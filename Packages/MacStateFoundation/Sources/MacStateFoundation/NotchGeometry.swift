import Foundation
import CoreGraphics

public enum NotchGeometry {
    /// AppKit screen coordinates, including displays left of or above the primary display.
    public static func frame(screen: CGRect, safeTop: CGFloat, centerX: CGFloat,
                             size: CGSize) -> CGRect {
        let width = min(size.width, screen.width)
        let height = min(size.height, max(0, screen.height - safeTop))
        return CGRect(x: min(max(centerX - width / 2, screen.minX), screen.maxX - width),
                      y: screen.maxY - safeTop - height, width: width, height: height)
    }
}
