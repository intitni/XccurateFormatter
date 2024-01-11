import CopilotForXcodeKit
import Foundation
import OSLog

struct FileState {
    var contentHashValue: Int = 0
    var isDirty: Bool = false
}

func log(message: String, type: OSLogType = .info) {
    os_log(
        "%{public}@",
        log: .init(subsystem: "com.intii.XccurateFormatter", category: "Auto Formatting"),
        type: type,
        message as CVarArg
    )
}

@main
class Extension: CopilotForXcodeExtension {
    var host: HostServer?
    var suggestionService: SuggestionServiceType? { nil }
    var chatService: ChatServiceType? { nil }
    var promptToCodeService: PromptToCodeServiceType? { nil }
    var sceneConfiguration: SceneConfiguration { .init() }

    required init() {}

    @MainActor
    var files: [URL: FileState] = [:]
    @MainActor
    var unhandledFileURLs: Set<URL> = []

    @MainActor
    func workspace(_ workspace: WorkspaceInfo, didUpdateDocumentAt fileURL: URL, content: String) {
        updateFile(at: fileURL, content: content)
    }

    func workspace(_ workspace: WorkspaceInfo, didSaveDocumentAt fileURL: URL) {
        Task { await formatFile(at: fileURL) }
    }

    @MainActor
    func workspace(_ workspace: WorkspaceInfo, didCloseDocumentAt fileURL: URL) {
        files[fileURL] = nil
    }
}

struct SceneConfiguration: CopilotForXcodeExtensionSceneConfiguration {
    typealias ChatPanelSceneGroup = Never
    typealias SuggestionPanelSceneGroup = Never
}

extension Extension {
    @MainActor
    func updateFile(at url: URL, content: String) {
        var state = files[url] ?? .init()
        state.isDirty = content.hashValue != state.contentHashValue
        state.contentHashValue = content.hashValue
        files[url] = state
    }

    @MainActor
    func formatFile(at url: URL) async {
        guard var state = files[url], state.isDirty else {
            unhandledFileURLs.remove(url)
            return
        }
        // Only trigger format if the file is active.
        guard let editor = try? await host?.getActiveEditor() else { return }
        guard editor.documentURL == url else {
            // when user switch to another editor, we should format the file when user switch back.
            unhandledFileURLs.insert(url)
            return
        }

        do {
            try await host?.triggerExtensionCommand(
                extensionName: "Xccurate Formatter",
                command: "Format File",
                activateXcode: false
            )
            unhandledFileURLs.remove(url)
            state.isDirty = false
            files[url] = state
        } catch {
            log(message: error.localizedDescription, type: .error)
        }
    }
}

