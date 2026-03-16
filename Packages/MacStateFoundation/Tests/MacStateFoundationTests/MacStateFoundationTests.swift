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
