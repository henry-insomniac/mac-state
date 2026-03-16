import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject {
    private enum Layout {
        static let iconPadding: CGFloat = 16
        static let imageSpacing: CGFloat = 6
    }

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
        render()
    }

    private func render() {
        guard let button = statusItem.button else {
            return
        }

        let title = appState.menuBarTitle
        button.toolTip = appState.menuBarAccessibilityLabel
        button.image = NSImage(
            systemSymbolName: appState.menuBarSymbolName,
            accessibilityDescription: appState.menuBarAccessibilityLabel
        )
        button.imagePosition = title.isEmpty ? .imageOnly : .imageLeading
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: titleFont,
            ]
        )
        statusItem.length = statusItemLength(for: title, button: button)
    }

    private var titleFont: NSFont {
        NSFont.monospacedDigitSystemFont(
            ofSize: NSFont.systemFontSize(for: .small),
            weight: .regular
        )
    }

    private func statusItemLength(
        for title: String,
        button: NSStatusBarButton
    ) -> CGFloat {
        guard title.isEmpty == false else {
            return NSStatusItem.squareLength
        }

        let titleWidth = reservedTitleWidth
        let imageWidth = button.image?.size.width ?? NSStatusItem.squareLength
        return ceil(titleWidth + imageWidth + Layout.iconPadding + Layout.imageSpacing)
    }

    private var reservedTitleWidth: CGFloat {
        let sampleText: String

        switch appState.menuBarPresentation.textMode {
        case .iconOnly:
            return 0
        case .appName:
            sampleText = appState.text(.appTitle)
        case .selectedMetric:
            sampleText = reservedMetricSampleText
        }

        return ceil((sampleText as NSString).size(withAttributes: [.font: titleFont]).width)
    }

    private var reservedMetricSampleText: String {
        switch appState.menuBarPresentation.primaryMetric {
        case .cpuUsage, .memoryUsage, .batteryLevel:
            return "100%"
        case .networkDownload, .networkUpload, .diskActivity:
            return "999.9 MB/s"
        }
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
