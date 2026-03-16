import Foundation

public actor SettingsStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func bool(for key: SettingsKey) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }

    public func set(_ value: Bool, for key: SettingsKey) {
        defaults.set(value, forKey: key.rawValue)
    }
}
