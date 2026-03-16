import AppKit
import SwiftUI

@MainActor
final class PopoverController: NSObject {
    private enum Constants {
        static let closeEventMask: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .keyDown,
        ]
    }

    private let popover: NSPopover
    private weak var anchoredButton: NSStatusBarButton?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

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
        super.init()

        popover.behavior = .applicationDefined
        popover.delegate = self
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
        anchoredButton = button
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
    }

    private func startEventMonitors() {
        stopEventMonitors()

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: Constants.closeEventMask) { [weak self] event in
            self?.handleCloseEvent(event)
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: Constants.closeEventMask) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleCloseEvent(event)
            }
        }
    }

    private func stopEventMonitors() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }

    private func handleCloseEvent(_ event: NSEvent) {
        guard popover.isShown else {
            return
        }

        if event.type == .keyDown {
            if event.keyCode == 53 {
                close()
            }
            return
        }

        let screenPoint = screenPoint(for: event)
        if containsPointInPopover(screenPoint) {
            return
        }

        if containsPointInStatusItem(screenPoint) {
            return
        }

        close()
    }

    private func screenPoint(for event: NSEvent) -> NSPoint {
        if let window = event.window {
            return window.convertPoint(toScreen: event.locationInWindow)
        }

        return event.locationInWindow
    }

    private func containsPointInPopover(_ point: NSPoint) -> Bool {
        guard let popoverWindow = popover.contentViewController?.view.window else {
            return false
        }

        return popoverWindow.frame.contains(point)
    }

    private func containsPointInStatusItem(_ point: NSPoint) -> Bool {
        guard
            let anchoredButton,
            let buttonWindow = anchoredButton.window
        else {
            return false
        }

        let buttonFrame = buttonWindow.convertToScreen(anchoredButton.convert(anchoredButton.bounds, to: nil))
        return buttonFrame.contains(point)
    }

    private func configurePopoverWindowIfNeeded() {
        guard let popoverWindow = popover.contentViewController?.view.window else {
            return
        }

        // Keep the menu bar popover in the active fullscreen space instead of leaving it behind.
        popoverWindow.collectionBehavior.formUnion([.transient, .moveToActiveSpace, .fullScreenAuxiliary])
        popoverWindow.level = .statusBar
        popoverWindow.orderFrontRegardless()
    }
}

@MainActor
extension PopoverController: NSPopoverDelegate {
    func popoverDidShow(_ notification: Notification) {
        configurePopoverWindowIfNeeded()
        startEventMonitors()
    }

    func popoverDidClose(_ notification: Notification) {
        stopEventMonitors()
    }
}
