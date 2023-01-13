import AppKit
import Foundation

class EditorExtensionXPCService: NSObject, EditorExtensionXPCServiceProtocol {
    func formatEditingFile(
        content: String,
        uti: String,
        withReply reply: @escaping (String?, Error?) -> Void
    ) {
        Task {
            do {
                let contentURL = try await getXcodeEditingContentURL()
                let result = try await Service().formatEditingFile(
                    content: content,
                    uti: uti,
                    contentURL: contentURL
                )
                reply(result, nil)
            } catch {
                let nserror = NSError(domain: "com.intii.XccurateFormatter", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: error.localizedDescription,
                ])
                reply(nil, nserror)
#if DEBUG
                print(error)
                Thread.callStackSymbols.forEach { print($0) }
#endif
            }
        }
    }

    func getXcodeEditingContentURL() async throws -> URL? {
        var activeXcodes = [NSRunningApplication]()
        var retryCount = 0
        // Sometimes runningApplications returns 0 items.
        while activeXcodes.isEmpty, retryCount < 5 {
            activeXcodes = NSRunningApplication
                .runningApplications(withBundleIdentifier: "com.apple.dt.Xcode")
                .sorted { lhs, _ in
                    if lhs.isActive { return true }
                    return false
                }
            if retryCount > 0 { try await Task.sleep(nanoseconds: 10_000_000) }
            retryCount += 1
        }

        // fetch file path of the frontmost window of Xcode through Accessability API.
        for xcode in activeXcodes {
            let application = AXUIElementCreateApplication(xcode.processIdentifier)
            do {
                let frontmostWindow = try application.copyValue(
                    key: kAXFocusedWindowAttribute,
                    ofType: AXUIElement.self
                )
                var path = try frontmostWindow.copyValue(
                    key: kAXDocumentAttribute,
                    ofType: String?.self
                )
                if path == nil {
                    if let firstWindow = try application.copyValue(
                        key: kAXWindowsAttribute,
                        ofType: [AXUIElement].self
                    ).first {
                        path = try firstWindow.copyValue(
                            key: kAXDocumentAttribute,
                            ofType: String.self
                        )
                    }
                }
                if let path = path?.removingPercentEncoding {
                    let url = URL(
                        fileURLWithPath: path
                            .replacingOccurrences(of: "file://", with: "")
                    )
                    return url
                }
            } catch {
                if let axError = error as? AXError, axError == .apiDisabled {
                    throw ExtensionError.noAccessToAccessibilityAPI
                }
            }
        }

        return nil
    }
}

extension AXError: Error {}

extension AXUIElement {
    func copyValue<T>(key: String, ofType _: T.Type = T.self) throws -> T {
        var value: AnyObject?
        let error = AXUIElementCopyAttributeValue(self, key as CFString, &value)
        if error == .success, let value = value as? T {
            return value
        }
        throw error
    }
}
