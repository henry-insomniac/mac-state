import Testing
@testable import MacStateMetrics

@Test func defaultSnapshotUsesExpectedRanges() {
    let snapshot = MetricSnapshot.placeholder()

    #expect(snapshot.cpuUsage >= 0)
    #expect(snapshot.cpuUsage <= 1)
    #expect(snapshot.memoryUsage >= 0)
    #expect(snapshot.memoryUsage <= 1)
    #expect(snapshot.networkDownloadRate >= 0)
    #expect(snapshot.networkUploadRate >= 0)
}
