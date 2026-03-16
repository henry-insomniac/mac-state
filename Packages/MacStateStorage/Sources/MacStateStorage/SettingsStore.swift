import Foundation

public actor SettingsStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func bool(for key: SettingsKey) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }

    public func boolValue(for key: SettingsKey) -> Bool? {
        guard defaults.object(forKey: key.rawValue) != nil else {
            return nil
        }

        return defaults.bool(forKey: key.rawValue)
    }

    public func set(_ value: Bool, for key: SettingsKey) {
        defaults.set(value, forKey: key.rawValue)
    }

    public func codableValue<T: Decodable>(
        for key: SettingsKey,
        as type: T.Type
    ) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }

        return try? decoder.decode(T.self, from: data)
    }

    public func set<T: Encodable>(
        _ value: T,
        for key: SettingsKey
    ) {
        guard let data = try? encoder.encode(value) else {
            return
        }

        defaults.set(data, forKey: key.rawValue)
    }
}
