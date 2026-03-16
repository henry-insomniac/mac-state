import AppKit
import SwiftUI

@MainActor
final class WindowRouter {
    private let appState: AppState
    private var settingsWindow: NSWindow?
    private var refreshMetrics: (@MainActor () -> Void)?

    init(appState: AppState) {
        self.appState = appState
    }

    func showSettings(refreshMetrics: @escaping @MainActor () -> Void) {
        self.refreshMetrics = refreshMetrics
        let window = settingsWindow ?? makeSettingsWindow()

        settingsWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeSettingsWindow() -> NSWindow {
        let hostingController = NSHostingController(
            rootView: SettingsView(
                appState: appState,
                refreshMetrics: { [weak self] in
                    self?.refreshMetrics?()
                }
            )
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 440, height: 320))

        return window
    }
}
