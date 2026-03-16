import AppKit

private let helperApplication = NSApplication.shared
private let helperDelegate = LoginHelperAppDelegate()

helperApplication.setActivationPolicy(.prohibited)
helperApplication.delegate = helperDelegate
helperApplication.run()

private final class LoginHelperAppDelegate: NSObject, NSApplicationDelegate {
    private let mainApplicationBundleIdentifier = "io.github.henry-insomniac.mac-state"

    func applicationDidFinishLaunching(_ notification: Notification) {
        if NSRunningApplication.runningApplications(
            withBundleIdentifier: mainApplicationBundleIdentifier
        ).isEmpty == false {
            NSApp.terminate(nil)
            return
        }

        let mainApplicationURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.createsNewApplicationInstance = false

        NSWorkspace.shared.openApplication(
            at: mainApplicationURL,
            configuration: configuration
        ) { _, _ in
            NSApp.terminate(nil)
        }
    }
}
