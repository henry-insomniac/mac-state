import SwiftUI
import WidgetKit

/// Modern widgets let the system manage their background and content margins.
struct WidgetSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        if #available(macOS 14.0, *) {
            content.containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.12, blue: 0.19), Color(red: 0.15, green: 0.18, blue: 0.24)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.08, green: 0.12, blue: 0.19), Color(red: 0.15, green: 0.18, blue: 0.24)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                content.padding(16)
            }
        }
    }
}
