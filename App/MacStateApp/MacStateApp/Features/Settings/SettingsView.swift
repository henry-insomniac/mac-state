import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Form {
            Toggle("Show compact menu bar text", isOn: $appState.compactMenuBarText)

            Text("When enabled, the status item shows a compact CPU summary next to the icon.")
                .foregroundColor(.secondary)

            Button {
                appState.refreshPreviewData()
            } label: {
                Label("Refresh Demo Metrics", systemImage: "arrow.clockwise")
            }

            Text("Last updated \(appState.lastUpdatedText)")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minWidth: 380, minHeight: 240)
    }
}
