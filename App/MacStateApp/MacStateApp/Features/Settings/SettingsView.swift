import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

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
                appState.refreshNow()
            } label: {
                Label("Refresh Metrics", systemImage: "arrow.clockwise")
            }

            Text("Current architecture: \(appState.platformSummary)")
                .foregroundColor(.secondary)

            Text("Last updated \(appState.lastUpdatedText)")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minWidth: 380, minHeight: 240)
    }
}
