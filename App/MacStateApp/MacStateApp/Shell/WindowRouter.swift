import AppKit
import SwiftUI

@MainActor
final class WindowRouter {
    private let appState: AppState
    private var settingsWindow: NSWindow?

    init(appState: AppState) {
        self.appState = appState
    }

    func showSettings() {
        let window = settingsWindow ?? makeSettingsWindow()

        settingsWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeSettingsWindow() -> NSWindow {
        let hostingController = NSHostingController(
            rootView: SettingsView(appState: appState)
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 420, height: 280))

        return window
    }
}
