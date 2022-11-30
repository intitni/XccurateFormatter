import Foundation

struct TestService {
    func format(content: String, uti: String, projectPath: String?) throws -> String {
        let service = Service()
        return try service.formatEditingFile(
            content: content,
            uti: uti,
            contentURL: projectPath.flatMap {
                URL(filePath: $0)
            }
        )
    }
}
