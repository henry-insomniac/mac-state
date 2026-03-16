import Foundation

public enum MetricAlertEvaluator {
    public static func alerts(
        for snapshot: MetricSnapshot,
        configuration: MetricAlertConfiguration
    ) -> [MetricAlert] {
        var alerts: [MetricAlert] = []

        if configuration.cpuHighUsage.isEnabled,
           snapshot.cpuUsage >= configuration.cpuHighUsage.thresholdValue {
            alerts.append(
                MetricAlert(
                    type: .cpuHighUsage,
                    title: "CPU usage is high",
                    body: "CPU load reached \(percentageString(from: snapshot.cpuUsage))."
                )
            )
        }

        if configuration.memoryHighUsage.isEnabled,
           snapshot.memoryUsage >= configuration.memoryHighUsage.thresholdValue {
            alerts.append(
                MetricAlert(
                    type: .memoryHighUsage,
                    title: "Memory pressure is high",
                    body: "Memory usage reached \(percentageString(from: snapshot.memoryUsage))."
                )
            )
        }

        if configuration.batteryLowLevel.isEnabled,
           let battery = snapshot.battery,
           battery.isOnBatteryPower,
           battery.level <= configuration.batteryLowLevel.thresholdValue {
            alerts.append(
                MetricAlert(
                    type: .batteryLowLevel,
                    title: "Battery is running low",
                    body: "Battery level dropped to \(percentageString(from: battery.level))."
                )
            )
        }

        let diskThroughput = snapshot.disk.readBytesPerSecond + snapshot.disk.writeBytesPerSecond
        if configuration.diskActivityHigh.isEnabled,
           diskThroughput >= configuration.diskActivityHigh.thresholdBytesPerSecond {
            alerts.append(
                MetricAlert(
                    type: .diskActivityHigh,
                    title: "Disk activity is high",
                    body: "Disk throughput reached \(megabytesPerSecondString(from: diskThroughput))."
                )
            )
        }

        return alerts
    }

    private static func percentageString(from value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func megabytesPerSecondString(from bytesPerSecond: UInt64) -> String {
        let megabytesPerSecond = Double(bytesPerSecond) / 1_048_576
        let roundedValue = (megabytesPerSecond * 10).rounded() / 10
        let wholePart = Int(roundedValue.rounded(.towardZero))
        let decimalPart = Int(abs((roundedValue - Double(wholePart)) * 10).rounded())

        return "\(wholePart).\(decimalPart) MB/s"
    }
}
