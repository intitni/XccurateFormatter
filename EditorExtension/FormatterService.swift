import Foundation

let service = EditorExtensionService()

final class EditorExtensionService {
    lazy var connection: NSXPCConnection = {
        let connection = NSXPCConnection(
            machServiceName: Bundle(for: EditorExtensionService.self)
                .object(forInfoDictionaryKey: "XPC_SERVICE_BUNDLE_IDENTIFIER") as! String
        )
        connection.remoteObjectInterface =
            NSXPCInterface(with: EditorExtensionXPCServiceProtocol.self)
        connection.resume()
        return connection
    }()

    deinit {
        connection.invalidate()
    }

    func formatFile(
        content: String,
        uti: String,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) {
        let service = connection.remoteObjectProxyWithErrorHandler {
            completionHandler(.failure($0))
        } as! EditorExtensionXPCServiceProtocol
        service.formatEditingFile(content: content, uti: uti, withReply: { result, error in
            if let error = error {
                completionHandler(.failure(error))
            } else {
                completionHandler(.success(result ?? content))
            }
        })
    }
}
