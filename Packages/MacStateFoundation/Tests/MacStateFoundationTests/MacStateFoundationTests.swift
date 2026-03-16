import Testing
@testable import MacStateFoundation

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

    #expect(presentation.textMode == .selectedMetric)
    #expect(presentation.primaryMetric == .cpuUsage)
}
