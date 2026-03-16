import Testing
@testable import MacStateFoundation
import Foundation

@Test func architectureIdentifierMatchesCurrentMachine() {
    #if arch(arm64)
    #expect(PlatformCapabilities.currentArchitecture == .appleSilicon)
    #else
    #expect(PlatformCapabilities.currentArchitecture == .intel)
    #endif
}

@Test func minimumSupportedVersionMatchesProjectPolicy() {
    #expect(PlatformCapabilities.minimumSupportedMacOSVersion == 11)
}

@Test func launchAtLoginStatusFlagsReflectRegistrationState() {
    let enabledStatus = LaunchAtLoginStatus(
        availability: .supported,
        registrationState: .enabled
    )
    let approvalStatus = LaunchAtLoginStatus(
        availability: .supported,
        registrationState: .requiresApproval
    )
    let legacyStatus = LaunchAtLoginStatus.legacyHelperRequired

    #expect(enabledStatus.canToggle == true)
    #expect(enabledStatus.isEnabled == true)
    #expect(enabledStatus.requiresApproval == false)

    #expect(approvalStatus.canToggle == true)
    #expect(approvalStatus.isEnabled == true)
    #expect(approvalStatus.requiresApproval == true)

    #expect(legacyStatus.canToggle == false)
    #expect(legacyStatus.isEnabled == false)
    #expect(legacyStatus.requiresApproval == false)
}

@Test func menuBarPresentationDefaultsMatchAppPolicy() {
    let presentation = MenuBarPresentation.default

    #expect(presentation.textMode == .selectedMetrics)
    #expect(presentation.primaryMetric == .cpuUsage)
    #expect(presentation.secondaryMetric == .memoryUsage)
    #expect(presentation.tertiaryMetric == .networkDownload)
    #expect(presentation.selectedMetrics == [.cpuUsage, .memoryUsage, .networkDownload])
}

@Test func sharedWidgetSnapshotStoreRoundTripsSnapshot() {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("widget-snapshot.json", isDirectory: false)
    let store = SharedWidgetSnapshotStore(fileURL: fileURL)

    store.save(.placeholder)
    let restored = store.load()

    #expect(restored == .placeholder)
}

@Test func menuBarPresentationTitlesCanBeLocalized() {
    #expect(MenuBarTextMode.iconOnly.localizedTitle(language: .simplifiedChinese) == "仅图标")
    #expect(MenuBarTextMode.selectedMetrics.localizedTitle(language: .english) == "Multiple Metrics")
    #expect(MenuBarTextMode.twoMetrics.localizedTitle(language: .english) == "Multiple Metrics")
    #expect(MenuBarPrimaryMetric.diskActivity.localizedTitle(language: .simplifiedChinese) == "磁盘活动")
    #expect(MenuBarPrimaryMetric.memoryUsage.localizedCompactTitle(language: .english) == "MEM")
    #expect(MenuBarPrimaryMetric.networkThroughput.localizedCompactTitle(language: .english) == "NET")
}

@Test func appLanguageDisplayNameRespectsPresentationLanguage() {
    #expect(AppLanguage.system.displayName(in: .english) == "System")
    #expect(AppLanguage.system.displayName(in: .simplifiedChinese) == "跟随系统")
}

@Test func dashboardPresentationDefaultsMatchPopoverPolicy() {
    let presentation = DashboardPresentation.default
    let orderedModules = presentation.orderedModules

    #expect(orderedModules.map(\.type) == DashboardModuleType.allCases)
    #expect(presentation.configuration(for: .battery).isVisible == true)
    #expect(presentation.configuration(for: .network).isVisible == true)
    #expect(presentation.configuration(for: .cpu).isVisible == true)
    #expect(presentation.configuration(for: .memory).isVisible == true)
    #expect(presentation.configuration(for: .disk).isVisible == true)
    #expect(presentation.configuration(for: .sensors).isVisible == true)
    #expect(presentation.configuration(for: .cpuCores).isVisible == false)
    #expect(presentation.configuration(for: .alerts).isVisible == false)
    #expect(presentation.configuration(for: .trends).isVisible == false)
    #expect(presentation.configuration(for: .runningApps).isVisible == false)
    #expect(presentation.configuration(for: .cpuCores).isExpandedByDefault == false)
}

@Test func dashboardPresentationNormalizationDeduplicatesAndRestoresMissingModules() {
    let presentation = DashboardPresentation(
        modules: [
            DashboardModuleConfiguration(type: .network, isVisible: false, isExpandedByDefault: true),
            DashboardModuleConfiguration(type: .network, isVisible: true, isExpandedByDefault: false),
            DashboardModuleConfiguration(type: .alerts, isVisible: true, isExpandedByDefault: true),
        ]
    )

    let orderedModules = presentation.orderedModules

    #expect(orderedModules.first?.type == .network)
    #expect(orderedModules.first?.isVisible == false)
    #expect(orderedModules.first?.isExpandedByDefault == false)
    #expect(orderedModules.count == DashboardModuleType.allCases.count)
    #expect(orderedModules.contains { $0.type == .alerts && $0.isVisible })
    #expect(orderedModules.contains { $0.type == .battery && $0.isVisible })
}
