import Testing
@testable import MacStateUI

@Test func metricCardStyleUsesRoundedCorners() {
    #expect(MetricCardStyle.cornerRadius > 0)
}

@Test func trendStripSamplerLimitsVisibleSamples() {
    let values = (0..<180).map(Double.init)

    let sampledValues = TrendStripSampler.binnedNormalizedValues(
        from: values,
        maximumSampleCount: 32
    )

    #expect(sampledValues.count == 32)
    #expect(sampledValues.allSatisfy { $0 >= 0 && $0 <= 1 })
}

@Test func trendStripSamplerPreservesSmallSeries() {
    let values = [2.0, 4.0, 8.0]

    let sampledValues = TrendStripSampler.binnedNormalizedValues(
        from: values,
        maximumSampleCount: 32
    )

    #expect(sampledValues.count == values.count)
    #expect(sampledValues.last == 1)
}
