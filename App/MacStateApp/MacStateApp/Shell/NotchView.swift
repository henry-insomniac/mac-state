import SwiftUI
import MacStateFoundation

struct NotchView: View {
    // AppState is the existing macOS 11-compatible observable integration boundary.
    @ObservedObject var appState: AppState
    let presentation: NotchPresentation
    let toggle: () -> Void
    let close: () -> Void
    let openDashboard: () -> Void
    let openHistory: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack {
            if presentation == .collapsed {
                Button(action: toggle) {
                    Capsule().fill(Color.white.opacity(0.55))
                        .frame(width: 30, height: 3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appState.resolvedLanguage == .simplifiedChinese ? "展开系统状态" : "Show system status")
            } else {
                HStack {
                    Button(action: toggle) {
                        Label("mac-state", systemImage: presentation == .expanded ? "pin.fill" : "waveform.path.ecg")
                            .font(.headline)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: close) {
                        Label(appState.text(.hideDetails), systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.plain)
                }
                NotchMetricRow(title: appState.text(.cpu), value: appState.cpuUsageText,
                               samples: appState.cpuTrendValues, tint: .orange)
                NotchMetricRow(title: appState.text(.memory), value: appState.memoryUsageText,
                               samples: appState.memoryTrendValues, tint: .blue)
                NotchMetricRow(title: appState.text(.network), value: appState.combinedNetworkRateText,
                               samples: [], tint: .green)
                if let message = appState.errorMessage {
                    Text(message).font(.caption).foregroundColor(.orange)
                }
                if presentation == .expanded {
                    Label(appState.batteryStatusText, systemImage: "battery.100")
                        .font(.caption)
                    HStack {
                        Button(appState.text(.showDetails), action: openDashboard)
                        Spacer()
                        Button(appState.text(.history), action: openHistory)
                        Button(appState.text(.settings), action: openSettings)
                    }
                } else {
                    Button(action: toggle) {
                        Text(appState.resolvedLanguage == .simplifiedChinese ? "点击展开" : "Click to expand")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(presentation == .collapsed ? 0 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: presentation == .collapsed ? 6 : 22, style: .continuous))
        .environment(\.colorScheme, .dark)
    }
}
