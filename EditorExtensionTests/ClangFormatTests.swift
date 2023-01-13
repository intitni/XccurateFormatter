import XCTest

final class ClangFormatTests: XCTestCase {
    let suiteName = "XccurateFormatterClangFormatTests"

    override func setUpWithError() throws {
        let userDefaults = UserDefaults(suiteName: suiteName)!
        Settings.storage = userDefaults
        userDefaults.set(
            TestConfig.clangFormatExecutablePath,
            forKey: SettingsKey.defaultClangFormatExecutablePath
        )
        userDefaults.set(
            "LLVM",
            forKey: SettingsKey.defaultClangFormatStyle
        )
    }

    override func tearDownWithError() throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    func testNoLuanchPathSet() async throws {
        Settings.storage.set("", forKey: SettingsKey.defaultClangFormatExecutablePath)

        do {
            _ = try await TestService().format(
                content: """
                       int        number =     20;
                """,
                uti: "public.c-source",
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
            int main() {
                printf("Hello, World!");
                return 0;
            }
            """,
            uti: "public.c-source",
            contentPath: nil
        )
        XCTAssertEqual(
            result,
            """
            int main() {
              printf("Hello, World!");
              return 0;
            }
            """
        )
    }

    func testFormatWithCustomConfiguration_IgnoreCustomStyle() async throws {
        let f = FileManager.default
        let tempDir = f.temporaryDirectory
        let folderName = "xccurate_formatter_\(UUID().uuidString)"
        let dirUrl = tempDir.appending(component: folderName)
        try f.createDirectory(at: dirUrl, withIntermediateDirectories: false)
        defer {
            try? f.removeItem(at: dirUrl)
        }
        let config = """
        IndentWidth:    10
        """
        let xconfig = """
        {
            "clangFormatStyle": "LLVM"
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".clang-format").path,
            contents: config.data(using: .utf8)
        )
        f.createFile(
            atPath: dirUrl.appending(component: ".xccurateformatter").path,
            contents: xconfig.data(using: .utf8)
        )
        let result = try await TestService().format(
            content: """
            #include <stdio.h>
            int main() {
                printf("Hello, World!");
                return 0;
            }
            """,
            uti: "public.c-source",
            contentPath: dirUrl.path
        )
        XCTAssertEqual(
            result,
            """
            #include <stdio.h>
            int main() {
                      printf("Hello, World!");
                      return 0;
            }
            """
        )
    }

    func testFormatWithCustomExecutablePath() async throws {
        Settings.storage.set("", forKey: SettingsKey.defaultClangFormatExecutablePath)
        let f = FileManager.default
        let tempDir = f.temporaryDirectory
        let folderName = "xccurate_formatter_\(UUID().uuidString)"
        let dirUrl = tempDir.appending(component: folderName)
        try f.createDirectory(at: dirUrl, withIntermediateDirectories: false)
        defer {
            try? f.removeItem(at: dirUrl)
        }
        let xconfig = """
        {
            "clangFormatExecutablePath": "\(TestConfig.clangFormatExecutablePath)"
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".xccurateformatter").path,
            contents: xconfig.data(using: .utf8)
        )
        let result = try await TestService().format(
            content: """
            #include <stdio.h>
            int main() {
                printf("Hello, World!");
                return 0;
            }
            """,
            uti: "public.c-source",
            contentPath: dirUrl.path
        )
        XCTAssertEqual(
            result,
            """
            #include <stdio.h>
            int main() {
              printf("Hello, World!");
              return 0;
            }
            """
        )
    }

    func testFormatWithCustomStyle() async throws {
        let f = FileManager.default
        let tempDir = f.temporaryDirectory
        let folderName = "xccurate_formatter_\(UUID().uuidString)"
        let dirUrl = tempDir.appending(component: folderName)
        try f.createDirectory(at: dirUrl, withIntermediateDirectories: false)
        defer {
            try? f.removeItem(at: dirUrl)
        }
        // WebKit coding style uses 4 spaces indentation!
        // And the curly braces style that looks weird to me!
        let xconfig = """
        {
            "clangFormatStyle": "Webkit"
        }
        """
        f.createFile(
            atPath: dirUrl.appending(component: ".xccurateformatter").path,
            contents: xconfig.data(using: .utf8)
        )
        let result = try await TestService().format(
            content: """
            #include <stdio.h>
            int main() {
                printf("Hello, World!");
                return 0;
            }
            """,
            uti: "public.c-source",
            contentPath: dirUrl.path
        )
        XCTAssertEqual(
            result,
            """
            #include <stdio.h>
            int main()
            {
                printf("Hello, World!");
                return 0;
            }
            """
        )
    }
}
