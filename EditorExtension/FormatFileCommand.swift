import Foundation
import XcodeKit

class FormatFileCommand: NSObject, XCSourceEditorCommand {
    func perform(
        with invocation: XCSourceEditorCommandInvocation,
        completionHandler: @escaping (Error?) -> Void
    ) {
        let uti = invocation.buffer.contentUTI
        let content = invocation.buffer.completeBuffer
        service.formatFile(content: content, uti: uti, completionHandler: {
            switch $0 {
            case let .failure(error):
                completionHandler(error)
            case let .success(content):
                let selectionsRangesToRestore = invocation.buffer.selections
                    .compactMap { $0 as? XCSourceTextRange }
                invocation.buffer.selections.removeAllObjects()
                invocation.buffer.completeBuffer = content
                for range in selectionsRangesToRestore {
                    invocation.buffer.selections.add(range)
                }
                completionHandler(nil)
            }
        })
    }
}
