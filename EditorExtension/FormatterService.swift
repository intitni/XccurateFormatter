import Foundation
import os.log

private var shared = EditorExtensionService()

func getService() throws -> EditorExtensionService {
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        struct RunningInPreview: Error {}
        throw RunningInPreview()
    }
    if shared.isInvalidated {
        shared = EditorExtensionService()
    }
    return shared
}

final class EditorExtensionService {
    var isInvalidated = false

    lazy var connection: NSXPCConnection = {
        let connection = NSXPCConnection(
            machServiceName: Bundle(for: EditorExtensionService.self)
                .object(forInfoDictionaryKey: "XPC_SERVICE_BUNDLE_IDENTIFIER") as! String
        )
        connection.remoteObjectInterface =
            NSXPCInterface(with: EditorExtensionXPCServiceProtocol.self)
        connection.invalidationHandler = { [weak self] in
            os_log(.info, "XPCService Invalidated")
            self?.isInvalidated = true
        }
        connection.interruptionHandler = { [weak self] in
            os_log(.info, "XPCService interrupted")
        }
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
            if let error {
                completionHandler(.failure(error))
            } else {
                completionHandler(.success(result ?? content))
            }
        })
    }
}
