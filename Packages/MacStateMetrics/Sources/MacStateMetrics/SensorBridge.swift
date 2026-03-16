import Foundation
import IOKit
import MacStateFoundation

struct SensorBridge {
    func snapshot(platform: PlatformCapabilities) -> SensorSnapshot {
        let thermalCondition = ThermalCondition(
            processInfoThermalState: ProcessInfo.processInfo.thermalState
        )
        let batteryTemperatureCelsius = Self.readBatteryTemperatureCelsius()

        if let lowLevelSnapshot = readLowLevelSensorSnapshot(
            platform: platform,
            thermalCondition: thermalCondition,
            batteryTemperatureCelsius: batteryTemperatureCelsius
        ) {
            return lowLevelSnapshot
        }

        return SensorSnapshot(
            thermalCondition: thermalCondition,
            sourceDescription: fallbackSourceDescription(
                for: platform,
                batteryTemperatureCelsius: batteryTemperatureCelsius
            ),
            cpuTemperatureCelsius: nil,
            gpuTemperatureCelsius: nil,
            batteryTemperatureCelsius: batteryTemperatureCelsius,
            fans: []
        )
    }

    private func readLowLevelSensorSnapshot(
        platform: PlatformCapabilities,
        thermalCondition: ThermalCondition,
        batteryTemperatureCelsius: Double?
    ) -> SensorSnapshot? {
        guard let smcBridge = SMCBridge.open(
            serviceNameCandidates: serviceNameCandidates(for: platform)
        ) else {
            return nil
        }

        let cpuTemperatureCelsius = smcBridge.firstTemperature(
            forKeys: [
                "TC0P",
                "TC0E",
                "TC0F",
                "TC1C",
                "TC1P",
                "TC2P",
            ]
        )
        let gpuTemperatureCelsius = smcBridge.firstTemperature(
            forKeys: [
                "TG0P",
                "TG0D",
                "TG1D",
            ]
        )
        let fans = smcBridge.fanSnapshots()

        guard cpuTemperatureCelsius != nil
                || gpuTemperatureCelsius != nil
                || fans.isEmpty == false else {
            return nil
        }

        return SensorSnapshot(
            thermalCondition: thermalCondition,
            sourceDescription: "SMC bridge with live hardware telemetry.",
            cpuTemperatureCelsius: cpuTemperatureCelsius,
            gpuTemperatureCelsius: gpuTemperatureCelsius,
            batteryTemperatureCelsius: batteryTemperatureCelsius,
            fans: fans
        )
    }

    private func serviceNameCandidates(
        for platform: PlatformCapabilities
    ) -> [String] {
        switch platform.architecture {
        case .appleSilicon:
            [
                "AppleSMCKeysEndpoint",
                "AppleSMC",
            ]
        case .intel:
            [
                "AppleSMC",
                "AppleSMCKeysEndpoint",
            ]
        }
    }

    private func fallbackSourceDescription(
        for platform: PlatformCapabilities,
        batteryTemperatureCelsius: Double?
    ) -> String {
        if batteryTemperatureCelsius != nil {
            switch platform.architecture {
            case .appleSilicon:
                return "Thermal state and battery telemetry are available. CPU/GPU temperature and fan telemetry need a deeper sensor bridge on Apple Silicon."
            case .intel:
                return "Thermal state and battery telemetry are available. SMC temperature or fan keys are unavailable on this Mac."
            }
        }

        switch platform.architecture {
        case .appleSilicon:
            return "Thermal state is available. CPU/GPU temperature and fan telemetry need a deeper sensor bridge on Apple Silicon."
        case .intel:
            return "Thermal state is available. SMC temperature and fan telemetry are unavailable on this Mac."
        }
    }

    private static func readBatteryTemperatureCelsius() -> Double? {
        let service = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )

        guard service != IO_OBJECT_NULL else {
            return nil
        }

        defer {
            IOObjectRelease(service)
        }

        guard let rawTemperature = registryIntegerProperty(
            service: service,
            key: "Temperature"
        ), rawTemperature > 0 else {
            return nil
        }

        let celsius = (Double(rawTemperature) / 10) - 273.15
        return celsius.isFinite ? max(celsius, 0) : nil
    }

    private static func registryIntegerProperty(
        service: io_service_t,
        key: String
    ) -> Int? {
        guard let value = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else {
            return nil
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        return nil
    }
}

private final class SMCBridge {
    private enum Selector {
        static let readKey = UInt32(2)
    }

    private enum Command {
        static let readBytes = UInt8(5)
        static let readKeyInfo = UInt8(9)
    }

    private let connection: io_connect_t

    private init(connection: io_connect_t) {
        self.connection = connection
    }

    deinit {
        IOServiceClose(connection)
    }

    static func open(serviceNameCandidates: [String]) -> SMCBridge? {
        for serviceName in serviceNameCandidates {
            let service = IOServiceGetMatchingService(
                kIOMasterPortDefault,
                IOServiceMatching(serviceName)
            )

            guard service != IO_OBJECT_NULL else {
                continue
            }

            var connection: io_connect_t = 0
            let status = IOServiceOpen(service, mach_task_self_, 0, &connection)
            IOObjectRelease(service)

            guard status == KERN_SUCCESS else {
                continue
            }

            return SMCBridge(connection: connection)
        }

        return nil
    }

    func firstTemperature(forKeys keys: [String]) -> Double? {
        for key in keys {
            if let value = readDoubleValue(forKey: key) {
                return value
            }
        }

        return nil
    }

