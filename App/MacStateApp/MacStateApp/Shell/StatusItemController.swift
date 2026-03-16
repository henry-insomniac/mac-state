import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject {
    private let appState: AppState
    private let popoverController: PopoverController
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var subscriptions = Set<AnyCancellable>()

    init(
        appState: AppState,
        popoverController: PopoverController
    ) {
        self.appState = appState
        self.popoverController = popoverController
        super.init()
    }

    func start() {
        configureButton()
        render()
        observePublishedValues()
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }

        popoverController.toggle(relativeTo: button)
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            return
        }

        button.action = #selector(togglePopover(_:))
        button.target = self
        button.image = NSImage(
            systemSymbolName: "waveform.path.ecg",
            accessibilityDescription: "mac-state"
        )
        button.imagePosition = .imageLeading
    }

    private func render() {
        statusItem.button?.title = appState.menuBarTitle
    }

    private func observePublishedValues() {
        appState.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.render()
            }
            .store(in: &subscriptions)
    }
}
