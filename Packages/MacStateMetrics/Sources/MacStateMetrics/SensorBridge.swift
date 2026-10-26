import Foundation
import MacStateFoundation

struct SensorBridge {
    func snapshot(platform: PlatformCapabilities) -> SensorSnapshot {
        SensorSnapshot(
            thermalCondition: ThermalCondition(processInfoThermalState: ProcessInfo.processInfo.thermalState),
            source: .publicThermalState,
            cpuTemperatureCelsius: nil,
            gpuTemperatureCelsius: nil,
            batteryTemperatureCelsius: nil,
            fans: []
        )
    }
}
