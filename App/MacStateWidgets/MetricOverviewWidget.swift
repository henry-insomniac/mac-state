import SwiftUI
import WidgetKit
import MacStateFoundation

private struct MetricOverviewEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

private struct MetricOverviewProvider: TimelineProvider {
    private let snapshotStore = SharedWidgetSnapshotStore()

    func placeholder(in context: Context) -> MetricOverviewEntry {
        MetricOverviewEntry(
            date: WidgetSnapshot.placeholder.timestamp,
            snapshot: .placeholder
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MetricOverviewEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MetricOverviewEntry>) -> Void) {
        let entry = makeEntry()
        let nextRefreshDate = Date().addingTimeInterval(300)
        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextRefreshDate)
            )
        )
    }

    private func makeEntry() -> MetricOverviewEntry {
        let snapshot = snapshotStore.load() ?? .placeholder

        return MetricOverviewEntry(
            date: snapshot.timestamp,
            snapshot: snapshot
        )
    }
}

private struct MetricOverviewWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MetricOverviewProvider.Entry

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.12, blue: 0.19),
                            Color(red: 0.15, green: 0.18, blue: 0.24),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 14) {
                header

                if family == .systemSmall {
                    compactContent
                } else {
                    expandedContent
                }
            }
            .padding(16)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("mac-state")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(entry.snapshot.platformSummary)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Text(timestampText)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            metricLine(
                title: "CPU",
                value: percentageText(for: entry.snapshot.cpuUsage),
                tint: Color(red: 0.94, green: 0.39, blue: 0.33)
            )
            metricLine(
                title: "Memory",
                value: percentageText(for: entry.snapshot.memoryUsage),
                tint: Color(red: 0.34, green: 0.65, blue: 0.93)
            )
            metricLine(
                title: "Down",
                value: rateText(for: entry.snapshot.networkDownloadBytesPerSecond),
                tint: Color(red: 0.30, green: 0.84, blue: 0.65)
            )
            metricLine(
                title: "Battery",
                value: batteryText,
                tint: Color(red: 0.98, green: 0.75, blue: 0.28)
            )
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                metricTile(
                    title: "CPU",
                    value: percentageText(for: entry.snapshot.cpuUsage),
                    subtitle: "Live usage",
                    tint: Color(red: 0.94, green: 0.39, blue: 0.33)
                )
                metricTile(
                    title: "Memory",
                    value: percentageText(for: entry.snapshot.memoryUsage),
                    subtitle: memoryFootprintText,
                    tint: Color(red: 0.34, green: 0.65, blue: 0.93)
                )
            }

            HStack(spacing: 12) {
                metricTile(
                    title: "Network",
                    value: rateText(for: entry.snapshot.networkDownloadBytesPerSecond),
                    subtitle: "Up \(rateText(for: entry.snapshot.networkUploadBytesPerSecond))",
                    tint: Color(red: 0.30, green: 0.84, blue: 0.65)
                )
                metricTile(
                    title: "Disk",
                    value: rateText(for: entry.snapshot.diskReadBytesPerSecond + entry.snapshot.diskWriteBytesPerSecond),
                    subtitle: diskUsageText,
                    tint: Color(red: 0.76, green: 0.68, blue: 0.56)
                )
            }

            metricLine(
                title: "Battery",
                value: batteryText,
                tint: Color(red: 0.98, green: 0.75, blue: 0.28)
            )
        }
    }

    @ViewBuilder
    private func metricTile(
        title: String,
        value: String,
        subtitle: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }

            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(.white)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.65))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }

    @ViewBuilder
    private func metricLine(
        title: String,
        value: String,
        tint: Color
    ) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    private var timestampText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.snapshot.timestamp)
    }

    private var memoryFootprintText: String {
        "\(storageText(for: entry.snapshot.memoryUsedBytes)) / \(storageText(for: entry.snapshot.memoryTotalBytes))"
    }

    private var diskUsageText: String {
        guard entry.snapshot.diskTotalBytes > 0 else {
            return "No disk data"
        }

        let usage = Double(entry.snapshot.diskUsedBytes) / Double(entry.snapshot.diskTotalBytes)
        return "\(Int((usage * 100).rounded()))% used"
    }

    private var batteryText: String {
        guard let batteryLevel = entry.snapshot.batteryLevel else {
            return "Unavailable"
        }

        let prefix = entry.snapshot.batteryIsCharging ? "Charging" : "Battery"
        return "\(prefix) \(percentageText(for: batteryLevel))"
    }

    private func percentageText(for value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func storageText(for bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var scaledValue = Double(bytes)
        var unitIndex = 0

        while scaledValue >= 1_024, unitIndex < units.count - 1 {
            scaledValue /= 1_024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(bytes) \(units[unitIndex])"
        }

        return "\(decimalText(for: scaledValue)) \(units[unitIndex])"
    }

    private func rateText(for bytesPerSecond: UInt64) -> String {
        let value = Double(bytesPerSecond)

        if value >= 1_048_576 {
            return "\(decimalText(for: value / 1_048_576)) MB/s"
        }

        if value >= 1_024 {
            return "\(decimalText(for: value / 1_024)) KB/s"
        }

        return "\(bytesPerSecond) B/s"
    }

    private func decimalText(for value: Double) -> String {
        let roundedValue = (value * 10).rounded() / 10
        let wholePart = Int(roundedValue.rounded(.towardZero))
        let decimalPart = Int(abs((roundedValue - Double(wholePart)) * 10).rounded())

        return "\(wholePart).\(decimalPart)"
    }
}

struct MetricOverviewWidget: Widget {
    private let kind = "MetricOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MetricOverviewProvider()
        ) { entry in
            MetricOverviewWidgetView(entry: entry)
        }
        .configurationDisplayName("System Overview")
        .description("Shows the latest mac-state CPU, memory, network, disk, and battery metrics.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
        ])
    }
}
