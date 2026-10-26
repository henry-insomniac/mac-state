import AppKit
import SwiftUI
import MacStateFoundation

@MainActor
final class NotchPanelController: NSObject {
    private let appState: AppState
    private let openDashboard: () -> Void
    private let openHistory: () -> Void
    private let openSettings: () -> Void
    private let panel = NotchPanel(contentRect: .zero,
                                   styleMask: [.borderless, .nonactivatingPanel],
                                   backing: .buffered, defer: false)
    private var hostingView: NotchHostingView<NotchView>?
    private var presentation = NotchPresentation.collapsed
    private var hoverTimer: Timer?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var screen: NSScreen?

    init(appState: AppState, openDashboard: @escaping () -> Void,
         openHistory: @escaping () -> Void, openSettings: @escaping () -> Void) {
        self.appState = appState
        self.openDashboard = openDashboard
        self.openHistory = openHistory
        self.openSettings = openSettings
        super.init()
    }

    func start() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .statusBar
        panel.dismiss = { [weak self] in self?.collapse() }
        let view = NotchHostingView(rootView: makeView())
        view.hoverChanged = { [weak self] inside in self?.hoverChanged(inside) }
        panel.contentView = view
        hostingView = view
        NotificationCenter.default.addObserver(self, selector: #selector(reposition),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(preferencesChanged),
                                               name: UserDefaults.didChangeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(reposition),
                                                          name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(spaceChanged),
                                                          name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        let clicks: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: clicks) { [weak self] _ in
            Task { @MainActor in self?.dismissIfOutside() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: clicks.union(.keyDown)) { [weak self] event in
            // Local event monitors run on AppKit's main event loop.
            let consumed = MainActor.assumeIsolated {
                if event.type == .keyDown, event.keyCode == 53, self?.panel.isKeyWindow == true {
                    self?.collapse()
                    return true
                }
                if event.type != .keyDown { self?.dismissIfOutside() }
                return false
            }
            return consumed ? nil : event
        }
        reposition()
    }

    func stop() {
        hoverTimer?.invalidate()
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        panel.orderOut(nil)
    }

    func show() {
        presentation = .expanded
        render()
        panel.makeKeyAndOrderFront(nil)
    }

    private func collapse() {
        hoverTimer?.invalidate()
        presentation = .collapsed
        panel.resignKey()
        render()
    }

    private func dismissIfOutside() {
        guard presentation != .collapsed, !panel.frame.contains(NSEvent.mouseLocation) else { return }
        collapse()
    }

    private func toggle() {
        hoverTimer?.invalidate()
        presentation.toggle()
        render()
        if presentation == .expanded { panel.makeKeyAndOrderFront(nil) }
        else { panel.resignKey() }
    }

    private func hoverChanged(_ inside: Bool) {
        hoverTimer?.invalidate()
        guard presentation != .expanded else { return }
        hoverTimer = Timer.scheduledTimer(withTimeInterval: inside ? 0.25 : 0.4, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let previous = self.presentation
                // Recheck actual pointer location after resizing/tracking-area replacement.
                if self.panel.frame.contains(NSEvent.mouseLocation) {
                    self.presentation.hover()
                } else {
                    self.presentation.leave()
                }
                if self.presentation != previous { self.render() }
            }
        }
    }

    @objc private func reposition() {
        let screens = NSScreen.screens
        screen = screens.first { candidate in
            if #available(macOS 12.0, *) { return candidate.safeAreaInsets.top > 0 }
            return false
        } ?? screens.first
        collapse()
    }

    @objc private func spaceChanged() { collapse() }
    @objc nonisolated private func preferencesChanged() {
        Task { @MainActor [weak self] in self?.render() }
    }

    private func render() {
        guard let screen else { panel.orderOut(nil); return }
        let showInFullScreen = UserDefaults.standard.bool(forKey: "notchShowInFullScreen")
        var behavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        if showInFullScreen {
            behavior.insert(.fullScreenAuxiliary)
            if #available(macOS 13.0, *) { behavior.insert(.canJoinAllApplications) }
        } else {
            behavior.insert(.fullScreenNone)
        }
        panel.collectionBehavior = behavior
        var safeTop: CGFloat = 0
        var centerX = screen.frame.midX
        var collapsedWidth: CGFloat = 120
        if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
            safeTop = screen.safeAreaInsets.top
            if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea,
               left.width > 0, right.width > 0 {
                centerX = (left.maxX + right.minX) / 2
                collapsedWidth = max(120, right.minX - left.maxX)
            }
        }
        // The hit target sits BELOW the camera and does not steal menu-bar clicks.
        let size: CGSize
        switch presentation {
        case .collapsed: size = CGSize(width: collapsedWidth, height: 12)
        case .preview: size = CGSize(width: 420, height: 230)
        case .expanded: size = CGSize(width: 420, height: 285)
        }
        let frame = NotchGeometry.frame(screen: screen.frame, safeTop: safeTop,
                                        centerX: centerX, size: size)
        panel.acceptsKeyboard = presentation == .expanded
        hostingView?.rootView = makeView()
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion || panel.frame == .zero ? 0 : 0.18
            panel.animator().setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
    }

    private func makeView() -> NotchView {
        NotchView(appState: appState, presentation: presentation,
                  toggle: { [weak self] in self?.toggle() },
                  close: { [weak self] in self?.collapse() },
                  openDashboard: { [weak self] in self?.collapse(); self?.openDashboard() },
                  openHistory: { [weak self] in self?.collapse(); self?.openHistory() },
                  openSettings: { [weak self] in self?.collapse(); self?.openSettings() })
    }
}
