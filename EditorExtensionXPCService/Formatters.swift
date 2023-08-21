import Foundation

struct ProjectConfig: Codable {
    var swiftFormatExecutablePath: String?
    var appleSwiftFormatExecutablePath: String?
    var clangFormatExecutablePath: String?
    var clangFormatStyle: String?
    var usePrettierFromNodeModules: Bool?
    var prettierExecutablePath: String?
    var prettierArguments: String?
}

protocol Formatter {
    var executablePath: String? { get }
    var configurationFileName: NSRegularExpression { get }
    var supportedFileExtensions: [String] { get }
    func format(
        file: URL,
        currentDirectoryURL: URL?,
        confURL: URL?,
        projectConfig: ProjectConfig?
    ) async throws
    func hasValidExecutablePath(projectConfiguration: ProjectConfig?) -> Bool
}

struct SwiftFormat: Formatter {
    var executablePath: String? { Settings.defaultSwiftFormatExecutablePath }
    var configurationFileName: NSRegularExpression {
        try! .init(pattern: #"^\.swiftformat$"#, options: [.caseInsensitive])
    }

    var supportedFileExtensions: [String] { ["swift"] }

    func format(
        file: URL,
        currentDirectoryURL: URL?,
        confURL _: URL?,
        projectConfig: ProjectConfig?
    ) async throws {
        guard let executablePath = projectConfig?.swiftFormatExecutablePath ?? executablePath
        else { throw ExtensionError.other("SwiftFormat executable path not set.") }
        try await runCommand(
            from: executablePath,
            currentDirectoryURL: currentDirectoryURL,
            args: file.path
        )
    }

    func hasValidExecutablePath(projectConfiguration: ProjectConfig?) -> Bool {
        (projectConfiguration?.swiftFormatExecutablePath ?? executablePath) != nil
    }
}

struct AppleSwiftFormat: Formatter {
    var executablePath: String? { Settings.defaultAppleSwiftFormatExecutablePath }
    var configurationFileName: NSRegularExpression {
        try! .init(pattern: #"^\.swift-format$"#, options: [.caseInsensitive])
    }

    var supportedFileExtensions: [String] { ["swift"] }

    func format(
        file: URL,
        currentDirectoryURL: URL?,
        confURL _: URL?,
        projectConfig: ProjectConfig?
    ) async throws {
        guard let executablePath = projectConfig?.appleSwiftFormatExecutablePath ?? executablePath
        else { throw ExtensionError.other("swift-format executable path not set.") }
        try await runCommand(
            from: executablePath,
            currentDirectoryURL: currentDirectoryURL,
            args: "-i",
            file.path
        )
    }

    func hasValidExecutablePath(projectConfiguration: ProjectConfig?) -> Bool {
        (projectConfiguration?.appleSwiftFormatExecutablePath ?? executablePath) != nil
    }
}

struct ClangFormat: Formatter {
    var executablePath: String? { Settings.defaultClangFormatExecutablePath }
    var configurationFileName: NSRegularExpression {
        try! .init(pattern: #"^\.clang-format$"#, options: [.caseInsensitive])
    }

    var supportedFileExtensions: [String] {
        [
            "c",
            "cpp", "cc", "cp", "c++", "cxx",
            "m",
            "mm",
            "java", "jav",
            "h", "pch", "pch++",
            "hh", "hpp", "h++", "hxx", "hp",
            "json",
            "cs",
            "proto",
        ]
    }

    func format(
        file: URL,
        currentDirectoryURL: URL?,
        confURL: URL?,
        projectConfig: ProjectConfig?
    ) async throws {
        guard let executablePath = projectConfig?.clangFormatExecutablePath ?? executablePath
        else { throw ExtensionError.other("ClangFormat executable path not set.") }
        var style = projectConfig?.clangFormatStyle ?? Settings.defaultClangFormatStyle ?? "LLVM"
        if confURL != nil {
            style = "file"
        }
        try await runCommand(
            from: executablePath, currentDirectoryURL: currentDirectoryURL,
            args: "-style=\(style)", "-i", file.path
        )
    }

    func hasValidExecutablePath(projectConfiguration: ProjectConfig?) -> Bool {
        (projectConfiguration?.clangFormatExecutablePath ?? executablePath) != nil
    }
}

struct Prettier: Formatter {
    var executablePath: String? { Settings.defaultPrettierExecutablePath }

    var arguments: String? { Settings.defaultPrettierArguments }

    var configurationFileName: NSRegularExpression {
        try! .init(pattern: #"^\.prettierrc(\..*)?$"#, options: [.caseInsensitive])
    }

    var supportedFileExtensions: [String] {
        [
            "js",
            "jsx",
            "ts",
            "tsx",
            "css",
            "less",
            "scss",
            "html", "htm",
            "json",
            "md",
            "graphql", "gql",
            "yaml", "yml",
            "xml",
        ]
    }

    func format(
        file: URL,
        currentDirectoryURL: URL?,
        confURL _: URL?,
        projectConfig: ProjectConfig?
    ) async throws {
        let arguments = projectConfig?.prettierArguments ?? arguments ?? ""
        if let usePrettierFromNodeModules = projectConfig?.usePrettierFromNodeModules,
           usePrettierFromNodeModules
        {
            guard let executablePath = Settings.defaultNPXExecutablePath
            else { throw ExtensionError.other("NPX executable path not set.") }
            try await runCommand(
                from: "/usr/bin/env",
                currentDirectoryURL: currentDirectoryURL,
                args: executablePath, "prettier", file.path, "--write", arguments
            )
        } else {
            guard let executablePath = projectConfig?.prettierExecutablePath ?? executablePath
            else { throw ExtensionError.other("Prettier executable path not set.") }
            if arguments.isEmpty {
                try await runCommand(
                    from: "/usr/bin/env",
                    currentDirectoryURL: currentDirectoryURL,
                    args: executablePath, "--write", file.path
                )
            } else {
                try await runCommand(
                    from: ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/bash",
                    currentDirectoryURL: currentDirectoryURL,
                    args: "-ilc", "\(executablePath) \(file.path) --write \(arguments)"
                )
            }
        }
    }

    func hasValidExecutablePath(projectConfiguration: ProjectConfig?) -> Bool {
        if let projectConfiguration {
            if projectConfiguration.usePrettierFromNodeModules ?? false {
                return Settings.defaultNPXExecutablePath != nil
            }
            return projectConfiguration.prettierExecutablePath != nil || executablePath != nil
        }
        return executablePath != nil
    }
}

@discardableResult
private func runCommand(
    from executablePath: String,
    currentDirectoryURL: URL?,
    args: String...
) async throws -> String {
    try await withUnsafeThrowingContinuation { continuation in
        do {
            let task = Process()
            task.launchPath = executablePath
            task.arguments = args
            task.currentDirectoryURL = currentDirectoryURL
            task.environment = [
                "PATH": Settings.envPath,
            ]
            let outpipe = Pipe()
            task.standardOutput = outpipe
            task.standardError = outpipe
            task.terminationHandler = { task in
                if let data = try? outpipe.fileHandleForReading.readToEnd(),
                   let text = String(data: data, encoding: .utf8)
                {
                    if task.terminationStatus == 0 {
                        continuation.resume(returning: text)
                    } else {
                        continuation.resume(
                            throwing: ExtensionError
                                .other(text.trimmingCharacters(in: .whitespacesAndNewlines))
                        )
                    }
                } else {
                    continuation.resume(throwing: ExtensionError.other("Unknown error"))
                }
            }
            try task.run()
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

