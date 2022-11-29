import Foundation

@objc(EditorExtensionXPCServiceProtocol) protocol EditorExtensionXPCServiceProtocol {
    func formatEditingFile(
        content: String,
        uti: String,
        withReply reply: @escaping (String?, Error?) -> Void
    )
}
