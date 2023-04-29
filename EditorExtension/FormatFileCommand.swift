import Foundation
import XcodeKit

class FormatFileCommand: NSObject, XCSourceEditorCommand {
    func perform(
        with invocation: XCSourceEditorCommandInvocation,
        completionHandler: @escaping (Error?) -> Void
    ) {
        let uti = invocation.buffer.contentUTI
        let content = invocation.buffer.completeBuffer
        let lines = invocation.buffer.lines
        do {
            let service = try getService()
            service.formatFile(
                content: content,
                lines: lines as! [String],
                uti: uti,
                completionHandler: {
                    switch $0 {
                    case let .failure(error):
                        completionHandler(error)
                    case let .success(diff):
                        let selectionsRangesToRestore = invocation.buffer.selections
                            .compactMap { $0 as? XCSourceTextRange }
                        guard let diff,
                              let nsmutableStringDiff = CollectionDifference<Any>(
                                  diff.map {
                                      switch $0 {
                                      case let .insert(offset, element, associatedWith):
                                          return .insert(
                                              offset: offset,
                                              element: NSMutableString(string: element),
                                              associatedWith: associatedWith
                                          )
                                      case let .remove(offset, element, associatedWith):
                                          return .remove(
                                              offset: offset,
                                              element: NSMutableString(string: element),
                                              associatedWith: associatedWith
                                          )
                                      }
                                  }
                              )
                        else {
                            completionHandler(nil)
                            return
                        }

                        invocation.buffer.lines.apply(nsmutableStringDiff)
                        completionHandler(nil)
                    }
                }
            )
        } catch {
            completionHandler(error)
        }
    }
}
