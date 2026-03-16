import Testing
@testable import MacStateStorage
import Foundation

@Test func settingsStoreReadsValuesThatWereWritten() async {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let store = SettingsStore(defaults: defaults)

    await store.set(true, for: SettingsKey.compactMenuBarText)

    let value = await store.bool(for: .compactMenuBarText)

    #expect(value == true)
}
