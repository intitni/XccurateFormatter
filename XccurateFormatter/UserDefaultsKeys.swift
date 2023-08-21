import Foundation

public extension UserDefaults {
    static let shared = UserDefaults(suiteName: "5YKZ4Y3DAW.group.com.intii.XccurateFormatter")!
}

enum SettingsKey {
    static let defaultSwiftFormatExecutablePath = "defaultSwiftFormatExecutablePath"
    static let defaultAppleSwiftFormatExecutablePath = "defaultAppleSwiftFormatExecutablePath"
    static let defaultClangFormatExecutablePath = "defaultClangFormatExecutablePath"
    static let defaultClangFormatStyle = "defaultClangFormatStyle"
    static let defaultPrettierExecutablePath = "defaultPrettierExecutablePath"
    static let defaultPrettierArguments = "defaultPrettierArguments"
    static let defaultNPXExecutablePath = "defaultNPXExecutablePath"
}
