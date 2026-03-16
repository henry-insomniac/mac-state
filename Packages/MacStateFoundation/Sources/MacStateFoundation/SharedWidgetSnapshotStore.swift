import Foundation

public final class SharedWidgetSnapshotStore {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        fileURL: URL? = nil,
        appGroupIdentifier: String = SharedDataConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
    }

    public func load() -> WidgetSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    public func save(_ snapshot: WidgetSnapshot) {
        let parentDirectoryURL = fileURL.deletingLastPathComponent()
        try? fileManager.createDirectory(
            at: parentDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        try? data.write(to: fileURL, options: .atomic)
    }

    public static func defaultFileURL(
        appGroupIdentifier: String = SharedDataConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) -> URL {
        if let groupContainerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            return groupContainerURL
                .appendingPathComponent(SharedDataConfiguration.widgetSnapshotFilename, isDirectory: false)
        }

        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        return applicationSupportURL
            .appendingPathComponent("mac-state", isDirectory: true)
            .appendingPathComponent(SharedDataConfiguration.widgetSnapshotFilename, isDirectory: false)
    }
}
