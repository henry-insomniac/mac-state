import SwiftUI
import MacStateUI

struct NotchMetricRow: View {
    let title: String
    let value: String
    let samples: [Double]
    let tint: Color

    var body: some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            if !samples.isEmpty {
                TrendStrip(values: samples, tint: tint)
                    .frame(width: 80)
                    .accessibilityHidden(true)
            }
            Text(value)
                .font(.system(.body, design: .monospaced))
                .bold()
                .frame(minWidth: 105, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
