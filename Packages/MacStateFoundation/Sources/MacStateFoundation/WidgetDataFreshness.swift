import Foundation

public enum WidgetDataFreshness: Sendable, Equatable {
    case missing
    case current
    case stale

    public static let maximumAge: TimeInterval = 600

    public init(timestamp: Date?, now: Date) {
        guard let timestamp else { self = .missing; return }
        let age = now.timeIntervalSince(timestamp)
        // Do not present a future-dated snapshot as live after a clock change.
        self = age >= -60 && age < Self.maximumAge ? .current : .stale
    }
}
