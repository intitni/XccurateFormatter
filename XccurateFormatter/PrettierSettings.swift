import SwiftUI

struct PrettierSettings: View {
    @AppStorage(SettingsKey.defaultPrettierExecutablePath, store: .shared)
    var defaultPrettierExecutablePath: String = ""
    @AppStorage(SettingsKey.defaultNPXExecutablePath, store: .shared)
    var defaultNPXExecutablePath: String = ""

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
                    "NPX Executable Path",
                    text: $defaultNPXExecutablePath,
                    prompt: Text("where NPX is installed.")
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)

                Text(
                    "Optional. Used we you set `usePrettierFromNodeModule` to `true` in `.xccurateformatter`."
                )
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
                        "support languages: `JavaScript, tsx, CSS, Less, SCSS, HTML, JSON, Markdown, YAML, XML`"
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
