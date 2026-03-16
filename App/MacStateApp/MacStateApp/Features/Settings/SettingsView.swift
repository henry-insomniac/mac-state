import SwiftUI
import MacStateFoundation

struct SettingsView: View {
    @ObservedObject var appState: AppState
    let refreshMetrics: @MainActor () -> Void

    var body: some View {
        Form {
            Section {
                Picker(
                    appState.text(.language),
                    selection: Binding(
                        get: { appState.appLanguage },
                        set: { appState.setAppLanguage($0) }
                    )
                ) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(appState.languageDisplayName(language)).tag(language)
                    }
                }
            }

            Section {
                Toggle(
                    appState.text(.launchAtLogin),
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
                    Label(appState.text(.refreshLaunchAtLoginStatus), systemImage: "arrow.clockwise")
                }
            }

            Section {
                Picker(
                    appState.text(.menuBarText),
                    selection: Binding(
                        get: { appState.menuBarPresentation.textMode },
                        set: { appState.setMenuBarTextMode($0) }
                    )
                ) {
                    ForEach(MenuBarTextMode.allCases, id: \.self) { textMode in
                        Text(appState.menuBarTextModeTitle(textMode)).tag(textMode)
                    }
                }

                Picker(
                    appState.text(.primaryMetric),
                    selection: Binding(
                        get: { appState.menuBarPresentation.primaryMetric },
                        set: { appState.setMenuBarPrimaryMetric($0) }
                    )
                ) {
                    ForEach(MenuBarPrimaryMetric.allCases, id: \.self) { metric in
                        Text(appState.menuBarPrimaryMetricTitle(metric)).tag(metric)
                    }
                }

                Text(appState.menuBarSettingsSummaryText)
                    .foregroundColor(.secondary)

                Text("\(appState.text(.preview)): \(appState.menuBarPreviewText) · \(appState.menuBarMetricTitle)")
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle(
                    appState.text(.alertWhenCPUUsageHigh),
                    isOn: Binding(
                        get: { appState.alertConfiguration.cpuHighUsage.isEnabled },
                        set: { appState.setCPUAlertEnabled($0) }
                    )
                )
                Stepper(
                    "\(appState.text(.cpuThreshold)): \(appState.alertConfiguration.cpuHighUsage.thresholdPercent)%",
                    value: Binding(
                        get: { appState.alertConfiguration.cpuHighUsage.thresholdPercent },
                        set: { appState.setCPUAlertThreshold($0) }
                    ),
                    in: 50...100
                )

                Toggle(
                    appState.text(.alertWhenMemoryUsageHigh),
                    isOn: Binding(
                        get: { appState.alertConfiguration.memoryHighUsage.isEnabled },
                        set: { appState.setMemoryAlertEnabled($0) }
                    )
                )
                Stepper(
                    "\(appState.text(.memoryThreshold)): \(appState.alertConfiguration.memoryHighUsage.thresholdPercent)%",
                    value: Binding(
                        get: { appState.alertConfiguration.memoryHighUsage.thresholdPercent },
                        set: { appState.setMemoryAlertThreshold($0) }
                    ),
                    in: 50...100
                )

                Toggle(
                    appState.text(.alertWhenBatteryLow),
                    isOn: Binding(
                        get: { appState.alertConfiguration.batteryLowLevel.isEnabled },
                        set: { appState.setBatteryAlertEnabled($0) }
                    )
                )
                Stepper(
                    "\(appState.text(.batteryThreshold)): \(appState.alertConfiguration.batteryLowLevel.thresholdPercent)%",
                    value: Binding(
                        get: { appState.alertConfiguration.batteryLowLevel.thresholdPercent },
                        set: { appState.setBatteryAlertThreshold($0) }
                    ),
                    in: 5...50
                )

                Toggle(
                    appState.text(.alertWhenDiskActivityHigh),
                    isOn: Binding(
                        get: { appState.alertConfiguration.diskActivityHigh.isEnabled },
                        set: { appState.setDiskAlertEnabled($0) }
                    )
                )
                Stepper(
                    "\(appState.text(.diskThreshold)): \(appState.alertConfiguration.diskActivityHigh.thresholdMegabytesPerSecond) MB/s",
                    value: Binding(
                        get: { appState.alertConfiguration.diskActivityHigh.thresholdMegabytesPerSecond },
                        set: { appState.setDiskAlertThreshold($0) }
                    ),
                    in: 10...2_000,
                    step: 10
                )

                Stepper(
                    "\(appState.text(.alertCooldown)): \(appState.alertConfiguration.clampedCooldownMinutes) \(appState.resolvedLanguage == .simplifiedChinese ? "分钟" : "minutes")",
                    value: Binding(
                        get: { appState.alertConfiguration.clampedCooldownMinutes },
                        set: { appState.setAlertCooldownMinutes($0) }
                    ),
                    in: 1...60
                )

                Text(appState.text(.alertsUseLocalNotifications))
                    .foregroundColor(.secondary)
                Text(appState.alertsSummaryText)
                    .foregroundColor(.secondary)
            }

            Section {
                Button {
                    refreshMetrics()
                } label: {
                    Label(appState.text(.refreshMetrics), systemImage: "arrow.clockwise")
                }

                Text("\(appState.text(.currentArchitecture)): \(appState.platformArchitectureText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.diskFootprint)): \(appState.diskFootprintText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.diskActivityLabel)): \(appState.diskActivityText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.batteryLabelWithColon)): \(appState.batteryDetailText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.thermalCondition)): \(appState.thermalConditionText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.sensorSource)): \(appState.sensorSourceText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.cpuTemperature)): \(appState.cpuTemperatureText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.gpuTemperature)): \(appState.gpuTemperatureText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.batteryTemperature)): \(appState.batteryTemperatureText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.cooling)): \(appState.fanStatusText)")
                    .foregroundColor(.secondary)

                Text(appState.sensorAvailabilityText)
                    .foregroundColor(.secondary)

                Text("\(appState.text(.perCoreCPU)): \(appState.cpuCoreCountText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.dashboardAppList)): \(appState.runningAppsText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.trendCache)): \(appState.historyStorageSummaryText)")
                    .foregroundColor(.secondary)

                Text("\(appState.text(.lastUpdated)) \(appState.lastUpdatedText)")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 460, minHeight: 520)
    }
}
