import SwiftUI

struct DashboardView: View {
    @ObservedObject var appState: AppState
    let openSettings: @MainActor () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("mac-state")
                    .font(.title2)
                    .bold()

                Text("Native macOS system monitor bootstrap")
                    .foregroundColor(.secondary)

                DashboardMetricCardView(
                    title: "CPU",
                    value: appState.cpuUsageText,
                    subtitle: "Menu bar headline metric"
                )

                DashboardMetricCardView(
                    title: "Memory",
                    value: appState.memoryUsageText,
                    subtitle: "Placeholder snapshot for the app shell"
                )

                DashboardMetricCardView(
                    title: "Network",
                    value: appState.downloadRateText,
                    subtitle: "Upload \(appState.uploadRateText)"
                )

                Text("Last updated \(appState.lastUpdatedText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    appState.refreshPreviewData()
                } label: {
                    Label("Refresh Demo Metrics", systemImage: "arrow.clockwise")
                }

                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 360, height: 420)
    }
}
