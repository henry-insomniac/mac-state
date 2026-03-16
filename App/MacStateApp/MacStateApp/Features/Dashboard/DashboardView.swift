import SwiftUI
import MacStateUI

struct DashboardView: View {
    @ObservedObject var appState: AppState
    let openSettings: @MainActor () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("mac-state")
                    .font(.title2)
                    .bold()

                Text("Live macOS system monitor")
                    .foregroundColor(.secondary)

                MetricCard("CPU") {
                    Text(appState.cpuUsageText)
                        .font(.title2)
                        .bold()

                    Text("Architecture: \(appState.platformSummary)")
                        .foregroundColor(.secondary)
                }

                MetricCard("Memory") {
                    Text(appState.memoryUsageText)
                        .font(.title2)
                        .bold()

                    Text(appState.memoryFootprintText)
                        .foregroundColor(.secondary)
                }

                MetricCard("Network") {
                    Text(appState.downloadRateText)
                        .font(.title2)
                        .bold()

                    Text("Upload \(appState.uploadRateText) • \(appState.networkStatusText)")
                        .foregroundColor(.secondary)
                }

                Text("Last updated \(appState.lastUpdatedText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                }

                Button {
                    appState.refreshNow()
                } label: {
                    Label("Refresh Metrics", systemImage: "arrow.clockwise")
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
