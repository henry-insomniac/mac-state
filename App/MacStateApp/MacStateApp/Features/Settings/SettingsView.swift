import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    let refreshMetrics: @MainActor () -> Void

    var body: some View {
        Form {
            Section {
                Toggle(
                    "Launch mac-state at login",
                    isOn: Binding(
                        get: { appState.launchAtLoginStatus.isEnabled },
                        set: { appState.setLaunchAtLoginEnabled($0) }
                    )
                )
                .disabled(appState.launchAtLoginStatus.canToggle == false)

                Text(appState.launchAtLoginSummaryText)
                    .foregroundColor(.secondary)

                Text(appState.launchAtLoginDetailText)
                    .foregroundColor(.secondary)

                if let launchAtLoginErrorMessage = appState.launchAtLoginErrorMessage {
                    Text(launchAtLoginErrorMessage)
                        .foregroundColor(.secondary)
                }

                Button {
                    appState.refreshLaunchAtLoginStatus()
                } label: {
                    Label("Refresh Launch at Login Status", systemImage: "arrow.clockwise")
                }
            }

            Section {
                Toggle(
                    "Show compact menu bar text",
                    isOn: Binding(
                        get: { appState.compactMenuBarText },
                        set: { appState.setCompactMenuBarText($0) }
                    )
                )

                Text("When enabled, the status item shows a compact CPU summary next to the icon.")
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle(
                    "Alert when CPU usage is high",
                    isOn: Binding(
                        get: { appState.alertConfiguration.cpuHighUsage.isEnabled },
                        set: { appState.setCPUAlertEnabled($0) }
                    )
                )
                Stepper(
                    "CPU threshold: \(appState.alertConfiguration.cpuHighUsage.thresholdPercent)%",
                    value: Binding(
                        get: { appState.alertConfiguration.cpuHighUsage.thresholdPercent },
                        set: { appState.setCPUAlertThreshold($0) }
                    ),
                    in: 50...100
                )

                Toggle(
                    "Alert when memory usage is high",
                    isOn: Binding(
                        get: { appState.alertConfiguration.memoryHighUsage.isEnabled },
                        set: { appState.setMemoryAlertEnabled($0) }
                    )
                )
                Stepper(
                    "Memory threshold: \(appState.alertConfiguration.memoryHighUsage.thresholdPercent)%",
                    value: Binding(
                        get: { appState.alertConfiguration.memoryHighUsage.thresholdPercent },
                        set: { appState.setMemoryAlertThreshold($0) }
                    ),
                    in: 50...100
                )

                Toggle(
                    "Alert when battery is low",
                    isOn: Binding(
                        get: { appState.alertConfiguration.batteryLowLevel.isEnabled },
                        set: { appState.setBatteryAlertEnabled($0) }
                    )
                )
                Stepper(
                    "Battery threshold: \(appState.alertConfiguration.batteryLowLevel.thresholdPercent)%",
                    value: Binding(
                        get: { appState.alertConfiguration.batteryLowLevel.thresholdPercent },
                        set: { appState.setBatteryAlertThreshold($0) }
                    ),
                    in: 5...50
                )

                Toggle(
                    "Alert when disk activity is high",
                    isOn: Binding(
                        get: { appState.alertConfiguration.diskActivityHigh.isEnabled },
                        set: { appState.setDiskAlertEnabled($0) }
                    )
                )
                Stepper(
                    "Disk threshold: \(appState.alertConfiguration.diskActivityHigh.thresholdMegabytesPerSecond) MB/s",
                    value: Binding(
                        get: { appState.alertConfiguration.diskActivityHigh.thresholdMegabytesPerSecond },
                        set: { appState.setDiskAlertThreshold($0) }
                    ),
                    in: 10...2_000,
                    step: 10
                )

                Stepper(
                    "Alert cooldown: \(appState.alertConfiguration.clampedCooldownMinutes) minutes",
                    value: Binding(
                        get: { appState.alertConfiguration.clampedCooldownMinutes },
                        set: { appState.setAlertCooldownMinutes($0) }
                    ),
                    in: 1...60
                )

                Text("Alerts use local notifications after notification permission is granted.")
                    .foregroundColor(.secondary)
                Text(appState.alertsSummaryText)
                    .foregroundColor(.secondary)
            }

            Section {
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
        }
        .padding()
        .frame(minWidth: 460, minHeight: 520)
    }
}
