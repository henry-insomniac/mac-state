import AppKit
import Darwin
import Foundation
import IOKit.ps
import MacStateFoundation

public enum MetricsSamplingError: Error {
    case cpuCountersUnavailable(code: Int32)
    case memoryCountersUnavailable(code: Int32)
    case networkCountersUnavailable(code: Int32)
    case diskCountersUnavailable
}

struct CPULoadCounters: Equatable {
    let user: UInt32
    let nice: UInt32
    let system: UInt32
    let idle: UInt32

    func usage(since previous: CPULoadCounters?) -> Double {
        guard let previous else {
            return 0
        }

        let userDelta = UInt64(user) &- UInt64(previous.user)
        let niceDelta = UInt64(nice) &- UInt64(previous.nice)
        let systemDelta = UInt64(system) &- UInt64(previous.system)
        let idleDelta = UInt64(idle) &- UInt64(previous.idle)

        let inUse = userDelta + niceDelta + systemDelta
        let total = inUse + idleDelta

        guard total > 0 else {
            return 0
        }

        return min(max(Double(inUse) / Double(total), 0), 1)
    }

    func adding(_ other: CPULoadCounters) -> CPULoadCounters {
        CPULoadCounters(
            user: user &+ other.user,
            nice: nice &+ other.nice,
            system: system &+ other.system,
            idle: idle &+ other.idle
        )
    }
}

struct MemoryCounters: Equatable {
    let usedBytes: UInt64
    let totalBytes: UInt64

    var usage: Double {
        guard totalBytes > 0 else {
            return 0
        }

        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }
}

struct NetworkCounters: Equatable {
    let timestamp: Date
    let receivedBytes: UInt64
    let sentBytes: UInt64
    let activeInterfaces: Int

    func rates(since previous: NetworkCounters?) -> (download: UInt64, upload: UInt64) {
        guard let previous else {
            return (0, 0)
        }

        let interval = timestamp.timeIntervalSince(previous.timestamp)
        guard interval > 0 else {
            return (0, 0)
        }

        let receivedDelta = receivedBytes >= previous.receivedBytes ? receivedBytes - previous.receivedBytes : 0
        let sentDelta = sentBytes >= previous.sentBytes ? sentBytes - previous.sentBytes : 0

        let downloadRate = UInt64((Double(receivedDelta) / interval).rounded())
        let uploadRate = UInt64((Double(sentDelta) / interval).rounded())

        return (downloadRate, uploadRate)
    }
}

struct DiskIOCounters: Equatable {
    let timestamp: Date
    let readBytes: UInt64
    let writeBytes: UInt64

    func rates(since previous: DiskIOCounters?) -> (read: UInt64, write: UInt64) {
        guard let previous else {
            return (0, 0)
        }

        let interval = timestamp.timeIntervalSince(previous.timestamp)
        guard interval > 0 else {
            return (0, 0)
        }

        let readDelta = readBytes >= previous.readBytes ? readBytes - previous.readBytes : 0
        let writeDelta = writeBytes >= previous.writeBytes ? writeBytes - previous.writeBytes : 0

        let readRate = UInt64((Double(readDelta) / interval).rounded())
        let writeRate = UInt64((Double(writeDelta) / interval).rounded())

        return (readRate, writeRate)
    }
}

public actor LiveMetricsProvider: MetricsSnapshotProviding {
    private var previousCoreLoads: [CPULoadCounters] = []
    private var previousNetworkCounters: NetworkCounters?
    private var previousDiskIOCounters: DiskIOCounters?
    private let sensorBridge = SensorBridge()

    public init() {}

    public func snapshot() async throws -> MetricSnapshot {
        let timestamp = Date()
        let platform = PlatformCapabilities.current
        let currentCoreLoads = try Self.readCoreLoadCounters()
        let memoryCounters = try Self.readMemoryCounters()
        let diskSpaceCounters = try Self.readDiskSpaceCounters()
        let currentDiskIOCounters = try Self.readDiskIOCounters(at: timestamp)
        let currentNetworkCounters = try Self.readNetworkCounters(at: timestamp)
        let battery = Self.readBatterySnapshot()
        let sensors = sensorBridge.snapshot(platform: platform)
        let processes = Self.readProcessSnapshots()

        let cpuCores = Self.makeCPUCoreSnapshots(
            from: currentCoreLoads,
            previous: previousCoreLoads
        )
        let cpuUsage = (Self.makeAggregateCPULoad(from: currentCoreLoads) ?? CPULoadCounters(
            user: 0,
            nice: 0,
            system: 0,
            idle: 0
        )).usage(since: Self.makeAggregateCPULoad(from: previousCoreLoads))
        let diskRates = currentDiskIOCounters.rates(since: previousDiskIOCounters)
        let networkRates = currentNetworkCounters.rates(since: previousNetworkCounters)

        previousCoreLoads = currentCoreLoads
        previousDiskIOCounters = currentDiskIOCounters
        previousNetworkCounters = currentNetworkCounters

        return MetricSnapshot(
            timestamp: timestamp,
            cpuUsage: cpuUsage,
            cpuCores: cpuCores,
            memoryUsage: memoryCounters.usage,
            memoryUsedBytes: memoryCounters.usedBytes,
            memoryTotalBytes: memoryCounters.totalBytes,
            disk: DiskSnapshot(
                usedBytes: diskSpaceCounters.usedBytes,
                freeBytes: diskSpaceCounters.freeBytes,
                totalBytes: diskSpaceCounters.totalBytes,
                readBytesPerSecond: diskRates.read,
                writeBytesPerSecond: diskRates.write
            ),
            networkDownloadBytesPerSecond: networkRates.download,
            networkUploadBytesPerSecond: networkRates.upload,
            activeNetworkInterfaces: currentNetworkCounters.activeInterfaces,
            battery: battery,
            sensors: sensors,
            processes: processes,
            platform: platform
        )
    }
}

