import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let container = AppAssembler.makeLiveContainer()
    private lazy var windowRouter = WindowRouter(appState: container.appState)
    private lazy var popoverController = PopoverController(
        appState: container.appState,
        refreshMetrics: { [weak self] in
            self?.container.metricsMonitor.refreshNow()
        },
        openHistory: { [weak self] in
            self?.openHistory(nil)
        },
        openSettings: { [weak self] in
            self?.openSettings(nil)
        }
    )
    private lazy var statusItemController = StatusItemController(
        appState: container.appState,
        popoverController: popoverController
    )
    private var subscriptions = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.mainMenu = makeMainMenu()
        observeLanguageChanges()
        statusItemController.start()
        Task {
            await container.appState.loadPersistedState()
            refreshLocalizedChrome()
            if container.appState.alertConfiguration.hasEnabledRules {
                await container.alertNotificationService.requestAuthorizationIfNeeded()
            }
            container.metricsMonitor.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        container.metricsMonitor.stop()
    }

    @objc
    private func openHistory(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        windowRouter.showHistory()
    }

    @objc
    private func openSettings(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        windowRouter.showSettings(
            refreshMetrics: { [weak self] in
                self?.container.metricsMonitor.refreshNow()
            }
        )
    }

    @objc
    private func quitApplication(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func observeLanguageChanges() {
        container.appState.$appLanguage
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshLocalizedChrome()
            }
            .store(in: &subscriptions)
    }

    private func refreshLocalizedChrome() {
        NSApp.mainMenu = makeMainMenu()
        windowRouter.refreshLocalizedChrome()
    }

    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        let applicationMenuItem = NSMenuItem()
        let applicationMenu = NSMenu()

        applicationMenu.addItem(
            withTitle: container.appState.text(.aboutApp),
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        applicationMenu.addItem(.separator())
        applicationMenu.addItem(
            withTitle: container.appState.text(.settings) + "…",
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
        )
        applicationMenu.addItem(
            withTitle: container.appState.text(.history),
            action: #selector(openHistory(_:)),
            keyEquivalent: ""
        )
        applicationMenu.addItem(.separator())
        applicationMenu.addItem(
            withTitle: container.appState.text(.hideApp),
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        applicationMenu.addItem(
            withTitle: container.appState.text(.hideOthers),
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        ).keyEquivalentModifierMask = [.command, .option]
        applicationMenu.addItem(
            withTitle: container.appState.text(.showAll),
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )
        applicationMenu.addItem(.separator())
        applicationMenu.addItem(
            withTitle: container.appState.text(.quitApp),
            action: #selector(quitApplication(_:)),
            keyEquivalent: "q"
        )

        applicationMenuItem.submenu = applicationMenu
        mainMenu.addItem(applicationMenuItem)

        return mainMenu
    }
}
