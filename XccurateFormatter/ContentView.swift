import SwiftUI

struct ContentView: View {
    @AppStorage(SettingsKey.defaultSwiftFormatExecutablePath, store: .shared)
    var defaultSwiftFormatExecutablePath: String = ""

    var body: some View {
        ScrollView {
            VStack {
                Link(destination: URL(string: "https://github.com/intitni/XccurateFormatter")!) {
                    Text("Go to GitHub for detailed instruction →")
                        .foregroundColor(Color(nsColor: .controlAccentColor))
                }
                SwiftFormatSetttings()
                AppleSwiftFormatSettings()
                ClangFormatSettings()
                PrettierSettings()
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 600)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
