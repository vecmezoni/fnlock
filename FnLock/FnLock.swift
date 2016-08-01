import IOKit.hid
import Foundation

enum IOHIDError: ErrorType {
    case FailedToOpenManager
    case FailedToGetKeyboard
    case FailedToGetLed
}

class FnLock: NSObject {
    static let singleton = FnLock()

    let manager = try! FnLock.setupManager()

    let keyboardDictionary = [kIOHIDPrimaryUsageKey: kHIDUsage_GD_Keyboard]
    let ledDictionary = [kIOHIDElementUsagePageKey: kHIDPage_LEDs, kIOHIDElementUsageKey: kHIDUsage_LED_CapsLock]

    var state = getSettingSafe()
    var keyboard: IOHIDDevice?
    var led: IOHIDElement?
    var onStateChange: (Bool -> ())? = nil

    override init() {
        super.init()
        keyboard = try! getKeyboard()
        led = try! getLed()
    }

    class func setupManager() throws -> IOHIDManager {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDManagerOptionNone.rawValue).takeRetainedValue()

        guard IOHIDManagerOpen(manager, kIOHIDManagerOptionNone.rawValue) == kIOReturnSuccess else {
            throw IOHIDError.FailedToOpenManager
        }

        return manager
    }

    func getKeyboard() throws -> IOHIDDevice {
        IOHIDManagerSetDeviceMatching(manager, keyboardDictionary)

        let matchingDevices = IOHIDManagerCopyDevices(manager).takeRetainedValue() as NSSet

        guard let object = matchingDevices.anyObject() where object is IOHIDDevice else {
            throw IOHIDError.FailedToGetKeyboard
        }

        return object as! IOHIDDevice
    }

    func getLed() throws -> IOHIDElement {
        let elements = IOHIDDeviceCopyMatchingElements(keyboard, ledDictionary, 0).takeRetainedValue()

        guard IOHIDDeviceOpen(keyboard, IOOptionBits(kIOHIDOptionsTypeSeizeDevice)) == kIOReturnSuccess else {
            throw IOHIDError.FailedToGetLed
        }

        let arrayValue: UnsafePointer<Void> = CFArrayGetValueAtIndex(elements, 0)

        return Unmanaged<IOHIDElement>.fromOpaque(COpaquePointer(arrayValue)).takeRetainedValue()
    }

    func toggleLed(state: Bool) {
        let value = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, led, 0, state ? 1 : 0).takeRetainedValue()
        IOHIDDeviceSetValue(keyboard, led, value)
    }

    func updateLed() {
        if self.state {
            toggleLed(self.state)
        }
    }

    func run() {
        let ctx = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)

        IOHIDDeviceRegisterInputValueCallback(keyboard, { (context, result, sender, value) in

            let fnLock = unsafeBitCast(context, FnLock.self)

            let element = IOHIDValueGetElement(value)
            let elementValue = IOHIDValueGetIntegerValue(value)
            let usage = Int(IOHIDElementGetUsage(element.takeUnretainedValue()))
            if usage == kHIDUsage_KeyboardCapsLock && elementValue == 0 {
                do {
                    try changeSetting(!fnLock.state)
                    fnLock.toggleLed(!fnLock.state)
                    fnLock.state = try getSetting()
                    saveState()
                    fnLock.onStateChange!(fnLock.state)
                } catch {
                    NSLog("failed to change fn setting to %s %s", !fnLock.state)
                }
            }

            }, ctx)

        // TODO: I have no idea why someone switches caps lock led off while user is switching windows
        NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(self.updateLed), userInfo: nil, repeats: true)

        NSRunLoop.currentRunLoop().run()
    }

}
