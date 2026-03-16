import AppKit
import SwiftUI

@MainActor
final class WindowRouter {
    private let appState: AppState
    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var refreshMetrics: (@MainActor () -> Void)?

    init(appState: AppState) {
        self.appState = appState
    }

    func showSettings(refreshMetrics: @escaping @MainActor () -> Void) {
        self.refreshMetrics = refreshMetrics
        let window = settingsWindow ?? makeSettingsWindow()

        settingsWindow = window
        refreshLocalizedChrome()
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func showHistory() {
        let window = historyWindow ?? makeHistoryWindow()

        historyWindow = window
        refreshLocalizedChrome()
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func refreshLocalizedChrome() {
        settingsWindow?.title = appState.text(.settings)
        historyWindow?.title = appState.text(.history)
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
        window.title = appState.text(.settings)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 520, height: 560))

        return window
    }

    private func makeHistoryWindow() -> NSWindow {
        let hostingController = NSHostingController(
            rootView: HistoryView(appState: appState)
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = appState.text(.history)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 760, height: 820))
        window.minSize = NSSize(width: 680, height: 720)

        return window
    }
}
