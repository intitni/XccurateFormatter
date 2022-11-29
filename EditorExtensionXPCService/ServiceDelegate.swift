import Foundation

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(
            with: EditorExtensionXPCServiceProtocol.self
        )

        let exportedObject = EditorExtensionXPCService()
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}
