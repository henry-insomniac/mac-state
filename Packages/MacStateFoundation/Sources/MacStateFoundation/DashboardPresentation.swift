import Foundation

public enum DashboardModuleType: String, CaseIterable, Codable, Sendable, Equatable, Hashable {
    case battery
    case network
    case cpu
    case cpuCores
    case memory
    case disk
    case sensors
    case alerts
    case trends
    case runningApps

    public var isCollapsible: Bool {
        switch self {
        case .cpuCores, .sensors, .alerts, .trends, .runningApps:
            true
        case .battery, .network, .cpu, .memory, .disk:
            false
        }
    }
}

public struct DashboardModuleConfiguration: Codable, Sendable, Equatable, Identifiable {
    public let type: DashboardModuleType
    public var isVisible: Bool
    public var isExpandedByDefault: Bool

    public var id: DashboardModuleType {
        type
    }

    public init(
        type: DashboardModuleType,
        isVisible: Bool,
        isExpandedByDefault: Bool = false
    ) {
        self.type = type
        self.isVisible = isVisible
        self.isExpandedByDefault = type.isCollapsible ? isExpandedByDefault : false
    }
}

public struct DashboardPresentation: Codable, Sendable, Equatable {
    public var modules: [DashboardModuleConfiguration]

    public init(modules: [DashboardModuleConfiguration]) {
        self.modules = Self.normalize(modules)
    }

    public static let `default` = DashboardPresentation(
        modules: DashboardModuleType.allCases.map { type in
            DashboardModuleConfiguration(
                type: type,
                isVisible: defaultVisibility(for: type),
                isExpandedByDefault: defaultExpandedState(for: type)
            )
        }
    )

    public var orderedModules: [DashboardModuleConfiguration] {
        Self.normalize(modules)
    }

    public func configuration(for type: DashboardModuleType) -> DashboardModuleConfiguration {
        orderedModules.first { $0.type == type }
            ?? DashboardModuleConfiguration(
                type: type,
                isVisible: Self.defaultVisibility(for: type),
                isExpandedByDefault: Self.defaultExpandedState(for: type)
            )
    }

    public static func normalize(
        _ modules: [DashboardModuleConfiguration]
    ) -> [DashboardModuleConfiguration] {
        var normalizedModules: [DashboardModuleConfiguration] = []
        var seenTypes = Set<DashboardModuleType>()

        for module in modules {
            guard seenTypes.insert(module.type).inserted else {
                continue
            }

            normalizedModules.append(
                DashboardModuleConfiguration(
                    type: module.type,
                    isVisible: module.isVisible,
                    isExpandedByDefault: module.isExpandedByDefault
                )
            )
        }

        for type in DashboardModuleType.allCases where seenTypes.contains(type) == false {
            normalizedModules.append(
                DashboardModuleConfiguration(
                    type: type,
                    isVisible: defaultVisibility(for: type),
                    isExpandedByDefault: defaultExpandedState(for: type)
                )
            )
        }

        return normalizedModules
    }

    private static func defaultVisibility(for type: DashboardModuleType) -> Bool {
        switch type {
        case .battery, .network, .cpu, .memory, .disk, .sensors:
            true
        case .cpuCores, .alerts, .trends, .runningApps:
            false
        }
    }

    private static func defaultExpandedState(for type: DashboardModuleType) -> Bool {
        switch type {
        case .cpuCores, .sensors, .alerts, .trends, .runningApps:
            false
        case .battery, .network, .cpu, .memory, .disk:
            false
        }
    }
}
