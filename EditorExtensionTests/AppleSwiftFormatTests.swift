import XCTest

final class AppleSwiftFormatTests: XCTestCase {
    let suiteName = "XccurateFormatterAppleSwiftFormatTests"

    override func setUpWithError() throws {
        let userDefaults = UserDefaults(suiteName: suiteName)!
        Settings.storage = userDefaults
        userDefaults.set(
            TestConfig.appleSwiftFormatExecutablePath,
            forKey: SettingsKey.defaultAppleSwiftFormatExecutablePath
        )
    }

    override func tearDownWithError() throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    func testNoExecutablePathSet() async throws {
        Settings.storage.set("", forKey: SettingsKey.defaultAppleSwiftFormatExecutablePath)
        do {
            _ = try await TestService().format(
                content: """
                       var        name = "dog"
                """,
                uti: "public.swift-source",
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
                   var        name = "dog"
            """,
            uti: "public.swift-source",
            contentPath: nil
        )
        XCTAssertEqual(
            result,
            """
            var name = "dog"

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
            "version": 1,
            "indentation": {
                "spaces": 10
            },
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".swift-format").path,
            contents: config.data(using: .utf8)
        )
        let result = try await TestService().format(
            content: """
            struct Cat {
              var name = "Dog"
            }
            """,
            uti: "public.swift-source",
            contentPath: dirUrl.path
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

    func testFormatWithCustomExecutablePath() async throws {
        Settings.storage.set("", forKey: SettingsKey.defaultAppleSwiftFormatExecutablePath)
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
          "appleSwiftFormatExecutablePath": "\(TestConfig.appleSwiftFormatExecutablePath)"
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".xccurateformatter").path,
            contents: config.data(using: .utf8)
        )
        let result = try await TestService().format(
            content: """
                   var        name = "dog"
            """,
            uti: "public.swift-source",
            contentPath: dirUrl.path
        )
        XCTAssertEqual(
            result,
            """
            var name = "dog"

            """
        )
    }

    func testFormatPlayground() async throws {
        let result = try await TestService().format(
            content: """
                   var        name = "dog"
            """,
            uti: "com.apple.dt.playground",
            contentPath: "/contents.xcplayground"
        )
        XCTAssertEqual(
            result,
            """
            var name = "dog"

            """
        )
    }

    func testFormatPlaygroundPage() async throws {
        let result = try await TestService().format(
            content: """
                   var        name = "dog"
            """,
            uti: "com.apple.dt.playgroundpage",
            contentPath: "/contents.xcplaygroundpage"
        )
        XCTAssertEqual(
            result,
            """
            var name = "dog"

            """
        )
    }

    func testFormatSwiftPackage() async throws {
        let result = try await TestService().format(
            content: """
                   var        name = "dog"
            """,
            uti: "com.apple.dt.swiftpm-package-manifest",
            contentPath: "/contents.xcplaygroundpage"
        )
        XCTAssertEqual(
            result,
            """
            var name = "dog"

            """
        )
    }
}
