import AppKit
import Foundation

let listener = NSXPCListener(
    machServiceName: Bundle.main.object(forInfoDictionaryKey: "BUNDLE_IDENTIFIER_BASE") as! String
        + ".EditorExtensionXPCService"
)
let delegate = ServiceDelegate()
listener.delegate = delegate
listener.resume()

Task {
    for await notification in NSWorkspace.shared.notificationCenter
        .notifications(named: NSWorkspace.didTerminateApplicationNotification)
    {
        guard let app = notification
            .userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            app.bundleIdentifier == "com.apple.dt.Xcode"
        else { continue }
        exit(0)
    }
}

RunLoop.main.run()
