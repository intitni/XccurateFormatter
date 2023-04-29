import Foundation

@objc(EditorExtensionXPCServiceProtocol) protocol EditorExtensionXPCServiceProtocol {
    func formatEditingFile(
        content: String,
        lines: [String],
        uti: String,
        withReply reply: @escaping (Data?, Error?) -> Void
    )
}
