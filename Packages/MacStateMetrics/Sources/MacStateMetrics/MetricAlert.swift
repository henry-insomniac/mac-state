import Foundation

public struct MetricAlert: Sendable, Equatable {
    public let type: MetricAlertType
    public let title: String
    public let body: String

    public init(
        type: MetricAlertType,
        title: String,
        body: String
    ) {
        self.type = type
        self.title = title
        self.body = body
    }
}
