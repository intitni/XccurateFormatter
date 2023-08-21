import SwiftUI

struct PrettierSettings: View {
    @AppStorage(SettingsKey.defaultPrettierExecutablePath, store: .shared)
    var defaultPrettierExecutablePath: String = ""
    @AppStorage(SettingsKey.defaultNPXExecutablePath, store: .shared)
    var defaultNPXExecutablePath: String = ""
    @AppStorage(SettingsKey.defaultPrettierArguments, store: .shared)
    var defaultPrettierArguments: String = ""

    var body: some View {
        Card(
            title: "Prettier",
            link: URL(string: "https://prettier.io/")!
        ) {
            Form {
                TextField(
                    "Prettier Executable Path",
                    text: $defaultPrettierExecutablePath,
                    prompt: Text("where Prettier is installed.")
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)

                TextField(
                    "Prettier Arguments",
                    text: $defaultPrettierArguments,
                    prompt: Text("arguments, e.g. --plugin=prettier-plugin-foo")
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)

                TextField(
                    "NPX Executable Path",
                    text: $defaultNPXExecutablePath,
                    prompt: Text("where NPX is installed.")
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)

                Text(
                    "Optional. Used when you set `usePrettierFromNodeModule` to `true` in `.xccurateformatter`."
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .font(.footnote)
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
            }
            VStack(alignment: .leading, spacing: 2) {
                Cheatsheet {
                    Text("install with npm: `npm install prettier --global`")
                }
                Cheatsheet {
                    Text("get executable path: `which prettier`")
                }
                Cheatsheet {
                    Text(
                        "support languages: `JavaScript, tsx, CSS, Less, SCSS, HTML, JSON, Markdown, YAML, XML, and others with plugins."
                    )
                }
            }
        }
    }
}

struct PrettierSettings_Previews: PreviewProvider {
    static var previews: some View {
        PrettierSettings()
    }
}

