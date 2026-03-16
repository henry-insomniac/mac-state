import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var compactMenuBarText = true
    @Published var cpuUsage = 0.18
    @Published var memoryUsage = 0.42
    @Published var networkDownloadRate = 12.6
    @Published var networkUploadRate = 4.2
    @Published var lastUpdatedAt = Date()

    var menuBarTitle: String {
        guard compactMenuBarText else {
            return "mac-state"
        }

        return "mac-state \(percentageString(from: cpuUsage))"
    }

    var cpuUsageText: String {
        percentageString(from: cpuUsage)
    }

    var memoryUsageText: String {
        percentageString(from: memoryUsage)
    }

    var downloadRateText: String {
        "\(singleDecimalString(from: networkDownloadRate)) MB/s"
    }

    var uploadRateText: String {
        "\(singleDecimalString(from: networkUploadRate)) MB/s"
    }

    var lastUpdatedText: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: lastUpdatedAt)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return "\(twoDigitString(hour)):\(twoDigitString(minute))"
    }

    func refreshPreviewData() {
        let nextCPU = min(cpuUsage + 0.07, 0.91)
        let nextMemory = min(memoryUsage + 0.04, 0.87)
        let nextDownload = min(networkDownloadRate + 3.2, 42.0)
        let nextUpload = min(networkUploadRate + 1.4, 18.0)

        cpuUsage = nextCPU == cpuUsage ? 0.18 : nextCPU
        memoryUsage = nextMemory == memoryUsage ? 0.42 : nextMemory
        networkDownloadRate = nextDownload == networkDownloadRate ? 12.6 : nextDownload
        networkUploadRate = nextUpload == networkUploadRate ? 4.2 : nextUpload
        lastUpdatedAt = Date()
    }

    private func percentageString(from value: Double) -> String {
        let percentage = Int((value * 100).rounded())
        return "\(percentage)%"
    }

    private func singleDecimalString(from value: Double) -> String {
        let roundedValue = (value * 10).rounded() / 10
        let wholePart = Int(roundedValue)
        let decimalPart = Int(abs((roundedValue - Double(wholePart)) * 10).rounded())

        return "\(wholePart).\(decimalPart)"
    }

    private func twoDigitString(_ value: Int) -> String {
        if value < 10 {
            return "0\(value)"
        }

        return "\(value)"
    }
}
