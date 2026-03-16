import Foundation
import MacStateMetrics

public struct MetricHistoryArchive: Sendable, Equatable, Codable {
    public let recentSamples: [MetricHistorySample]
    public let daySamples: [MetricHistorySample]

    public init(
        recentSamples: [MetricHistorySample],
        daySamples: [MetricHistorySample]
    ) {
        self.recentSamples = recentSamples
        self.daySamples = daySamples
    }

    public static let empty = MetricHistoryArchive(
        recentSamples: [],
        daySamples: []
    )
}
