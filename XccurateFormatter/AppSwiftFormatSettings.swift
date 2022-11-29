import SwiftUI

struct AppleSwiftFormatSettings: View {
    @AppStorage(SettingsKey.defaultAppleSwiftFormatExecutablePath, store: .shared)
    var defaultAppleSwiftFormatExecutablePath: String = ""

    var body: some View {
        Card(
            title: "swift-format",
            link: URL(string: "https://github.com/apple/swift-format")!
        ) {
            Form {
                TextField(
                    "Executable Path",
                    text: $defaultAppleSwiftFormatExecutablePath,
                    prompt: Text("where swift-format is installed.")
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Cheatsheet {
                    Text("build from source, check its GitHub page for manual")
                }
                Cheatsheet {
                    Text("get executable path: `/path/.build/release/swift-format`")
                }
                Cheatsheet {
                    Text("support languages: `Swift`")
                }
            }
        }
    }
}

struct AppleSwiftFormatSettings_Previews: PreviewProvider {
    static var previews: some View {
        AppleSwiftFormatSettings()
    }
}
