import Foundation

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

    public var title: String {
        switch self {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        }
    }

    public var detailText: String {
        switch self {
        case .nominal:
            return "Thermal pressure is within the normal operating range."
        case .fair:
            return "Thermal pressure is elevated but the system is still within a manageable range."
        case .serious:
            return "Thermal pressure is high and macOS may begin reducing performance."
        case .critical:
            return "Thermal pressure is critical and aggressive throttling may already be active."
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
    public let sourceDescription: String
    public let cpuTemperatureCelsius: Double?
    public let gpuTemperatureCelsius: Double?
    public let batteryTemperatureCelsius: Double?
    public let fans: [FanSnapshot]

    public init(
        thermalCondition: ThermalCondition,
        sourceDescription: String,
        cpuTemperatureCelsius: Double?,
        gpuTemperatureCelsius: Double?,
        batteryTemperatureCelsius: Double?,
        fans: [FanSnapshot]
    ) {
        self.thermalCondition = thermalCondition
        self.sourceDescription = sourceDescription
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
