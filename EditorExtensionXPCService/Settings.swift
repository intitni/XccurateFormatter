import Foundation

enum Settings {
    static var storage = UserDefaults.shared

    static var defaultSwiftFormatExecutablePath: String? {
        string(forKey: SettingsKey.defaultSwiftFormatExecutablePath, from: storage)
    }

    static var defaultAppleSwiftFormatExecutablePath: String? {
        string(forKey: SettingsKey.defaultAppleSwiftFormatExecutablePath, from: storage)
    }

    static var defaultClangFormatExecutablePath: String? {
        string(forKey: SettingsKey.defaultClangFormatExecutablePath, from: storage)
    }

    static var defaultClangFormatStyle: String? {
        string(forKey: SettingsKey.defaultClangFormatStyle, from: storage)
    }

    static var defaultPrettierExecutablePath: String? {
        string(forKey: SettingsKey.defaultPrettierExecutablePath, from: storage)
    }

    static var defaultNPXExecutablePath: String? {
        string(forKey: SettingsKey.defaultNPXExecutablePath, from: storage)
    }

    static var envPath: String {
        "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin/:/usr/bin:/bin:/usr/sbin:/sbin"
    }
}

private func string(forKey key: String, from userDefaults: UserDefaults) -> String? {
    guard let value = userDefaults.string(forKey: key)
    else { return nil }
    if value.isEmpty { return nil }
    return value
}

private func bool(forKey key: String, from userDefaults: UserDefaults) -> Bool {
    userDefaults.bool(forKey: key)
}
