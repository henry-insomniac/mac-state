import Foundation
import CoreGraphics
import Testing
@testable import MacStateFoundation

@Test func hoverCannotDismissPinnedPanel() {
    var state = NotchPresentation.collapsed
    state.hover()
    #expect(state == .preview)
    state.toggle()
    state.leave()
    state.hover()
    #expect(state == .expanded)
    state.toggle()
    #expect(state == .collapsed)
}

@Test func leavingPreviewCollapsesIt() {
    var state = NotchPresentation.preview
    state.leave()
    #expect(state == .collapsed)
}

@Test func notchPlacementRespectsOffsetScreensAndCamera() {
    let screen = CGRect(x: -1440, y: 180, width: 1440, height: 900)
    let frame = NotchGeometry.frame(screen: screen, safeTop: 32, centerX: -720,
                                    size: CGSize(width: 400, height: 300))
    #expect(frame.midX == -720)
    #expect(frame.maxY == 1048)
    #expect(screen.contains(frame))
}

@Test func oversizedPanelStaysWithinSmallDisplay() {
    let screen = CGRect(x: 100, y: -600, width: 320, height: 240)
    let frame = NotchGeometry.frame(screen: screen, safeTop: 0, centerX: 0,
                                    size: CGSize(width: 420, height: 360))
    #expect(frame == screen)
}
