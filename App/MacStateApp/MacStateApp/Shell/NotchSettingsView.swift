import SwiftUI

struct NotchSettingsView: View {
    @ObservedObject var appState: AppState
    @AppStorage("notchShowInFullScreen") private var showInFullScreen = false

    var body: some View {
        SettingsSectionCard(appState.resolvedLanguage == .simplifiedChinese ? "刘海面板" : "Notch panel",
                            summary: appState.resolvedLanguage == .simplifiedChinese
                            ? "悬停预览，点击展开。无刘海时显示在屏幕顶部中央。"
                            : "Hover to preview, click to expand. On other displays, use the top-center handle.") {
            Toggle(appState.resolvedLanguage == .simplifiedChinese ? "在全屏应用上显示" : "Show over full-screen apps",
                   isOn: $showInFullScreen)
        }
    }
}
