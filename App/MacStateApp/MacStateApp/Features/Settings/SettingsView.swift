import AppKit
import SwiftUI
import MacStateFoundation

private enum SettingsLayout {
    static let contentWidth: CGFloat = 720
    static let minimumWindowWidth: CGFloat = 700
    static let minimumWindowHeight: CGFloat = 760
    static let controlWidth: CGFloat = 220
    static let sectionSpacing: CGFloat = 20
    static let valueColumnWidth: CGFloat = 280
    static let outerPadding: CGFloat = 24
}

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case alerts
    case diagnostics
    case about

    var id: Self { self }
}

struct SettingsView: View {
    @ObservedObject var appState: AppState
    let refreshMetrics: @MainActor () -> Void
    @State private var selectedPane: SettingsPane = .general

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.05),
                    Color.primary.opacity(0.01),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(0.85)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                    HStack(alignment: .center, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.primary.opacity(0.08))

                            Image(systemName: "waveform.path.ecg.rectangle.fill")
                                .font(.title2)
                                .foregroundColor(Color.primary)
                        }
                        .frame(width: 60, height: 60)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(appState.text(.settings))
                                .font(.largeTitle)
                                .bold()

                            Text(appState.text(.settingsSubtitle))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 16)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(appState.text(.appVersion))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(appVersionText)
                                .font(.system(.body, design: .monospaced))
                                .bold()
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(SettingsPane.allCases) { pane in
                            Button {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    selectedPane = pane
                                }
                            } label: {
                                Text(title(for: pane))
                                    .font(.subheadline)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                            }
                            .buttonStyle(.plain)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        selectedPane == pane
                                            ? Color.primary.opacity(0.12)
                                            : Color.primary.opacity(0.04)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        Color.primary.opacity(selectedPane == pane ? 0.22 : 0.08),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }

                    switch selectedPane {
                    case .general:
                        SettingsSectionCard(
                            appState.text(.general),
                            summary: appState.text(.generalSummary)
                        ) {
                            SettingsControlRow(title: appState.text(.language)) {
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
                                .labelsHidden()
                                .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                            }
                        }

                        SettingsSectionCard(
                            appState.text(.launchAtLogin),
                            summary: appState.launchAtLoginSummaryText
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                SettingsControlRow(
                                    title: appState.text(.launchAtLogin),
                                    detail: appState.launchAtLoginDetailText
                                ) {
                                    Toggle(
                                        appState.text(.yes),
                                        isOn: Binding(
                                            get: { appState.launchAtLoginStatus.isEnabled },
                                            set: { appState.setLaunchAtLoginEnabled($0) }
                                        )
                                    )
                                    .labelsHidden()
                                    .disabled(appState.launchAtLoginStatus.canToggle == false)
                                }

                                if let launchAtLoginErrorMessage = appState.launchAtLoginErrorMessage {
                                    Text(launchAtLoginErrorMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Button(
                                    appState.text(.refreshLaunchAtLoginStatus),
                                    systemImage: "arrow.clockwise"
                                ) {
                                    appState.refreshLaunchAtLoginStatus()
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        SettingsSectionCard(
                            appState.text(.menuBar),
                            summary: appState.menuBarSettingsSummaryText
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                SettingsControlRow(title: appState.text(.menuBarText)) {
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
                                    .labelsHidden()
                                    .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                                }

                                SettingsControlRow(title: appState.text(.primaryMetric)) {
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
                                    .labelsHidden()
                                    .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                                }

                                if appState.menuBarPresentation.textMode == .twoMetrics {
                                    SettingsControlRow(title: appState.text(.secondaryMetric)) {
                                        Picker(
                                            appState.text(.secondaryMetric),
                                            selection: Binding(
                                                get: {
                                                    appState.menuBarPresentation.secondaryMetric
                                                        ?? MenuBarPrimaryMetric.allCases.first(where: {
                                                            $0 != appState.menuBarPresentation.primaryMetric
                                                        })
                                                        ?? .memoryUsage
                                                },
                                                set: { appState.setMenuBarSecondaryMetric($0) }
                                            )
                                        ) {
                                            ForEach(
                                                MenuBarPrimaryMetric.allCases.filter {
                                                    $0 != appState.menuBarPresentation.primaryMetric
                                                },
                                                id: \.self
                                            ) { metric in
                                                Text(appState.menuBarPrimaryMetricTitle(metric)).tag(metric)
                                            }
                                        }
                                        .labelsHidden()
                                        .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                                    }
                                }

                                Text("\(appState.text(.preview)): \(appState.menuBarPreviewText)")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.primary.opacity(0.04))
                                    )
                                    .clipShape(.rect(cornerRadius: 12))
                            }
                        }

                    case .alerts:
                        SettingsSectionCard(
                            appState.text(.alerts),
                            summary: appState.text(.alertsSectionSummary)
                        ) {
                            VStack(alignment: .leading, spacing: 18) {
                                Text(appState.alertsStatusText)
                                    .font(.headline)
                                    .fixedSize(horizontal: false, vertical: true)

                                VStack(alignment: .leading, spacing: 12) {
                                    SettingsControlRow(title: appState.text(.alertWhenCPUUsageHigh)) {
                                        Toggle(
                                            appState.text(.yes),
                                            isOn: Binding(
                                                get: { appState.alertConfiguration.cpuHighUsage.isEnabled },
                                                set: { appState.setCPUAlertEnabled($0) }
                                            )
                                        )
                                        .labelsHidden()
                                    }

                                    SettingsControlRow(title: appState.text(.cpuThreshold)) {
                                        HStack(spacing: 10) {
                                            Text("\(appState.alertConfiguration.cpuHighUsage.thresholdPercent)%")
                                                .font(.system(.body, design: .monospaced))
                                                .frame(minWidth: 64, alignment: .trailing)

                                            Stepper(
                                                "",
                                                value: Binding(
                                                    get: { appState.alertConfiguration.cpuHighUsage.thresholdPercent },
                                                    set: { appState.setCPUAlertThreshold($0) }
                                                ),
                                                in: 50...100
                                            )
                                            .labelsHidden()
                                        }
                                        .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                                        .disabled(appState.alertConfiguration.cpuHighUsage.isEnabled == false)
                                    }
                                }

                                Divider()

                                VStack(alignment: .leading, spacing: 12) {
                                    SettingsControlRow(title: appState.text(.alertWhenMemoryUsageHigh)) {
                                        Toggle(
                                            appState.text(.yes),
                                            isOn: Binding(
                                                get: { appState.alertConfiguration.memoryHighUsage.isEnabled },
                                                set: { appState.setMemoryAlertEnabled($0) }
                                            )
                                        )
                                        .labelsHidden()
                                    }

                                    SettingsControlRow(title: appState.text(.memoryThreshold)) {
                                        HStack(spacing: 10) {
                                            Text("\(appState.alertConfiguration.memoryHighUsage.thresholdPercent)%")
                                                .font(.system(.body, design: .monospaced))
                                                .frame(minWidth: 64, alignment: .trailing)

                                            Stepper(
                                                "",
                                                value: Binding(
                                                    get: { appState.alertConfiguration.memoryHighUsage.thresholdPercent },
                                                    set: { appState.setMemoryAlertThreshold($0) }
                                                ),
                                                in: 50...100
                                            )
                                            .labelsHidden()
                                        }
                                        .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                                        .disabled(appState.alertConfiguration.memoryHighUsage.isEnabled == false)
                                    }
                                }

                                Divider()

                                VStack(alignment: .leading, spacing: 12) {
                                    SettingsControlRow(title: appState.text(.alertWhenBatteryLow)) {
                                        Toggle(
                                            appState.text(.yes),
                                            isOn: Binding(
                                                get: { appState.alertConfiguration.batteryLowLevel.isEnabled },
                                                set: { appState.setBatteryAlertEnabled($0) }
                                            )
                                        )
                                        .labelsHidden()
                                    }

                                    SettingsControlRow(title: appState.text(.batteryThreshold)) {
                                        HStack(spacing: 10) {
                                            Text("\(appState.alertConfiguration.batteryLowLevel.thresholdPercent)%")
                                                .font(.system(.body, design: .monospaced))
                                                .frame(minWidth: 64, alignment: .trailing)

                                            Stepper(
                                                "",
                                                value: Binding(
                                                    get: { appState.alertConfiguration.batteryLowLevel.thresholdPercent },
                                                    set: { appState.setBatteryAlertThreshold($0) }
                                                ),
                                                in: 5...50
                                            )
                                            .labelsHidden()
                                        }
                                        .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                                        .disabled(appState.alertConfiguration.batteryLowLevel.isEnabled == false)
                                    }
                                }

                                Divider()

                                VStack(alignment: .leading, spacing: 12) {
                                    SettingsControlRow(title: appState.text(.alertWhenDiskActivityHigh)) {
                                        Toggle(
                                            appState.text(.yes),
                                            isOn: Binding(
                                                get: { appState.alertConfiguration.diskActivityHigh.isEnabled },
                                                set: { appState.setDiskAlertEnabled($0) }
                                            )
                                        )
                                        .labelsHidden()
                                    }

                                    SettingsControlRow(title: appState.text(.diskThreshold)) {
                                        HStack(spacing: 10) {
                                            Text("\(appState.alertConfiguration.diskActivityHigh.thresholdMegabytesPerSecond) MB/s")
                                                .font(.system(.body, design: .monospaced))
                                                .frame(minWidth: 88, alignment: .trailing)

                                            Stepper(
                                                "",
                                                value: Binding(
                                                    get: { appState.alertConfiguration.diskActivityHigh.thresholdMegabytesPerSecond },
                                                    set: { appState.setDiskAlertThreshold($0) }
                                                ),
                                                in: 10...2_000,
                                                step: 10
                                            )
                                            .labelsHidden()
                                        }
                                        .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                                        .disabled(appState.alertConfiguration.diskActivityHigh.isEnabled == false)
                                    }
                                }

                                Divider()

                                SettingsControlRow(title: appState.text(.alertCooldown)) {
                                    HStack(spacing: 10) {
                                        Text(
                                            appState.resolvedLanguage == .simplifiedChinese
                                                ? "\(appState.alertConfiguration.clampedCooldownMinutes) 分钟"
                                                : "\(appState.alertConfiguration.clampedCooldownMinutes) min"
                                        )
                                        .font(.system(.body, design: .monospaced))
                                        .frame(minWidth: 88, alignment: .trailing)

                                        Stepper(
                                            "",
                                            value: Binding(
                                                get: { appState.alertConfiguration.clampedCooldownMinutes },
                                                set: { appState.setAlertCooldownMinutes($0) }
                                            ),
                                            in: 1...60
                                        )
                                        .labelsHidden()
                                    }
                                    .frame(width: SettingsLayout.controlWidth, alignment: .trailing)
                                }

                                Text(appState.text(.alertsUseLocalNotifications))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(appState.alertsSummaryText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                    case .diagnostics:
                        SettingsSectionCard(
                            appState.text(.diagnostics),
                            summary: appState.text(.diagnosticsSummary)
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                Button(
                                    appState.text(.refreshMetrics),
                                    systemImage: "arrow.clockwise"
                                ) {
                                    refreshMetrics()
                                }
                                .buttonStyle(.bordered)

                                SettingsControlRow(title: appState.text(.currentArchitecture)) {
                                    Text(appState.platformArchitectureText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                }

                                SettingsControlRow(title: appState.text(.diskFootprint)) {
                                    Text(appState.diskFootprintText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                SettingsControlRow(title: appState.text(.diskActivityLabel)) {
                                    Text(appState.diskActivityText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                SettingsControlRow(title: appState.text(.batteryLabelWithColon)) {
                                    Text(appState.batteryDetailText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                SettingsControlRow(title: appState.text(.thermalCondition)) {
                                    Text(appState.thermalConditionText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                }

                                SettingsControlRow(title: appState.text(.sensorSource)) {
                                    Text(appState.sensorSourceText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                SettingsControlRow(title: appState.text(.cpuTemperature)) {
                                    Text(appState.cpuTemperatureText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                }

                                SettingsControlRow(title: appState.text(.gpuTemperature)) {
                                    Text(appState.gpuTemperatureText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                }

                                SettingsControlRow(title: appState.text(.batteryTemperature)) {
                                    Text(appState.batteryTemperatureText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                }

                                SettingsControlRow(title: appState.text(.cooling)) {
                                    Text(appState.fanStatusText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                SettingsControlRow(title: appState.text(.perCoreCPU)) {
                                    Text(appState.cpuCoreCountText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                SettingsControlRow(title: appState.text(.dashboardAppList)) {
                                    Text(appState.runningAppsText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                SettingsControlRow(title: appState.text(.trendCache)) {
                                    Text(appState.historyStorageSummaryText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                SettingsControlRow(title: appState.text(.lastUpdated)) {
                                    Text(appState.lastUpdatedText)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }

                    case .about:
                        SettingsSectionCard(
                            appState.text(.aboutApp),
                            summary: appState.text(.aboutSummary)
                        ) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .center, spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.primary.opacity(0.08))

                                        Image(systemName: "waveform.path.ecg.rectangle.fill")
                                            .font(.title2)
                                            .foregroundColor(Color.primary)
                                    }
                                    .frame(width: 52, height: 52)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(appState.text(.appTitle))
                                            .font(.title3)
                                            .bold()

                                        Text(appState.text(.liveMacOSSystemMonitor))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }

                                SettingsControlRow(title: appState.text(.appVersion)) {
                                    Text(appVersionText)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                }

                                SettingsControlRow(title: appState.text(.buildNumber)) {
                                    Text(appBuildText)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                }

                                SettingsControlRow(title: appState.text(.compatibility)) {
                                    Text(appState.compatibilityText)
                                        .frame(maxWidth: SettingsLayout.valueColumnWidth, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Button(
                                    appState.text(.openAboutPanel),
                                    systemImage: "info.circle"
                                ) {
                                    NSApp.activate(ignoringOtherApps: true)
                                    NSApp.orderFrontStandardAboutPanel(nil)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(SettingsLayout.outerPadding)
                .frame(maxWidth: SettingsLayout.contentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(
            minWidth: SettingsLayout.minimumWindowWidth,
            minHeight: SettingsLayout.minimumWindowHeight
        )
    }

    private func title(for pane: SettingsPane) -> String {
        switch pane {
        case .general:
            return appState.text(.general)
        case .alerts:
            return appState.text(.alerts)
        case .diagnostics:
            return appState.text(.diagnostics)
        case .about:
            return appState.text(.aboutApp)
        }
    }

    private var appVersionText: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
            ?? appState.text(.unavailable)
    }

    private var appBuildText: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
            ?? appState.text(.unavailable)
    }
}
