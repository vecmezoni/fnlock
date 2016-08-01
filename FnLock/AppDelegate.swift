import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var menu: NSMenu!

    @IBAction func quitClicked(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    let iconOff = NSImage(named: "icon-off")
    let iconOn = NSImage(named: "icon-on")

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        deduplicateRunningInstances()

        statusItem.menu = menu

        iconOff?.template = true
        iconOn?.template = true

        statusItem.image = iconOn

        let fnLock = FnLock.singleton
        let daemon = NSThread(target: fnLock, selector: #selector(NSRunLoop.run), object: nil)

        fnLock.onStateChange = changeIcon
        changeIcon(fnLock.state)
        daemon.start()
    }

    func changeIcon(state: Bool) {
        statusItem.image = state ? iconOn : iconOff
    }

    func deduplicateRunningInstances() {
        if NSRunningApplication.runningApplicationsWithBundleIdentifier(NSBundle.mainBundle().bundleIdentifier!).count > 1 {
            let alert = NSAlert()
            alert.messageText = "Another copy of fnlock is already running."
            alert.informativeText = "This copy will now quit."
            alert.runModal()
            NSApplication.sharedApplication().terminate(self)
        }
    }

}
