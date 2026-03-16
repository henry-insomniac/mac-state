import Darwin
import Foundation
import MacStateFoundation

public enum MetricsSamplingError: Error {
    case cpuCountersUnavailable(code: Int32)
    case memoryCountersUnavailable(code: Int32)
    case networkCountersUnavailable(code: Int32)
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

public actor LiveMetricsProvider: MetricsSnapshotProviding {
    private var previousCPULoad: CPULoadCounters?
    private var previousNetworkCounters: NetworkCounters?

    public init() {}

    public func snapshot() async throws -> MetricSnapshot {
        let timestamp = Date()
        let currentCPULoad = try Self.readCPULoadCounters()
        let memoryCounters = try Self.readMemoryCounters()
        let currentNetworkCounters = try Self.readNetworkCounters(at: timestamp)

        let cpuUsage = currentCPULoad.usage(since: previousCPULoad)
        let networkRates = currentNetworkCounters.rates(since: previousNetworkCounters)

        previousCPULoad = currentCPULoad
        previousNetworkCounters = currentNetworkCounters

        return MetricSnapshot(
            timestamp: timestamp,
            cpuUsage: cpuUsage,
            memoryUsage: memoryCounters.usage,
            memoryUsedBytes: memoryCounters.usedBytes,
            memoryTotalBytes: memoryCounters.totalBytes,
            networkDownloadBytesPerSecond: networkRates.download,
            networkUploadBytesPerSecond: networkRates.upload,
            activeNetworkInterfaces: currentNetworkCounters.activeInterfaces,
            platform: .current
        )
    }
}

private extension LiveMetricsProvider {
    static func readCPULoadCounters() throws -> CPULoadCounters {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let status = withUnsafeMutablePointer(to: &load) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics(
                    mach_host_self(),
                    HOST_CPU_LOAD_INFO,
                    reboundPointer,
                    &count
                )
            }
        }

        guard status == KERN_SUCCESS else {
            throw MetricsSamplingError.cpuCountersUnavailable(code: status)
        }

        return CPULoadCounters(
            user: load.cpu_ticks.0,
            nice: load.cpu_ticks.1,
            system: load.cpu_ticks.2,
            idle: load.cpu_ticks.3
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

        let pageSizeBytes = UInt64(pageSize)
        let freeBytes = UInt64(stats.free_count + stats.speculative_count) * pageSizeBytes
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let usedBytes = totalBytes > freeBytes ? totalBytes - freeBytes : 0

        return MemoryCounters(
            usedBytes: usedBytes,
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
}
