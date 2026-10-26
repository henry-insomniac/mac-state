import Foundation

/// Interaction state is independent of the window so pointer races are testable.
public enum NotchPresentation: Sendable, Equatable {
    case collapsed
    case preview
    case expanded

    public mutating func hover() {
        if self == .collapsed { self = .preview }
    }

    public mutating func leave() {
        if self == .preview { self = .collapsed }
    }

    public mutating func toggle() {
        self = self == .expanded ? .collapsed : .expanded
    }
}
