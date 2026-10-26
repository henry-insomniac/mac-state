import Foundation

public enum SharedDataConfiguration {
    public static let appGroupIdentifier: String = {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "MacStateAppGroupIdentifier") as? String,
           !configured.isEmpty, !configured.hasPrefix("$(") {
            return configured
        }
        return "group.io.github.henry-insomniac.mac-state"
    }()
    public static let widgetSnapshotFilename = "latest-widget-snapshot.json"
    public static let metricOverviewWidgetKind = "MetricOverviewWidget"
}
