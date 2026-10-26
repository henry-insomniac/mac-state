import SwiftUI

struct AppPrivacyView: View {
    @Environment(\.presentationMode) private var presentationMode
    let chinese: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(chinese ? "隐私与支持" : "Privacy & support").font(.title2).bold()
            ScrollView {
                Text(chinese
                     ? "mac-state 在本机读取系统状态，用于展示 CPU、内存、网络计数、磁盘容量、电池、热状态和正在运行的应用信息。设置、监控历史与 Widget 快照保存在本机应用容器及共享容器中。应用不向开发者发送这些数据，不包含广告、分析或跟踪 SDK。\n\n只有你主动导出时，CSV 才会写入你选择的位置。如果该位置由 iCloud、其他云盘或备份服务同步，文件将遵循该服务的设置。\n\n通知和登录启动由你控制。你可以在历史窗口清除监控历史。卸载应用不一定删除系统保留的容器数据。\n\n你主动发送支持邮件时，邮箱服务和开发者会收到你提供的邮件内容。请勿附带不必要的个人信息。"
                     : "mac-state reads system status locally to display CPU, memory, network counters, disk capacity, battery, thermal state and running application information. Settings, monitoring history and Widget snapshots stay in the app and shared containers on your Mac. The app sends none of this data to the developer and includes no ads, analytics or tracking SDKs.\n\nCSV is written only when you export to a location you choose. iCloud, other cloud storage and backup services may synchronize that location according to their settings.\n\nNotifications and launch at login are controlled by you. Clear monitoring history from the History window. Uninstalling the app may leave system-retained container data.\n\nIf you email support, your mail provider and the developer receive the content you choose to send. Please avoid unnecessary personal information.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                if let policyURL = URL(string: "https://henry-insomniac.github.io/mac-state/app-store/privacy.html") {
                    Link(chinese ? "完整隐私政策" : "Privacy policy", destination: policyURL)
                }
                if let supportPageURL = URL(string: "https://henry-insomniac.github.io/mac-state/app-store/support.html") {
                    Link(chinese ? "支持页面" : "Support", destination: supportPageURL)
                }
            }
            if let supportURL = URL(string: "mailto:hymghost@gmail.com") {
                Link("hymghost@gmail.com", destination: supportURL)
            }
            Button(chinese ? "完成" : "Done") { presentationMode.wrappedValue.dismiss() }
        }
        .padding()
        .frame(width: 520, height: 430)
    }
}
