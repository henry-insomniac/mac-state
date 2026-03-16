import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    let refreshMetrics: @MainActor () -> Void

    var body: some View {
        Form {
            Toggle(
                "Show compact menu bar text",
                isOn: Binding(
                    get: { appState.compactMenuBarText },
                    set: { appState.setCompactMenuBarText($0) }
                )
            )

            Text("When enabled, the status item shows a compact CPU summary next to the icon.")
                .foregroundColor(.secondary)

            Button {
                refreshMetrics()
            } label: {
                Label("Refresh Metrics", systemImage: "arrow.clockwise")
            }

            Text("Current architecture: \(appState.platformSummary)")
                .foregroundColor(.secondary)

            Text("Disk footprint: \(appState.diskFootprintText)")
                .foregroundColor(.secondary)

            Text("Disk activity: \(appState.diskActivityText)")
                .foregroundColor(.secondary)

            Text("Battery: \(appState.batteryDetailText)")
                .foregroundColor(.secondary)

            Text("Per-core CPU: \(appState.cpuCoreCountText)")
                .foregroundColor(.secondary)

            Text("Dashboard app list: \(appState.runningAppsText)")
                .foregroundColor(.secondary)

            Text("Trend cache: \(appState.historySummaryText)")
                .foregroundColor(.secondary)

            Text("Last updated \(appState.lastUpdatedText)")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minWidth: 420, minHeight: 280)
    }
}
