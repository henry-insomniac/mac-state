import AppKit
import SwiftUI

@MainActor
final class PopoverController {
    private let popover: NSPopover

    init(
        appState: AppState,
        refreshMetrics: @escaping @MainActor () -> Void,
        openHistory: @escaping @MainActor () -> Void,
        openSettings: @escaping @MainActor () -> Void
    ) {
        let dashboardView = DashboardView(
            appState: appState,
            refreshMetrics: refreshMetrics,
            openHistory: openHistory,
            openSettings: openSettings
        )

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(
            width: DashboardLayout.popoverWidth,
            height: DashboardLayout.popoverHeight
        )
        popover.contentViewController = NSHostingController(rootView: dashboardView)
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            close()
            return
        }

        show(relativeTo: button)
    }

    func close() {
        popover.performClose(nil)
    }

    private func show(relativeTo button: NSStatusBarButton) {
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
    }
}
