public protocol MetricsSnapshotProviding: Sendable {
    func snapshot() async throws -> MetricSnapshot
}
