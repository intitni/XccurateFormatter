import AppKit
import Foundation

enum ExtensionError: Swift.Error, LocalizedError {
    case noSupportedFormatterFound(uti: String)
    case noAccessToAccessibilityAPI
    case other(String)

    var errorDescription: String? {
        switch self {
        case let .noSupportedFormatterFound(uti):
            return "No formatter found for file type \(uti)."
        case .noAccessToAccessibilityAPI:
            return "Permission not granted to use Accessibility API. Please turn in on in Settings.app."
        case let .other(message):
            return message
        }
    }
}

final class Service {
    func formatEditingFile(content: String, uti: String, contentURL: URL?) async throws -> String {
        let fileExtension = contentURL?.pathExtension
        let utiExtension = utiToExtensionName[uti]
        let tempFileExtension: (any Formatter) -> String? = { formatter in
            if let fileExtension,
               !fileExtension.isEmpty,
               formatter.supportedFileExtensions.contains(fileExtension) { return fileExtension }
            return utiExtension
        }
        let formatters = [
            SwiftFormat(),
            AppleSwiftFormat(),
            ClangFormat(),
            Prettier(),
        ].filter { (formatter: any Formatter) in
            if let fileExtension {
                if formatter.supportedFileExtensions.contains(fileExtension) {
                    return true
                }
            }
            if let utiExtension {
                return formatter.supportedFileExtensions.contains(utiExtension)
            }
            return false
        }
        if let contentURL {
            let (formatter, confURL, projectConfig, fileDirectory) = guessFormatter(
                forContentAt: contentURL,
                from: formatters
            )
            guard let formatter else {
                throw ExtensionError.noSupportedFormatterFound(uti: uti)
            }
            let result = try await format(
                content: content,
                fileExtension: tempFileExtension(formatter),
                with: formatter,
                confURL: confURL,
                projectConfig: projectConfig,
                in: fileDirectory
            )
            return result
        } else {
            guard let formatter = formatters.first(where: {
                $0.hasValidExecutablePath(projectConfiguration: nil)
            }) else {
                throw ExtensionError.noSupportedFormatterFound(uti: uti)
            }
            let result = try await format(
                content: content,
                fileExtension: tempFileExtension(formatter),
                with: formatter,
                confURL: nil,
                projectConfig: nil,
                in: nil
            )
            return result
        }
    }

    func guessFormatter(
        forContentAt contentURL: URL,
        from formatters: [any Formatter]
    )
        -> (
            formatter: (any Formatter)?,
            confURL: URL?,
            projectConfig: ProjectConfig?,
            fileDirectory: URL?
        )
    {
        var directoryURL = contentURL
        var fileDirectory: URL?
        var formatter: (any Formatter)?
        var confURL: URL?
        var projectConfigURL: URL?

        while directoryURL.pathComponents.count > 1, confURL == nil, projectConfigURL == nil {
            defer { directoryURL.deleteLastPathComponent() }
            do {
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDir)
                guard isDir.boolValue else { continue }
                if fileDirectory == nil {
                    fileDirectory = directoryURL
                }
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
            return (formatter, confURL, projectConfig, fileDirectory)
        }

        formatter = formatters.first {
            $0.hasValidExecutablePath(projectConfiguration: projectConfig)
        }
        return (formatter, confURL, projectConfig, fileDirectory)
    }

    func format(
        content: String,
        fileExtension: String?,
        with formatter: any Formatter,
        confURL: URL?,
        projectConfig: ProjectConfig?,
        in projectURL: URL?
    ) async throws -> String {
        let data = content.data(using: .utf8)
        let tempDirectory = projectURL ?? FileManager.default.temporaryDirectory
        let fileName = ".xccurate_formatter_\(UUID().uuidString).\(fileExtension ?? "")"
        let fileURL: URL
        if #available(macOS 13.0, *) {
            fileURL = tempDirectory.appending(component: fileName)
        } else {
            fileURL = tempDirectory.appendingPathComponent(fileName)
        }
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        try await formatter.format(
            file: fileURL,
            currentDirectoryURL: projectURL,
            confURL: confURL,
            projectConfig: projectConfig
        )
        return try String(contentsOf: fileURL)
    }
}
