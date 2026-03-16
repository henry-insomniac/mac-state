import SwiftUI
import MacStateMetrics
import MacStateUI

private enum HistoryTimeRange: String, CaseIterable, Identifiable {
    case live = "Live"
    case day = "24 Hours"

    var id: Self {
        self
    }

    var subtitle: String {
        switch self {
        case .live:
            return "Recent raw samples captured during active monitoring"
        case .day:
            return "Minute-level aggregates retained for the last 24 hours"
        }
    }
}

private struct HistoryMetricCard: View {
    let title: String
    let subtitle: String
    let tint: Color
    let values: [Double]
    let latestText: String
    let averageText: String
    let peakText: String

    var body: some View {
        MetricCard(title) {
            Text(subtitle)
                .foregroundColor(.secondary)

            TimelineChart(values: values, tint: tint)

            HStack(spacing: 16) {
                metricSummary(title: "Latest", value: latestText)
                metricSummary(title: "Average", value: averageText)
                metricSummary(title: "Peak", value: peakText)
            }
        }
    }

    @ViewBuilder
    private func metricSummary(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HistoryView: View {
    @ObservedObject var appState: AppState
    @State private var selectedRange: HistoryTimeRange = .live

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("History")
                    .font(.title2)
                    .bold()

                Text(selectedRange.subtitle)
                    .foregroundColor(.secondary)

                Picker("Time Range", selection: $selectedRange) {
                    ForEach(HistoryTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                Text(historySummaryText)
                    .foregroundColor(.secondary)

                HistoryMetricCard(
                    title: "CPU Usage",
                    subtitle: "Overall system CPU utilization",
                    tint: .red,
                    values: values(for: \.cpuUsage),
                    latestText: percentageText(for: latestValue(for: \.cpuUsage)),
                    averageText: percentageText(for: averageValue(for: \.cpuUsage)),
                    peakText: percentageText(for: peakValue(for: \.cpuUsage))
                )

                HistoryMetricCard(
                    title: "Memory Usage",
                    subtitle: "Resident memory pressure over time",
                    tint: .blue,
                    values: values(for: \.memoryUsage),
                    latestText: percentageText(for: latestValue(for: \.memoryUsage)),
                    averageText: percentageText(for: averageValue(for: \.memoryUsage)),
                    peakText: percentageText(for: peakValue(for: \.memoryUsage))
                )

                HistoryMetricCard(
                    title: "Network Throughput",
                    subtitle: "Combined upload and download throughput",
                    tint: .green,
                    values: values { Double($0.networkThroughputBytesPerSecond) },
                    latestText: rateText(for: latestValue { Double($0.networkThroughputBytesPerSecond) }),
                    averageText: rateText(for: averageValue { Double($0.networkThroughputBytesPerSecond) }),
                    peakText: rateText(for: peakValue { Double($0.networkThroughputBytesPerSecond) })
                )

                HistoryMetricCard(
                    title: "Disk Activity",
                    subtitle: "Combined read and write throughput",
                    tint: .gray,
                    values: values { Double($0.diskThroughputBytesPerSecond) },
                    latestText: rateText(for: latestValue { Double($0.diskThroughputBytesPerSecond) }),
                    averageText: rateText(for: averageValue { Double($0.diskThroughputBytesPerSecond) }),
                    peakText: rateText(for: peakValue { Double($0.diskThroughputBytesPerSecond) })
                )

                HistoryMetricCard(
                    title: "Disk Capacity",
                    subtitle: "Used capacity as a percentage of the primary volume",
                    tint: Color(red: 0.55, green: 0.38, blue: 0.22),
                    values: values(for: \.diskUsage),
                    latestText: percentageText(for: latestValue(for: \.diskUsage)),
                    averageText: percentageText(for: averageValue(for: \.diskUsage)),
                    peakText: percentageText(for: peakValue(for: \.diskUsage))
                )

                HistoryMetricCard(
                    title: "Battery Level",
                    subtitle: "Battery percentage when battery metrics are available",
                    tint: .orange,
                    values: values { $0.batteryLevel },
                    latestText: percentageText(for: latestValue { $0.batteryLevel }),
                    averageText: percentageText(for: averageValue { $0.batteryLevel }),
                    peakText: percentageText(for: peakValue { $0.batteryLevel })
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 760, height: 820)
    }

    private var selectedSamples: [MetricHistorySample] {
        switch selectedRange {
        case .live:
            appState.historySamples
        case .day:
            appState.dayHistorySamples
        }
    }

    private var historySummaryText: String {
        switch selectedRange {
        case .live:
            return appState.historySummaryText
        case .day:
            return appState.dayHistorySummaryText
        }
    }

    private func values(
        for keyPath: KeyPath<MetricHistorySample, Double>
    ) -> [Double] {
        selectedSamples.map { $0[keyPath: keyPath] }
    }

    private func values(
        _ transform: (MetricHistorySample) -> Double?
    ) -> [Double] {
        selectedSamples.compactMap(transform)
    }

    private func latestValue(
        for keyPath: KeyPath<MetricHistorySample, Double>
    ) -> Double? {
        selectedSamples.last?[keyPath: keyPath]
    }

    private func latestValue(
        _ transform: (MetricHistorySample) -> Double?
    ) -> Double? {
        values(transform).last
    }

    private func averageValue(
        for keyPath: KeyPath<MetricHistorySample, Double>
    ) -> Double? {
        averageValue { $0[keyPath: keyPath] }
    }

    private func averageValue(
        _ transform: (MetricHistorySample) -> Double?
    ) -> Double? {
        let values = values(transform)
        guard values.isEmpty == false else {
            return nil
        }

        let total = values.reduce(0, +)
        return total / Double(values.count)
    }

    private func peakValue(
        for keyPath: KeyPath<MetricHistorySample, Double>
    ) -> Double? {
        peakValue { $0[keyPath: keyPath] }
    }

    private func peakValue(
        _ transform: (MetricHistorySample) -> Double?
    ) -> Double? {
        values(transform).max()
    }

    private func percentageText(for value: Double?) -> String {
        guard let value else {
            return "Unavailable"
        }

        return "\(Int((value * 100).rounded()))%"
    }

    private func rateText(for value: Double?) -> String {
        guard let value else {
            return "Unavailable"
        }

        if value >= 1_048_576 {
            return "\(decimalString(from: value / 1_048_576)) MB/s"
        }

        if value >= 1_024 {
            return "\(decimalString(from: value / 1_024)) KB/s"
        }

        return "\(Int(value.rounded())) B/s"
    }

    private func decimalString(from value: Double) -> String {
        let roundedValue = (value * 10).rounded() / 10
        let wholePart = Int(roundedValue.rounded(.towardZero))
        let decimalPart = Int(abs((roundedValue - Double(wholePart)) * 10).rounded())

        return "\(wholePart).\(decimalPart)"
    }
}