    func fanSnapshots() -> [FanSnapshot] {
        guard let fanCountValue = readUnsignedIntegerValue(forKey: "FNum") else {
            return []
        }

        let fanCount = max(Int(fanCountValue), 0)
        guard fanCount > 0 else {
            return []
        }

        return (0..<fanCount).compactMap { index in
            let currentRPM = readDoubleValue(forKey: "F\(index)Ac")

            guard let currentRPM else {
                return nil
            }

            return FanSnapshot(
                index: index,
                currentRPM: Int(currentRPM.rounded()),
                minimumRPM: readDoubleValue(forKey: "F\(index)Mn").map { Int($0.rounded()) },
                maximumRPM: readDoubleValue(forKey: "F\(index)Mx").map { Int($0.rounded()) }
            )
        }
    }

    private func readUnsignedIntegerValue(forKey key: String) -> UInt64? {
        guard let value = readValue(forKey: key) else {
            return nil
        }

        let type = value.dataType.trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {
        case "ui8":
            guard let firstByte = value.bytes.first else {
                return nil
            }

            return UInt64(firstByte)
        case "ui16":
            guard value.bytes.count >= 2 else {
                return nil
            }

            return UInt64(UInt16(value.bytes[0]) << 8 | UInt16(value.bytes[1]))
        default:
            return nil
        }
    }

    private func readDoubleValue(forKey key: String) -> Double? {
        guard let value = readValue(forKey: key) else {
            return nil
        }

        let type = value.dataType.trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {
        case "sp78":
            guard value.bytes.count >= 2 else {
                return nil
            }

            let rawValue = Int16(bitPattern: UInt16(value.bytes[0]) << 8 | UInt16(value.bytes[1]))
            return Double(rawValue) / 256
        case "fpe2":
            guard value.bytes.count >= 2 else {
                return nil
            }

            let rawValue = UInt16(value.bytes[0]) << 8 | UInt16(value.bytes[1])
            return Double(rawValue) / 4
        case "flt":
            guard value.bytes.count >= 4 else {
                return nil
            }

            let rawValue = UInt32(value.bytes[0]) << 24
                | UInt32(value.bytes[1]) << 16
                | UInt32(value.bytes[2]) << 8
                | UInt32(value.bytes[3])
            return Double(Float(bitPattern: rawValue))
        case "ui8":
            return value.bytes.first.map(Double.init)
        case "ui16":
            guard value.bytes.count >= 2 else {
                return nil
            }

            let rawValue = UInt16(value.bytes[0]) << 8 | UInt16(value.bytes[1])
            return Double(rawValue)
        default:
            return nil
        }
    }

    private func readValue(forKey key: String) -> SMCValue? {
        guard key.count == 4 else {
            return nil
        }

        var input = SMCKeyData()
        input.key = Self.fourCharCode(from: key)
        input.data8 = Command.readKeyInfo

        var output = SMCKeyData()
        guard call(input: &input, output: &output) == KERN_SUCCESS else {
            return nil
        }

        input.keyInfo = output.keyInfo
        input.data8 = Command.readBytes

        guard call(input: &input, output: &output) == KERN_SUCCESS else {
            return nil
        }

        let byteCount = min(Int(output.keyInfo.dataSize), 32)
        let dataType = Self.string(from: output.keyInfo.dataType)
        let bytes = withUnsafeBytes(of: output.bytes) { rawBuffer in
            Array(rawBuffer.prefix(byteCount))
        }

        return SMCValue(dataType: dataType, bytes: bytes)
    }

    private func call(
        input: inout SMCKeyData,
        output: inout SMCKeyData
    ) -> kern_return_t {
        var outputSize = MemoryLayout<SMCKeyData>.stride

        return withUnsafePointer(to: &input) { inputPointer in
            withUnsafeMutablePointer(to: &output) { outputPointer in
                IOConnectCallStructMethod(
                    connection,
                    Selector.readKey,
                    inputPointer,
                    MemoryLayout<SMCKeyData>.stride,
                    outputPointer,
                    &outputSize
                )
            }
        }
    }

    private static func fourCharCode(from string: String) -> UInt32 {
        string.utf8.reduce(0) { partialResult, character in
            (partialResult << 8) | UInt32(character)
        }
    }

    private static func string(from value: UInt32) -> String {
        let characters: [UInt8] = [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF),
        ]

        return String(bytes: characters, encoding: .utf8) ?? ""
    }
}

private struct SMCValue {
    let dataType: String
    let bytes: [UInt8]
}

private typealias SMCByteTuple = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
)

private struct SMCVersion {
    var major = UInt8(0)
    var minor = UInt8(0)
    var build = UInt8(0)
    var reserved = UInt8(0)
    var release = UInt16(0)
}

private struct SMCLimitData {
    var version = UInt16(0)
    var length = UInt16(0)
    var cpuPLimit = UInt32(0)
    var gpuPLimit = UInt32(0)
    var memoryPLimit = UInt32(0)
}

private struct SMCKeyInfo {
    var dataSize = UInt32(0)
    var dataType = UInt32(0)
    var dataAttributes = UInt8(0)
}

private struct SMCKeyData {
    var key = UInt32(0)
    var version = SMCVersion()
    var limitData = SMCLimitData()
    var keyInfo = SMCKeyInfo()
    var result = UInt8(0)
    var status = UInt8(0)
    var data8 = UInt8(0)
    var data32 = UInt32(0)
    var bytes: SMCByteTuple = (
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
    )
}
