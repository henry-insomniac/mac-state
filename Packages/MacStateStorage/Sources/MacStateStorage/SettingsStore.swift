public actor SettingsStore {
    private var boolValues: [SettingsKey: Bool] = [:]

    public init() {}

    public func bool(for key: SettingsKey) -> Bool {
        boolValues[key] ?? false
    }

    public func set(_ value: Bool, for key: SettingsKey) {
        boolValues[key] = value
    }
}
