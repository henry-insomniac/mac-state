@MainActor
enum AppAssembler {
    static func makeLiveContainer() -> DependencyContainer {
        DependencyContainer(appState: AppState())
    }
}
