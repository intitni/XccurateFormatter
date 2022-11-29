import Foundation

enum ExtensionError: Swift.Error, LocalizedError {
    case noSupportedFormatterFound(uti: String)
    case other(String)

    var errorDescription: String? {
        switch self {
        case let .noSupportedFormatterFound(uti):
            return "No formatter found for file type \(uti)."
        case let .other(message):
            return message
        }
    }
}

class EditorExtensionXPCService: NSObject, EditorExtensionXPCServiceProtocol {
    var projectPathGetter: (() -> String?)?

    func formatEditingFile(
        content: String,
        uti: String,
        withReply reply: @escaping (String?, Error?) -> Void
    ) {
        do {
            let projectURL = try getXcodeEditingProjectURL()
            let formatters: [any Formatter] = [
                SwiftFormat(),
                AppleSwiftFormat(),
                ClangFormat(),
                Prettier(),
            ].filter {
                $0.supportedFileUTI.contains(uti)
            }
            if let projectURL {
                let (formatter, confURL, projectConfig) = guessFormatter(
                    forProjectAt: projectURL,
                    from: formatters
                )
                guard let formatter else {
                    throw ExtensionError.noSupportedFormatterFound(uti: uti)
                }
                let result = try format(
                    content: content,
                    uti: uti,
                    with: formatter,
                    confURL: confURL,
                    projectConfig: projectConfig,
                    in: projectURL
                )
                reply(result, nil)
            } else {
                guard let formatter = formatters.first(where: {
                    $0.hasValidExecutablePath(projectConfiguration: nil)
                }) else {
                    throw ExtensionError.noSupportedFormatterFound(uti: uti)
                }
                let result = try format(
                    content: content,
                    uti: uti,
                    with: formatter,
                    confURL: nil,
                    projectConfig: nil,
                    in: projectURL
                )
                reply(result, nil)
            }
        } catch {
            let nserror = NSError(domain: "com.intii.XccurateFormatter", code: -1, userInfo: [
                NSLocalizedDescriptionKey: error.localizedDescription,
            ])
            reply(nil, nserror)
        }
    }

    func getXcodeEditingProjectURL() throws -> URL? {
        if let projectPathGetter {
            return projectPathGetter().flatMap(URL.init(fileURLWithPath:))
        }

        let appleScript = """
        tell application "Xcode"
            return path of document of the first window
        end tell
        """

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", appleScript]
        let outpipe = Pipe()
        task.standardOutput = outpipe
        try task.run()
        task.waitUntilExit()
        if let data = try outpipe.fileHandleForReading.readToEnd(),
           let path = String(data: data, encoding: .utf8)
        {
            let trimmedNewLine = path.trimmingCharacters(in: .newlines)
            return URL(fileURLWithPath: trimmedNewLine)
        }
        return nil
    }

    func guessFormatter(
        forProjectAt projectURL: URL,
        from formatters: [any Formatter]
    ) -> (formatter: (any Formatter)?, confURL: URL?, projectConfig: ProjectConfig?) {
        var directoryURL = projectURL
        var formatter: (any Formatter)?
        var confURL: URL?
        var projectConfigURL: URL?

        while directoryURL.pathComponents.count > 1, confURL == nil, projectConfigURL == nil {
            defer { directoryURL.deleteLastPathComponent() }
            do {
                let contents = try FileManager.default
                    .contentsOfDirectory(atPath: directoryURL.path)
                for content in contents {
                    if confURL == nil {
                        for f in formatters {
                            let range = NSRange(content.startIndex..<content.endIndex, in: content)
                            let regex = f.configurationFileName
                            if regex.firstMatch(in: content, range: range) != nil {
                                formatter = f
                                if #available(macOS 13.0, *) {
                                    confURL = directoryURL.appending(component: content)
                                } else {
                                    confURL = directoryURL.appendingPathComponent(content)
                                }
                            }
                        }
                    }
                    if projectConfigURL == nil {
                        if content == ".xccurateformatter" {
                            if #available(macOS 13.0, *) {
                                projectConfigURL = directoryURL.appending(component: content)
                            } else {
                                projectConfigURL = directoryURL.appendingPathComponent(content)
                            }
                        }
                    }
                }
            } catch {
                continue
            }
        }

        let projectConfig = try? projectConfigURL.flatMap {
            let data = try Data(contentsOf: $0)
            return try JSONDecoder().decode(ProjectConfig.self, from: data)
        }

        if let formatter {
            return (formatter, confURL, projectConfig)
        }

        formatter = formatters.first {
            $0.hasValidExecutablePath(projectConfiguration: projectConfig)
        }
        return (formatter, confURL, projectConfig)
    }

    func format(
        content: String,
        uti: String,
        with formatter: any Formatter,
        confURL: URL?,
        projectConfig: ProjectConfig?,
        in projectURL: URL?
    ) throws -> String {
        let data = content.data(using: .utf8)
        let tempDirectory = projectURL ?? FileManager.default.temporaryDirectory
        let fileName = ".xccurate_formatter_\(UUID().uuidString).\(utiToExtensionName[uti] ?? "")"
        let fileURL: URL
        if #available(macOS 13.0, *) {
            fileURL = tempDirectory.appending(component: fileName)
        } else {
            fileURL = tempDirectory.appendingPathComponent(fileName)
        }
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        try formatter.format(
            file: fileURL,
            currentDirectoryURL: projectURL,
            confURL: confURL,
            projectConfig: projectConfig
        )
        return try String(contentsOf: fileURL)
    }
}
