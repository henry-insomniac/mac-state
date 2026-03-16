import Testing
@testable import MacStateStorage

@Test func settingsStoreReadsValuesThatWereWritten() async {
    let store = SettingsStore()

    await store.set(true, for: SettingsKey.compactMenuBarText)

    let value = await store.bool(for: .compactMenuBarText)

    #expect(value == true)
}
