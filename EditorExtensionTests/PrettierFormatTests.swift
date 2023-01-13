import XCTest

final class PrettierTests: XCTestCase {
    let suiteName = "XccurateFormatterPrettierTests"

    override func setUpWithError() throws {
        let userDefaults = UserDefaults(suiteName: suiteName)!
        Settings.storage = userDefaults
        userDefaults.set(
            TestConfig.prettierExecutablePath,
            forKey: SettingsKey.defaultPrettierExecutablePath
        )
        userDefaults.set(
            TestConfig.npxExecutablePath,
            forKey: SettingsKey.defaultNPXExecutablePath
        )
    }

    override func tearDownWithError() throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    func testNoExecutablePathSet() async throws {
        Settings.storage.set("", forKey: SettingsKey.defaultPrettierExecutablePath)
        do {
            _ = try await TestService().format(
                content: """
                             const        name       = "dog"
                """,
                uti: "com.netscape.javascript-source",
                contentPath: nil
            )
            XCTFail("Error expected")
        } catch {
            XCTAssertTrue(error.localizedDescription.hasPrefix("No formatter found"))
        }
    }

    func testFormatWithDefaultExecutablePath() async throws {
        let result = try await TestService().format(
            content: """
                         const        name       = "dog"
            """,
            uti: "com.netscape.javascript-source",
            contentPath: nil
        )
        XCTAssertEqual(
            result,
            """
            const name = "dog";

            """
        )
    }

    func testFormatWithCustomConfiguration() async throws {
        let f = FileManager.default
        let tempDir = f.temporaryDirectory
        let folderName = "xccurate_formatter_\(UUID().uuidString)"
        let dirUrl = tempDir.appending(component: folderName)
        try f.createDirectory(at: dirUrl, withIntermediateDirectories: false)
        defer {
            try? f.removeItem(at: dirUrl)
        }
        let config = """
        {
          "tabWidth": 10
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".prettierrc.json").path,
            contents: config.data(using: .utf8)
        )
        let result = try await TestService().format(
            content: """
            class Cat {
              name = "Dog";
            }
            """,
            uti: "com.netscape.javascript-source",
            contentPath: dirUrl.path
        )
        XCTAssertEqual(
            result,
            """
            class Cat {
                      name = "Dog";
            }

            """
        )
    }

    func testFormatWithCustomExecutablePath() async throws {
        Settings.storage.set("", forKey: SettingsKey.defaultPrettierExecutablePath)
        let f = FileManager.default
        let tempDir = f.temporaryDirectory
        let folderName = "xccurate_formatter_\(UUID().uuidString)"
        let dirUrl = tempDir.appending(component: folderName)
        try f.createDirectory(at: dirUrl, withIntermediateDirectories: false)
        defer {
            try? f.removeItem(at: dirUrl)
        }
        let config = """
        {
          "prettierExecutablePath": "\(TestConfig.prettierExecutablePath)"
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".xccurateformatter").path,
            contents: config.data(using: .utf8)
        )
        let result = try await TestService().format(
            content: """
                         const        name       = "dog"
            """,
            uti: "com.netscape.javascript-source",
            contentPath: dirUrl.path
        )
        XCTAssertEqual(
            result,
            """
            const name = "dog";

            """
        )
    }

    /// Will fire up npm init and npm install to install Prettier locally.
    func testFormatWithLocallyInstalledPrettier() async throws {
        Settings.storage.set("", forKey: SettingsKey.defaultPrettierExecutablePath)
        let f = FileManager.default
        let tempDir = f.temporaryDirectory
        let folderName = "xccurate_formatter_\(UUID().uuidString)"
        let dirUrl = tempDir.appending(component: folderName)
        try f.createDirectory(at: dirUrl, withIntermediateDirectories: false)
        defer {
            try? f.removeItem(at: dirUrl)
        }
        let config = """
        {
          "usePrettierFromNodeModules": true
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".xccurateformatter").path,
            contents: config.data(using: .utf8)
        )
        let npm = TestConfig.npxExecutablePath.replacing("npx", with: "npm")
        try runCommand(currentDirectoryURL: dirUrl, args: npm, "init", "--yes")
        try runCommand(currentDirectoryURL: dirUrl, args: npm, "install", "prettier")
        let result = try await TestService().format(
            content: """
                         const        name       = "dog"
            """,
            uti: "com.netscape.javascript-source",
            contentPath: dirUrl.path
        )
        XCTAssertEqual(
            result,
            """
            const name = "dog";

            """
        )
    }
}

@discardableResult
private func runCommand(currentDirectoryURL: URL?, args: String...) throws -> String {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.currentDirectoryURL = currentDirectoryURL
    task.environment = [
        "PATH": Settings.envPath,
    ]
    let outpipe = Pipe()
    task.standardOutput = outpipe
    try task.run()
    task.waitUntilExit()
    if let data = try outpipe.fileHandleForReading.readToEnd(),
       let text = String(data: data, encoding: .utf8)
    {
        if task.terminationStatus == 0 {
            return text
        } else {
            throw ExtensionError.other(text)
        }
    }

    return ""
}
