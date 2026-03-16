import Foundation
import MacStateFoundation

public enum ThermalCondition: String, CaseIterable, Sendable, Codable {
    case nominal
    case fair
    case serious
    case critical

    public init(processInfoThermalState: ProcessInfo.ThermalState) {
        switch processInfoThermalState {
        case .nominal:
            self = .nominal
        case .fair:
            self = .fair
        case .serious:
            self = .serious
        case .critical:
            self = .critical
        @unknown default:
            self = .fair
        }
    }

    public func localizedTitle(language: AppLanguage) -> String {
        switch (language.resolvedLanguage, self) {
        case (.system, .nominal):
            return "Nominal"
        case (.system, .fair):
            return "Fair"
        case (.system, .serious):
            return "Serious"
        case (.system, .critical):
            return "Critical"
        case (.simplifiedChinese, .nominal):
            return "正常"
        case (.simplifiedChinese, .fair):
            return "偏高"
        case (.simplifiedChinese, .serious):
            return "严重"
        case (.simplifiedChinese, .critical):
            return "临界"
        case (.english, .nominal):
            return "Nominal"
        case (.english, .fair):
            return "Fair"
        case (.english, .serious):
            return "Serious"
        case (.english, .critical):
            return "Critical"
        }
    }

    public func localizedDetailText(language: AppLanguage) -> String {
        switch (language.resolvedLanguage, self) {
        case (.system, .nominal):
            return "Thermal pressure is within the normal operating range."
        case (.system, .fair):
            return "Thermal pressure is elevated but the system is still within a manageable range."
        case (.system, .serious):
            return "Thermal pressure is high and macOS may begin reducing performance."
        case (.system, .critical):
            return "Thermal pressure is critical and aggressive throttling may already be active."
        case (.simplifiedChinese, .nominal):
            return "热压力处于正常工作范围。"
        case (.simplifiedChinese, .fair):
            return "热压力有所升高，但系统仍处于可控范围。"
        case (.simplifiedChinese, .serious):
            return "热压力较高，macOS 可能开始降低性能。"
        case (.simplifiedChinese, .critical):
            return "热压力已到临界，系统可能已经开始明显降频。"
        case (.english, .nominal):
            return "Thermal pressure is within the normal operating range."
        case (.english, .fair):
            return "Thermal pressure is elevated but the system is still within a manageable range."
        case (.english, .serious):
            return "Thermal pressure is high and macOS may begin reducing performance."
        case (.english, .critical):
            return "Thermal pressure is critical and aggressive throttling may already be active."
        }
    }
}

public enum SensorSource: String, Sendable, Equatable, Codable {
    case collecting
    case placeholder
    case smcBridge
    case thermalAndBatteryOnlyAppleSilicon
    case thermalAndBatteryOnlyIntel
    case thermalOnlyAppleSilicon
    case thermalOnlyIntel

    public func localizedDescription(language: AppLanguage) -> String {
        switch (language.resolvedLanguage, self) {
        case (.system, .collecting):
            return "Collecting sensor telemetry."
        case (.system, .placeholder):
            return "Placeholder sensor telemetry."
        case (.system, .smcBridge):
            return "SMC bridge with live hardware telemetry."
        case (.system, .thermalAndBatteryOnlyAppleSilicon):
            return "Thermal state and battery telemetry are available. CPU/GPU temperature and fan telemetry need a deeper sensor bridge on Apple Silicon."
        case (.system, .thermalAndBatteryOnlyIntel):
            return "Thermal state and battery telemetry are available. SMC temperature or fan keys are unavailable on this Mac."
        case (.system, .thermalOnlyAppleSilicon):
            return "Thermal state is available. CPU/GPU temperature and fan telemetry need a deeper sensor bridge on Apple Silicon."
        case (.system, .thermalOnlyIntel):
            return "Thermal state is available. SMC temperature and fan telemetry are unavailable on this Mac."
        case (.simplifiedChinese, .collecting):
            return "正在收集传感器数据。"
        case (.simplifiedChinese, .placeholder):
            return "占位传感器数据。"
        case (.simplifiedChinese, .smcBridge):
            return "通过 SMC bridge 读取实时硬件传感器数据。"
        case (.simplifiedChinese, .thermalAndBatteryOnlyAppleSilicon):
            return "当前可读取热状态和电池温度。Apple Silicon 上的 CPU/GPU 温度与风扇仍需更深层的传感器 bridge。"
        case (.simplifiedChinese, .thermalAndBatteryOnlyIntel):
            return "当前可读取热状态和电池温度，但这台 Intel Mac 上的 SMC 温度或风扇键不可用。"
        case (.simplifiedChinese, .thermalOnlyAppleSilicon):
            return "当前只可读取热状态。Apple Silicon 上的 CPU/GPU 温度与风扇仍需更深层的传感器 bridge。"
        case (.simplifiedChinese, .thermalOnlyIntel):
            return "当前只可读取热状态，这台 Intel Mac 上的 SMC 温度与风扇数据不可用。"
        case (.english, .collecting):
            return "Collecting sensor telemetry."
        case (.english, .placeholder):
            return "Placeholder sensor telemetry."
        case (.english, .smcBridge):
            return "SMC bridge with live hardware telemetry."
        case (.english, .thermalAndBatteryOnlyAppleSilicon):
            return "Thermal state and battery telemetry are available. CPU/GPU temperature and fan telemetry need a deeper sensor bridge on Apple Silicon."
        case (.english, .thermalAndBatteryOnlyIntel):
            return "Thermal state and battery telemetry are available. SMC temperature or fan keys are unavailable on this Mac."
        case (.english, .thermalOnlyAppleSilicon):
            return "Thermal state is available. CPU/GPU temperature and fan telemetry need a deeper sensor bridge on Apple Silicon."
        case (.english, .thermalOnlyIntel):
            return "Thermal state is available. SMC temperature and fan telemetry are unavailable on this Mac."
        }
    }
}

public struct FanSnapshot: Sendable, Equatable, Identifiable, Codable {
    public let index: Int
    public let currentRPM: Int
    public let minimumRPM: Int?
    public let maximumRPM: Int?

    public init(
        index: Int,
        currentRPM: Int,
        minimumRPM: Int?,
        maximumRPM: Int?
    ) {
        self.index = index
        self.currentRPM = currentRPM
        self.minimumRPM = minimumRPM
        self.maximumRPM = maximumRPM
    }

    public var id: Int {
        index
    }
}

public struct SensorSnapshot: Sendable, Equatable, Codable {
    public let thermalCondition: ThermalCondition
    public let source: SensorSource
    public let cpuTemperatureCelsius: Double?
    public let gpuTemperatureCelsius: Double?
    public let batteryTemperatureCelsius: Double?
    public let fans: [FanSnapshot]

    public init(
        thermalCondition: ThermalCondition,
        source: SensorSource,
        cpuTemperatureCelsius: Double?,
        gpuTemperatureCelsius: Double?,
        batteryTemperatureCelsius: Double?,
        fans: [FanSnapshot]
    ) {
        self.thermalCondition = thermalCondition
        self.source = source
        self.cpuTemperatureCelsius = cpuTemperatureCelsius
        self.gpuTemperatureCelsius = gpuTemperatureCelsius
        self.batteryTemperatureCelsius = batteryTemperatureCelsius
        self.fans = fans
    }

    public var hasTemperatureTelemetry: Bool {
        cpuTemperatureCelsius != nil
            || gpuTemperatureCelsius != nil
            || batteryTemperatureCelsius != nil
    }

    public var hasFanTelemetry: Bool {
        fans.isEmpty == false
    }
}
