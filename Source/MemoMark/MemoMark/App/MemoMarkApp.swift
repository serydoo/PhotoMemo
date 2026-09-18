import SwiftUI
#if os(macOS)
import AppKit
#endif

#if os(macOS)
@main
struct MemoMarkApp: App {

    @StateObject
    private var runtime =
        MemoMarkAppRuntime()

    @StateObject
    private var macConfigurationUndoCoordinator =
        MacConfigurationUndoCoordinator.shared

#if os(macOS)
    @NSApplicationDelegateAdaptor(
        MemoMarkAppDelegate.self
    )
    private var appDelegate
#endif

    init() {

#if os(macOS)
        NSApplication.shared.appearance =
        NSAppearance(
                named: .aqua
            )
#endif
    }

    var body: some Scene {

        WindowGroup {

            MemoMarkRootSceneView(
                runtime: runtime
            )
            .environmentObject(macConfigurationUndoCoordinator)
            .onAppear {
                appDelegate.install { urls in
                    runtime.handleExternalURLs(
                        urls,
                        source: .fileOpen
                    )
                }
            }
        }
        .commands {
            InspectorCommands()
            MacConfigurationUndoCommands()
        }
    }
}

private struct MacConfigurationUndoCommands: Commands {

    private let undoCoordinator = MacConfigurationUndoCoordinator.shared

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button("撤销") {
                _ = undoCoordinator.undo()
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!undoCoordinator.canUndo)

            Button("重做") {
                _ = undoCoordinator.redo()
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!undoCoordinator.canRedo)
        }
    }
}
#endif
