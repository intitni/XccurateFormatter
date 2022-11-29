import Foundation

enum TestConfig {
    class LookForBundle {}
    static var swiftFormatExecutablePath: String { value(for: "SWIFT_FORMAT_EXECUTABLEPATH") }
    static var appleSwiftFormatExecutablePath: String {
        value(for: "APPLE_SWIFT_FORMAT_EXECUTABLEPATH")
    }

    static var clangFormatExecutablePath: String { value(for: "CLANG_FORMAT_EXECUTABLEPATH") }
    static var npxExecutablePath: String { value(for: "NPX_EXECUTABLEPATH") }
    static var prettierExecutablePath: String { value(for: "PRETTIER_EXECUTABLEPATH") }

    private static func value<T>(for key: String) -> T where T: LosslessStringConvertible {
        Bundle(for: LookForBundle.self).object(forInfoDictionaryKey: key) as! T
    }
}
