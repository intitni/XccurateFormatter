import SwiftUI

enum ClangStyles: String, CaseIterable {
    case llvm
    case google
    case chromium
    case mozilla
    case webkit
    case microsoft
}

struct ClangFormatSettings: View {
    @AppStorage(SettingsKey.defaultClangFormatExecutablePath, store: .shared)
    var defaultClangFormatExecutablePath: String = ""
    @AppStorage(SettingsKey.defaultClangFormatStyle, store: .shared)
    var defaultClangFormatStyle: String = ClangStyles.llvm.rawValue
    @State
    var style = UserDefaults.shared
        .string(forKey: SettingsKey.defaultClangFormatStyle) ?? ClangStyles.llvm.rawValue

    var body: some View {
        Card(
            title: "ClangFormat",
            link: URL(string: "https://clang.llvm.org/docs/ClangFormat.html")!
        ) {
            Form {
                TextField(
                    "Executable Path",
                    text: $defaultClangFormatExecutablePath,
                    prompt: Text("where ClangFormat is installed.")
                )
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)

                Picker("Style", selection: .init(get: {
                    style
                }, set: {
                    style = $0
                    defaultClangFormatStyle = $0
                })) {
                    ForEach(ClangStyles.allCases.map(\.rawValue), id: \.self) {
                        Text($0)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Cheatsheet {
                    Text("install with homebrew: `brew install clang-format`")
                }
                Cheatsheet {
                    Text("get executable path: `which clang-format`")
                }
                Cheatsheet {
                    Text(
                        "support languages: `C, C++, Objective-C, Objective-C++, Java, JSON, C#, ProtoBuffer`"
                    )
                }
            }
        }
    }
}

struct ClangFormatSettings_Previews: PreviewProvider {
    static var previews: some View {
        ClangFormatSettings()
    }
}
