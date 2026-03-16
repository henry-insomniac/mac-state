import SwiftUI
import UniformTypeIdentifiers
import MacStateMetrics
import MacStateStorage
import MacStateUI

private enum HistoryTimeRange: CaseIterable, Identifiable {
    case live
    case day

    var id: Self {
        self
    }

    var fileNameComponent: String {
        switch self {
        case .live:
            return "live"
        case .day:
            return "24-hours"
        }
    }
}

private struct HistoryExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.commaSeparatedText]
    }

    let data: Data

    init(csvString: String) {
        self.data = Data(csvString.utf8)
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
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
    let latestTitle: String
    let averageTitle: String
    let peakTitle: String

    var body: some View {
        MetricCard(title) {
            Text(subtitle)
                .foregroundColor(.secondary)

            TimelineChart(values: values, tint: tint)

            HStack(spacing: 16) {
                metricSummary(title: latestTitle, value: latestText)
                metricSummary(title: averageTitle, value: averageText)
                metricSummary(title: peakTitle, value: peakText)
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
    @State private var exportDocument = HistoryExportDocument(csvString: "")
    @State private var exportFilename = "mac-state-history.csv"
    @State private var isExporting = false
    @State private var exportErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(appState.text(.history))
                        .font(.title2)
                        .bold()

                    Spacer()

                    Button(appState.text(.exportCSV), action: prepareExport)
                        .disabled(selectedSamples.isEmpty)
                }

                Text(subtitle(for: selectedRange))
                    .foregroundColor(.secondary)

                Picker(appState.text(.timeRange), selection: $selectedRange) {
                    ForEach(HistoryTimeRange.allCases) { range in
                        Text(title(for: range)).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                Text(historySummaryText)
                    .foregroundColor(.secondary)

                HistoryMetricCard(
                    title: appState.text(.cpuUsage),
                    subtitle: appState.text(.overallSystemCPUUtilization),
                    tint: .red,
                    values: values(for: \.cpuUsage),
                    latestText: percentageText(for: latestValue(for: \.cpuUsage)),
                    averageText: percentageText(for: averageValue(for: \.cpuUsage)),
                    peakText: percentageText(for: peakValue(for: \.cpuUsage)),
                    latestTitle: appState.text(.latest),
                    averageTitle: appState.text(.average),
                    peakTitle: appState.text(.peak)
                )

                HistoryMetricCard(
                    title: appState.text(.memoryUsage),
                    subtitle: appState.text(.residentMemoryPressureOverTime),
                    tint: .blue,
                    values: values(for: \.memoryUsage),
                    latestText: percentageText(for: latestValue(for: \.memoryUsage)),
                    averageText: percentageText(for: averageValue(for: \.memoryUsage)),
                    peakText: percentageText(for: peakValue(for: \.memoryUsage)),
                    latestTitle: appState.text(.latest),
                    averageTitle: appState.text(.average),
                    peakTitle: appState.text(.peak)
                )

                HistoryMetricCard(
                    title: appState.text(.networkThroughput),
                    subtitle: appState.text(.combinedUploadAndDownloadThroughput),
                    tint: .green,
                    values: values { Double($0.networkThroughputBytesPerSecond) },
                    latestText: rateText(for: latestValue { Double($0.networkThroughputBytesPerSecond) }),
                    averageText: rateText(for: averageValue { Double($0.networkThroughputBytesPerSecond) }),
                    peakText: rateText(for: peakValue { Double($0.networkThroughputBytesPerSecond) }),
                    latestTitle: appState.text(.latest),
                    averageTitle: appState.text(.average),
                    peakTitle: appState.text(.peak)
                )

                HistoryMetricCard(
                    title: appState.text(.diskActivity),
                    subtitle: appState.text(.combinedReadAndWriteThroughput),
                    tint: .gray,
                    values: values { Double($0.diskThroughputBytesPerSecond) },
                    latestText: rateText(for: latestValue { Double($0.diskThroughputBytesPerSecond) }),
                    averageText: rateText(for: averageValue { Double($0.diskThroughputBytesPerSecond) }),
                    peakText: rateText(for: peakValue { Double($0.diskThroughputBytesPerSecond) }),
                    latestTitle: appState.text(.latest),
                    averageTitle: appState.text(.average),
                    peakTitle: appState.text(.peak)
                )

                HistoryMetricCard(
                    title: appState.text(.diskCapacity),
                    subtitle: appState.text(.usedCapacityPrimaryVolume),
                    tint: Color(red: 0.55, green: 0.38, blue: 0.22),
                    values: values(for: \.diskUsage),
                    latestText: percentageText(for: latestValue(for: \.diskUsage)),
                    averageText: percentageText(for: averageValue(for: \.diskUsage)),
                    peakText: percentageText(for: peakValue(for: \.diskUsage)),
                    latestTitle: appState.text(.latest),
                    averageTitle: appState.text(.average),
                    peakTitle: appState.text(.peak)
                )

                HistoryMetricCard(
                    title: appState.text(.batteryLevel),
                    subtitle: appState.text(.batteryPercentageWhenAvailable),
                    tint: .orange,
                    values: values { $0.batteryLevel },
                    latestText: percentageText(for: latestValue { $0.batteryLevel }),
                    averageText: percentageText(for: averageValue { $0.batteryLevel }),
                    peakText: percentageText(for: peakValue { $0.batteryLevel }),
                    latestTitle: appState.text(.latest),
                    averageTitle: appState.text(.average),
                    peakTitle: appState.text(.peak)
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 760, height: 820)
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: exportFilename
        ) { result in
            if case .failure(let error) = result {
                exportErrorMessage = error.localizedDescription
            }
        }
        .alert(isPresented: exportErrorIsPresented) {
            Alert(
                title: Text(appState.text(.exportFailed)),
                message: Text(exportErrorMessage ?? appState.text(.unableExportHistoryCSV)),
                dismissButton: .default(Text(appState.text(.ok))) {
                    exportErrorMessage = nil
                }
            )
        }
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
            return appState.text(.unavailable)
        }

        return "\(Int((value * 100).rounded()))%"
    }

    private func rateText(for value: Double?) -> String {
        guard let value else {
            return appState.text(.unavailable)
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

    private var exportErrorIsPresented: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    exportErrorMessage = nil
                }
            }
        )
    }

    private func prepareExport() {
        let csvString = MetricHistoryCSVExporter.csvString(for: selectedSamples)
        exportDocument = HistoryExportDocument(csvString: csvString)
        exportFilename = "mac-state-history-\(selectedRange.fileNameComponent)-\(timestampFileNameComponent()).csv"
        isExporting = true
    }

    private func title(for range: HistoryTimeRange) -> String {
        switch range {
        case .live:
            appState.text(.live)
        case .day:
            appState.text(.day24Hours)
        }
    }

    private func subtitle(for range: HistoryTimeRange) -> String {
        switch range {
        case .live:
            appState.text(.liveHistorySubtitle)
        case .day:
            appState.text(.dayHistorySubtitle)
        }
    }

    private func timestampFileNameComponent(now: Date = Date()) -> String {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: now
        )
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return "\(year)-\(twoDigitString(month))-\(twoDigitString(day))-\(twoDigitString(hour))\(twoDigitString(minute))"
    }

    private func twoDigitString(_ value: Int) -> String {
        if value < 10 {
            return "0\(value)"
        }

        return "\(value)"
    }
}
