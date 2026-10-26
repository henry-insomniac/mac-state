import AppKit
import SwiftUI

@MainActor
final class WindowRouter {
    private let appState: AppState
    private var dashboardWindow: NSWindow?
    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var refreshMetrics: (@MainActor () -> Void)?

    init(appState: AppState) {
        self.appState = appState
    }

    func showDashboard(refreshMetrics: @escaping @MainActor () -> Void,
                       openHistory: @escaping @MainActor () -> Void,
                       openSettings: @escaping @MainActor () -> Void) {
        if dashboardWindow == nil {
            let controller = NSHostingController(rootView: DashboardView(
                appState: appState, refreshMetrics: refreshMetrics,
                openHistory: openHistory, openSettings: openSettings
            ))
            let window = NSWindow(contentViewController: controller)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: DashboardLayout.popoverWidth, height: 680))
            window.isReleasedWhenClosed = false
            dashboardWindow = window
        }
        dashboardWindow?.title = appState.text(.dashboard)
        dashboardWindow?.center()
        dashboardWindow?.makeKeyAndOrderFront(nil)
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
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 760, height: 820))
        window.minSize = NSSize(width: 680, height: 720)

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
