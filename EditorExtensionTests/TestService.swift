import Foundation

struct TestService {
    func format(content: String, uti: String, contentPath: String?) async throws -> String {
        let service = Service()
        return try await service.formatEditingFile(
            content: content,
            uti: uti,
            contentURL: contentPath.flatMap {
                URL(filePath: $0)
            }
        )
    }
}
