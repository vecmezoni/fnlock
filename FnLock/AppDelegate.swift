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
        statusItem.menu = menu
        
        iconOff?.template = true
        iconOn?.template = true

        statusItem.image = iconOn

        let fnLock = FnLock.singleton
        let daemon = NSThread(target: fnLock, selector:#selector(NSRunLoop.run), object: nil)
        
        fnLock.onStateChange = changeIcon
        changeIcon(fnLock.state)
        daemon.start()
    }
    
    func changeIcon(state: Bool) {
        statusItem.image = state ? iconOn : iconOff
    }
}

