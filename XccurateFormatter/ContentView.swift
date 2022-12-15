import Foundation
import SwiftUI

struct ContentView: View {
    @AppStorage(SettingsKey.defaultSwiftFormatExecutablePath, store: .shared)
    var defaultSwiftFormatExecutablePath = ""
    @State var isDidSetupLaunchAgentAlertPresented = false
    @State var isDidRemoveLaunchAgentAlertPresented = false
    @State var isDidRestartLaunchAgentAlertPresented = false
    @State var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack {
                Link(destination: URL(string: "https://github.com/intitni/XccurateFormatter")!) {
                    Text("Go to GitHub for detailed instruction →")
                        .foregroundColor(Color(nsColor: .controlAccentColor))
                }
                HStack {
                    Button(action: {
                        do {
                            try LaunchAgentManager().setupLaunchAgent()
                            isDidSetupLaunchAgentAlertPresented = true
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }) {
                        Text("Setup Launch Agent for XPC Service")
                    }
                    .alert(isPresented: $isDidSetupLaunchAgentAlertPresented) {
                        .init(
                            title: Text("Finished Launch Agent Setup"),
                            message: Text(
                                "You may need to restart Xcode to make the extension work."
                            ),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    Button(action: {
                        do {
                            try LaunchAgentManager().removeLaunchAgent()
                            isDidRemoveLaunchAgentAlertPresented = true
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }) {
                        Text("Remove Launch Agent")
                    }
                    .alert(isPresented: $isDidRemoveLaunchAgentAlertPresented) {
                        .init(
                            title: Text("Launch Agent Removed"),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    
                    Button(action: {
                        LaunchAgentManager().restartLaunchAgent()
                        isDidRestartLaunchAgentAlertPresented = true
                    }) {
                        Text("Restart XPC Service")
                    }.alert(isPresented: $isDidRestartLaunchAgentAlertPresented) {
                        .init(
                            title: Text("Launch Agent Restarted"),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    EmptyView()
                        .alert(isPresented: .init(
                            get: { errorMessage != nil },
                            set: { yes in
                                if !yes { errorMessage = nil }
                            }
                        )) {
                            .init(
                                title: Text("Failed. Got to the GitHub page for Help"),
                                message: Text(errorMessage ?? "Unknown Error"),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                }
                SwiftFormatSetttings()
                AppleSwiftFormatSettings()
                ClangFormatSettings()
                PrettierSettings()
                
                Spacer()
            }
            .padding()
        }
        .overlay(alignment: .topLeading) {
            Text(
                Bundle.main
                    .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            )
            .foregroundColor(.white)
            .padding(.all, 4)
            .background(Color.black)
            .cornerRadius(4)
            .padding(4)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(height: 800)
    }
}
