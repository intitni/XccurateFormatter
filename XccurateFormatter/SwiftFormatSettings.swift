import SwiftUI

struct SwiftFormatSetttings: View {
    @AppStorage(SettingsKey.defaultSwiftFormatExecutablePath, store: .shared)
    var defaultSwiftFormatExecutablePath: String = ""

    var body: some View {
        Card(
            title: "Swift Format",
            link: URL(string: "https://github.com/nicklockwood/SwiftFormat")!
        ) {
            Form {
                TextField(
                    "Executable Path",
                    text: $defaultSwiftFormatExecutablePath,
                    prompt: Text("where Swift Format is installed.")
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Cheatsheet {
                    Text("install with homebrew: `brew install swiftformat`")
                }
                Cheatsheet {
                    Text("get executable path: `which swiftformat`")
                }
                Cheatsheet {
                    Text("support languages: `Swift`")
                }
            }
        }
    }
}

struct SwiftFormatSetttings_Previews: PreviewProvider {
    static var previews: some View {
        SwiftFormatSetttings()
    }
}
