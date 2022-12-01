import XCTest

@testable import EditorExtensionXPCService

final class SwiftFormatTests: XCTestCase {
    let suiteName = "XccurateFormatterSwiftFormatTests"

    override func setUpWithError() throws {
        let userDefaults = UserDefaults(suiteName: suiteName)!
        Settings.storage = userDefaults
        userDefaults.set(
            TestConfig.swiftFormatExecutablePath,
            forKey: SettingsKey.defaultSwiftFormatExecutablePath
        )
    }

    override func tearDownWithError() throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    func testNoExecutablePathSet() throws {
        Settings.storage.set("", forKey: SettingsKey.defaultSwiftFormatExecutablePath)
        do {
            _ = try TestService().format(
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

    func testFormatWithDefaultExecutablePath() throws {
        let result = try TestService().format(
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

    func testFormatWithCustomConfiguration() throws {
        let f = FileManager.default
        let tempDir = f.temporaryDirectory
        let folderName = "xccurate_formatter_\(UUID().uuidString)"
        let dirUrl = tempDir.appending(component: folderName)
        try f.createDirectory(at: dirUrl, withIntermediateDirectories: false)
        defer {
            try? f.removeItem(at: dirUrl)
        }
        let config = """
        --indent 10
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".swiftformat").path,
            contents: config.data(using: .utf8)
        )
        let result = try TestService().format(
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

    func testFormatWithCustomExecutablePath() throws {
        Settings.storage.set("", forKey: SettingsKey.defaultSwiftFormatExecutablePath)
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
          "swiftFormatExecutablePath": "\(TestConfig.swiftFormatExecutablePath)"
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".xccurateformatter").path,
            contents: config.data(using: .utf8)
        )
        let result = try TestService().format(
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
    
    func testFormatPlayground() throws {
        let result = try TestService().format(
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
    
    func testFormatPlaygroundPage() throws {
        let result = try TestService().format(
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
    
    func testFormatSwiftPackage() throws {
        let result = try TestService().format(
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