extension LiveMetricsProvider {
    static func makeMemoryCounters(
        from stats: vm_statistics64,
        pageSizeBytes: UInt64,
        totalBytes: UInt64
    ) -> MemoryCounters {
        // macOS keeps file-backed cache warm and will reclaim it under pressure,
        // so treating only "free" pages as available pushes usage toward 100%
        // even when the system remains responsive.
        let usedPageCount = UInt64(stats.internal_page_count)
            + UInt64(stats.wire_count)
            + UInt64(stats.throttled_count)
        let usedBytes = min(usedPageCount * pageSizeBytes, totalBytes)

        return MemoryCounters(
            usedBytes: usedBytes,
            totalBytes: totalBytes
        )
    }
}

private extension LiveMetricsProvider {
    static func readCoreLoadCounters() throws -> [CPULoadCounters] {
        var processorCount: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let status = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &infoArray,
            &infoCount
        )

        guard status == KERN_SUCCESS,
              let infoArray else {
            throw MetricsSamplingError.cpuCountersUnavailable(code: status)
        }

        defer {
            let byteCount = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: infoArray),
                byteCount
            )
        }

        let coreCount = Int(processorCount)
        let stride = Int(CPU_STATE_MAX)
        var counters: [CPULoadCounters] = []
        counters.reserveCapacity(coreCount)

        for index in 0..<coreCount {
            let offset = index * stride
            counters.append(
                CPULoadCounters(
                    user: UInt32(infoArray[offset + Int(CPU_STATE_USER)]),
                    nice: UInt32(infoArray[offset + Int(CPU_STATE_NICE)]),
                    system: UInt32(infoArray[offset + Int(CPU_STATE_SYSTEM)]),
                    idle: UInt32(infoArray[offset + Int(CPU_STATE_IDLE)])
                )
            )
        }

        return counters
    }

    static func makeAggregateCPULoad(from coreLoads: [CPULoadCounters]) -> CPULoadCounters? {
        guard coreLoads.isEmpty == false else {
            return nil
        }

        return coreLoads.reduce(
            CPULoadCounters(user: 0, nice: 0, system: 0, idle: 0)
        ) { partialResult, load in
            partialResult.adding(load)
        }
    }

    static func makeCPUCoreSnapshots(
        from current: [CPULoadCounters],
        previous: [CPULoadCounters]
    ) -> [CPUCoreSnapshot] {
        current.enumerated().map { index, load in
            let previousLoad = previous.indices.contains(index) ? previous[index] : nil

            return CPUCoreSnapshot(
                index: index,
                usage: load.usage(since: previousLoad)
            )
        }
    }

    static func readDiskSpaceCounters() throws -> (usedBytes: UInt64, freeBytes: UInt64, totalBytes: UInt64) {
        let fileSystemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())

        guard let totalBytesNumber = fileSystemAttributes[.systemSize] as? NSNumber,
              let freeBytesNumber = fileSystemAttributes[.systemFreeSize] as? NSNumber else {
            throw MetricsSamplingError.diskCountersUnavailable
        }

        let totalBytes = totalBytesNumber.uint64Value
        let freeBytes = freeBytesNumber.uint64Value
        let usedBytes = totalBytes > freeBytes ? totalBytes - freeBytes : 0

        return (
            usedBytes: usedBytes,
            freeBytes: freeBytes,
            totalBytes: totalBytes
        )
    }

    static func readDiskIOCounters(at timestamp: Date) throws -> DiskIOCounters {
        let processCount = proc_listallpids(nil, 0)
        guard processCount >= 0 else {
            throw MetricsSamplingError.diskCountersUnavailable
        }

        let byteCount = max(Int(processCount), 1) * MemoryLayout<pid_t>.stride
        let rawBuffer = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: MemoryLayout<pid_t>.alignment
        )

        defer {
            rawBuffer.deallocate()
        }

        let listedProcessCount = proc_listallpids(rawBuffer, Int32(byteCount))
        guard listedProcessCount >= 0 else {
            throw MetricsSamplingError.diskCountersUnavailable
        }

        let pids = rawBuffer.assumingMemoryBound(to: pid_t.self)
        var totalReadBytes: UInt64 = 0
        var totalWriteBytes: UInt64 = 0

        for index in 0..<Int(listedProcessCount) {
            let pid = pids[index]
            guard pid > 0 else {
                continue
            }

            var usageInfo = rusage_info_v4()
            let result = withUnsafeMutablePointer(to: &usageInfo) { pointer in
                proc_pid_rusage(
                    pid,
                    RUSAGE_INFO_V4,
                    UnsafeMutableRawPointer(pointer).assumingMemoryBound(
                        to: Optional<UnsafeMutableRawPointer>.self
                    )
                )
            }

            guard result == 0 else {
                continue
            }

            totalReadBytes &+= usageInfo.ri_diskio_bytesread
            totalWriteBytes &+= usageInfo.ri_diskio_byteswritten
        }

        return DiskIOCounters(
            timestamp: timestamp,
            readBytes: totalReadBytes,
            writeBytes: totalWriteBytes
        )
    }

    static func readMemoryCounters() throws -> MemoryCounters {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let status = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    reboundPointer,
                    &count
                )
            }
        }

        guard status == KERN_SUCCESS else {
            throw MetricsSamplingError.memoryCountersUnavailable(code: status)
        }

        var pageSize: vm_size_t = 0
        let pageSizeStatus = host_page_size(mach_host_self(), &pageSize)

        guard pageSizeStatus == KERN_SUCCESS else {
            throw MetricsSamplingError.memoryCountersUnavailable(code: pageSizeStatus)
        }

        let totalBytes = ProcessInfo.processInfo.physicalMemory
        return makeMemoryCounters(
            from: stats,
            pageSizeBytes: UInt64(pageSize),
            totalBytes: totalBytes
        )
    }

    static func readNetworkCounters(at timestamp: Date) throws -> NetworkCounters {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0 else {
            throw MetricsSamplingError.networkCountersUnavailable(code: errno)
        }

        defer {
            freeifaddrs(interfaces)
        }

        var activeInterfaceNames = Set<String>()
        var totalReceivedBytes: UInt64 = 0
        var totalSentBytes: UInt64 = 0
        var cursor = interfaces

        while let current = cursor {
            let interface = current.pointee
            defer {
                cursor = interface.ifa_next
            }

            guard let address = interface.ifa_addr else {
                continue
            }

            guard Int32(address.pointee.sa_family) == AF_LINK else {
                continue
            }

            let flags = Int32(interface.ifa_flags)
            guard (flags & IFF_UP) != 0 else {
                continue
            }

            guard (flags & IFF_LOOPBACK) == 0 else {
                continue
            }

            guard let rawData = interface.ifa_data else {
                continue
            }

            let interfaceData = rawData.assumingMemoryBound(to: if_data.self).pointee
            totalReceivedBytes += UInt64(interfaceData.ifi_ibytes)
            totalSentBytes += UInt64(interfaceData.ifi_obytes)
            activeInterfaceNames.insert(String(cString: interface.ifa_name))
        }

        return NetworkCounters(
            timestamp: timestamp,
            receivedBytes: totalReceivedBytes,
            sentBytes: totalSentBytes,
            activeInterfaces: activeInterfaceNames.count
        )
    }

    static func readBatterySnapshot() -> BatterySnapshot? {
        guard let powerSourcesInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return nil
        }

        let powerSources = IOPSCopyPowerSourcesList(powerSourcesInfo).takeRetainedValue() as NSArray

        guard let firstPowerSource = powerSources.firstObject,
              let description = IOPSGetPowerSourceDescription(
                powerSourcesInfo,
                firstPowerSource as CFTypeRef
              )?.takeUnretainedValue() as NSDictionary? else {
            return nil
        }

        let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 0
        let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
        let powerSourceState = description[kIOPSPowerSourceStateKey] as? String ?? ""
        let isOnBatteryPower = powerSourceState == kIOPSBatteryPowerValue

        let timeRemainingMinutes: Int?
        if isCharging {
            timeRemainingMinutes = description[kIOPSTimeToFullChargeKey] as? Int
        } else if isOnBatteryPower {
            timeRemainingMinutes = description[kIOPSTimeToEmptyKey] as? Int
        } else {
            timeRemainingMinutes = nil
        }

        return BatterySnapshot(
            currentCapacity: currentCapacity,
            maxCapacity: maxCapacity,
            isCharging: isCharging,
            isOnBatteryPower: isOnBatteryPower,
            timeRemainingMinutes: timeRemainingMinutes
        )
    }

    static func readProcessSnapshots() -> [ProcessSnapshot] {
        let applications = NSWorkspace.shared.runningApplications

        return applications
            .filter { application in
                application.activationPolicy != .prohibited && application.processIdentifier > 0
            }
            .map { application in
                ProcessSnapshot(
                    pid: application.processIdentifier,
                    name: application.localizedName ?? "PID \(application.processIdentifier)",
                    isFrontmost: application.isActive
                )
            }
            .sorted { left, right in
                if left.isFrontmost != right.isFrontmost {
                    return left.isFrontmost && !right.isFrontmost
                }

                return left.name.localizedStandardCompare(right.name) == .orderedAscending
            }
            .prefix(5)
            .map { $0 }
    }
}
