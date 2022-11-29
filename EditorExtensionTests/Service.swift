import Foundation

struct Service {
    func format(content: String, uti: String, projectPath: String?) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let service = EditorExtensionXPCService()
            service.projectPathGetter = { projectPath }
            service.formatEditingFile(
                content: content,
                uti: uti
            ) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result ?? "")
            }
        }
    }
}
