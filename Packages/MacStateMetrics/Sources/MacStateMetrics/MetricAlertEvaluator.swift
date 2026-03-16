import Foundation
import MacStateFoundation

public enum MetricAlertEvaluator {
    public static func alerts(
        for snapshot: MetricSnapshot,
        configuration: MetricAlertConfiguration,
        language: AppLanguage = .system
    ) -> [MetricAlert] {
        var alerts: [MetricAlert] = []
        let resolvedLanguage = language.resolvedLanguage

        if configuration.cpuHighUsage.isEnabled,
           snapshot.cpuUsage >= configuration.cpuHighUsage.thresholdValue {
            alerts.append(
                MetricAlert(
                    type: .cpuHighUsage,
                    title: resolvedLanguage == .simplifiedChinese ? "CPU 使用率过高" : "CPU usage is high",
                    body: resolvedLanguage == .simplifiedChinese
                        ? "CPU 负载已达到 \(percentageString(from: snapshot.cpuUsage))。"
                        : "CPU load reached \(percentageString(from: snapshot.cpuUsage))."
                )
            )
        }

        if configuration.memoryHighUsage.isEnabled,
           snapshot.memoryUsage >= configuration.memoryHighUsage.thresholdValue {
            alerts.append(
                MetricAlert(
                    type: .memoryHighUsage,
                    title: resolvedLanguage == .simplifiedChinese ? "内存压力过高" : "Memory pressure is high",
                    body: resolvedLanguage == .simplifiedChinese
                        ? "内存使用率已达到 \(percentageString(from: snapshot.memoryUsage))。"
                        : "Memory usage reached \(percentageString(from: snapshot.memoryUsage))."
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
                    title: resolvedLanguage == .simplifiedChinese ? "电池电量过低" : "Battery is running low",
                    body: resolvedLanguage == .simplifiedChinese
                        ? "电池电量已下降到 \(percentageString(from: battery.level))。"
                        : "Battery level dropped to \(percentageString(from: battery.level))."
                )
            )
        }

        let diskThroughput = snapshot.disk.readBytesPerSecond + snapshot.disk.writeBytesPerSecond
        if configuration.diskActivityHigh.isEnabled,
           diskThroughput >= configuration.diskActivityHigh.thresholdBytesPerSecond {
            alerts.append(
                MetricAlert(
                    type: .diskActivityHigh,
                    title: resolvedLanguage == .simplifiedChinese ? "磁盘活动过高" : "Disk activity is high",
                    body: resolvedLanguage == .simplifiedChinese
                        ? "磁盘吞吐已达到 \(megabytesPerSecondString(from: diskThroughput))。"
                        : "Disk throughput reached \(megabytesPerSecondString(from: diskThroughput))."
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
