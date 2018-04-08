import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var menu: NSMenu!

    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let iconOff = NSImage(named: NSImage.Name(rawValue: "icon-off"))
    let iconOn = NSImage(named: NSImage.Name(rawValue: "icon-on"))

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        deduplicateRunningInstances()

        statusItem.menu = menu

        iconOff?.isTemplate = true
        iconOn?.isTemplate = true

        statusItem.image = iconOn

        let fnLock = FnLock.singleton
        let daemon = Thread(target: fnLock, selector: #selector(FnLock.run), object: nil)

        fnLock.onStateChange = changeIcon
        changeIcon(state: fnLock.state)
        daemon.start()
    }

    func changeIcon(state: Bool) {
        statusItem.image = state ? iconOn : iconOff
    }

    func deduplicateRunningInstances() {
        if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!).count > 1 {
            let alert = NSAlert()
            alert.messageText = "Another copy of fnlock is already running."
            alert.informativeText = "This copy will now quit."
            alert.runModal()
            NSApplication.shared.terminate(self)
        }
    }

}
