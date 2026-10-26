import Foundation

/// Limits disk writes and WidgetKit requests independently of the two-second sampler.
public struct WidgetDeliveryPolicy: Sendable {
    public static let writeInterval: TimeInterval = 60
    public static let reloadInterval: TimeInterval = 300
    public static let configurationInterval: TimeInterval = 60

    private var lastConfigurationCheck: Date?
    private var hasWidget = false
    private var lastWriteAttempt: Date?
    private var lastReload: Date?

    public init() {}

    public func shouldCheckConfiguration(at date: Date) -> Bool {
        isDue(since: lastConfigurationCheck, at: date, interval: Self.configurationInterval)
    }

    public mutating func recordConfiguration(hasWidget: Bool, at date: Date) {
        if hasWidget != self.hasWidget {
            lastWriteAttempt = nil
            lastReload = nil
        }
        self.hasWidget = hasWidget
        lastConfigurationCheck = date
    }

    public mutating func beginWrite(at date: Date) -> Bool {
        guard hasWidget, isDue(since: lastWriteAttempt, at: date, interval: Self.writeInterval) else {
            return false
        }
        // A failing container must not be retried on every sample.
        lastWriteAttempt = date
        return true
    }

    public mutating func shouldReloadAfterSuccessfulWrite(at date: Date) -> Bool {
        guard isDue(since: lastReload, at: date, interval: Self.reloadInterval) else { return false }
        lastReload = date
        return true
    }

    private func isDue(since previous: Date?, at date: Date, interval: TimeInterval) -> Bool {
        guard let previous else { return true }
        let elapsed = date.timeIntervalSince(previous)
        return elapsed < 0 || elapsed >= interval
    }
}
