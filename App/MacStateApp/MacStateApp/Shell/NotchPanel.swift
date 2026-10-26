import AppKit

@MainActor
final class NotchPanel: NSPanel {
    var acceptsKeyboard = false
    var dismiss: (() -> Void)?

    override var canBecomeKey: Bool { acceptsKeyboard }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        dismiss?()
    }
}
