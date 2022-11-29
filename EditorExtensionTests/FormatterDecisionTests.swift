import XCTest

final class FormatterDecisionTests: XCTestCase {
    let suiteName = "XccurateFormatterFormatterDecisionTests"

    override func setUpWithError() throws {
        let userDefaults = UserDefaults(suiteName: suiteName)!
        Settings.storage = userDefaults
    }

    override func tearDownWithError() throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    func testIf2FormattersSupportTheSameLanguagePickTheOneThatHasAConfigurationFileCloserToTheProjectDirectory(
    ) async throws {
        Settings.storage.set(
            TestConfig.swiftFormatExecutablePath,
            forKey: SettingsKey.defaultSwiftFormatExecutablePath
        )
        Settings.storage.set(
            TestConfig.appleSwiftFormatExecutablePath,
            forKey: SettingsKey.defaultAppleSwiftFormatExecutablePath
        )

        let f = FileManager.default
        let tempDir = f.temporaryDirectory
        let folderName = "xccurate_formatter_\(UUID().uuidString)"
        let dirUrl = tempDir.appending(component: folderName)
        let secondaryDirURL = dirUrl.appending(component: "folder")
        try f.createDirectory(at: secondaryDirURL, withIntermediateDirectories: true)
        defer {
            try? f.removeItem(at: dirUrl)
        }
        let configSwiftFormat = """
        --indent 10
        """
        let configAppleSwiftFormat = """
        {
            "version": 1,
            "indentation": {
                "spaces": 5
            },
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".swiftformat").path,
            contents: configSwiftFormat.data(using: .utf8)
        )
        f.createFile(
            atPath: secondaryDirURL.appending(component: ".swift-format").path,
            contents: configAppleSwiftFormat.data(using: .utf8)
        )
        let result = try await Service().format(
            content: """
            struct Cat {
              var name = "Dog"
            }
            """,
            uti: "public.swift-source",
            projectPath: secondaryDirURL.path
        )
        XCTAssertEqual(
            result,
            """
            struct Cat {
                 var name = "Dog"
            }

            """
        )
    }
}
