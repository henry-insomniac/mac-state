import Foundation
import Testing
@testable import MacStateFoundation

@Test func widgetDeliveryWritesEveryMinuteAndReloadsEveryFiveMinutes() {
    let start = Date(timeIntervalSince1970: 1_000)
    var policy = WidgetDeliveryPolicy()
    #expect(policy.shouldCheckConfiguration(at: start))
    let result8 = !policy.beginWrite(at: start)
    #expect(result8)
    policy.recordConfiguration(hasWidget: true, at: start)
    var writes = 0
    var reloads = 0
    for second in stride(from: 0, through: 600, by: 2) {
        let now = start.addingTimeInterval(Double(second))
        if policy.beginWrite(at: now) {
            writes += 1
            if policy.shouldReloadAfterSuccessfulWrite(at: now) { reloads += 1 }
        }
    }
    #expect(writes == 11)
    #expect(reloads == 3)
}

@Test func widgetRemovalAndReadditionResetDelivery() {
    let now = Date(timeIntervalSince1970: 1_000)
    var policy = WidgetDeliveryPolicy()
    policy.recordConfiguration(hasWidget: true, at: now)
    let result27 = policy.beginWrite(at: now)
    #expect(result27)
    let result28 = policy.shouldReloadAfterSuccessfulWrite(at: now)
    #expect(result28)
    policy.recordConfiguration(hasWidget: false, at: now.addingTimeInterval(60))
    let result30 = !policy.beginWrite(at: now.addingTimeInterval(100))
    #expect(result30)
    policy.recordConfiguration(hasWidget: true, at: now.addingTimeInterval(120))
    let result32 = policy.beginWrite(at: now.addingTimeInterval(120))
    #expect(result32)
    let result33 = policy.shouldReloadAfterSuccessfulWrite(at: now.addingTimeInterval(120))
    #expect(result33)
}

@Test func failedWidgetWritesAreThrottledWithoutSpendingReloadInterval() {
    let now = Date(timeIntervalSince1970: 1_000)
    var policy = WidgetDeliveryPolicy()
    policy.recordConfiguration(hasWidget: true, at: now)
    let result40 = policy.beginWrite(at: now)
    #expect(result40)
    // Failed save: deliberately do not call shouldReloadAfterSuccessfulWrite.
    let result42 = !policy.beginWrite(at: now.addingTimeInterval(2))
    #expect(result42)
    let result43 = policy.beginWrite(at: now.addingTimeInterval(60))
    #expect(result43)
    let result44 = policy.shouldReloadAfterSuccessfulWrite(at: now.addingTimeInterval(60))
    #expect(result44)
    #expect(!policy.shouldCheckConfiguration(at: now.addingTimeInterval(59)))
    #expect(policy.shouldCheckConfiguration(at: now.addingTimeInterval(60)))
}

@Test func widgetDeliveryRecoversFromClockMovingBackwards() {
    let now = Date(timeIntervalSince1970: 1_000)
    var policy = WidgetDeliveryPolicy()
    policy.recordConfiguration(hasWidget: true, at: now)
    let result53 = policy.beginWrite(at: now)
    #expect(result53)
    let result54 = policy.shouldReloadAfterSuccessfulWrite(at: now)
    #expect(result54)
    let earlier = now.addingTimeInterval(-100)
    #expect(policy.shouldCheckConfiguration(at: earlier))
    let result57 = policy.beginWrite(at: earlier)
    #expect(result57)
    let result58 = policy.shouldReloadAfterSuccessfulWrite(at: earlier)
    #expect(result58)
}

@Test func widgetFreshnessHandlesMissingExpiredAndFutureSnapshots() {
    let now = Date(timeIntervalSince1970: 1_000)
    #expect(WidgetDataFreshness(timestamp: nil, now: now) == .missing)
    #expect(WidgetDataFreshness(timestamp: now, now: now) == .current)
    #expect(WidgetDataFreshness(timestamp: now.addingTimeInterval(-599), now: now) == .current)
    #expect(WidgetDataFreshness(timestamp: now.addingTimeInterval(-600), now: now) == .stale)
    #expect(WidgetDataFreshness(timestamp: now.addingTimeInterval(61), now: now) == .stale)
}
