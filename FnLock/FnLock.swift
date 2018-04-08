import IOKit.hid
import Foundation

class FnLock: NSObject {
    static let singleton = FnLock()

    let manager = try! FnLock.setupManager()

    let keyboardDictionary = [kIOHIDPrimaryUsageKey: kHIDUsage_GD_Keyboard]
    let ledDictionary = [kIOHIDElementUsagePageKey: kHIDPage_LEDs, kIOHIDElementUsageKey: kHIDUsage_LED_CapsLock]

    var state = getSettingSafe()
    var keyboard: IOHIDDevice?
    var led: IOHIDElement?
    var onStateChange: ((Bool) -> ())? = nil

    override init() {
        super.init()
        keyboard = getKeyboard()
        led = getLed()
    }

    class func setupManager() throws -> IOHIDManager {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        return manager
    }

    func getKeyboard() -> IOHIDDevice {
        IOHIDManagerSetDeviceMatching(manager, keyboardDictionary as CFDictionary)

        let matchingDevices = IOHIDManagerCopyDevices(manager) as! NSSet

        return matchingDevices.anyObject() as! IOHIDDevice
    }

    func getLed() -> IOHIDElement {
        let elements = IOHIDDeviceCopyMatchingElements(keyboard!, ledDictionary as CFDictionary, 0) as! Array<IOHIDElement>

        IOHIDDeviceOpen(keyboard!, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))

        return elements[0]
    }

    func toggleLed(state: Bool) {
        let value = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, led!, 0, state ? 1 : 0)
        IOHIDDeviceSetValue(keyboard!, led!, value)
    }

    @objc func updateLed() {
        if self.state {
            toggleLed(state: self.state)
        }
    }

    @objc func run() {
        let ctx = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        IOHIDDeviceRegisterInputValueCallback(keyboard!, { (context, result, sender, value) in

            let fnLock = unsafeBitCast(context, to: FnLock.self)

            let element = IOHIDValueGetElement(value)
            let elementValue = IOHIDValueGetIntegerValue(value)
            let usage = Int(IOHIDElementGetUsage(element))
            if usage == kHIDUsage_KeyboardCapsLock && elementValue == 0 {
                do {
                    try changeSetting(setting: !fnLock.state)
                    fnLock.toggleLed(state: !fnLock.state)
                    fnLock.state = try getSetting()
                    saveState()
                    fnLock.onStateChange!(fnLock.state)
                } catch {
                    NSLog("failed to change fn setting to %s %s", !fnLock.state)
                }
            }

            }, ctx)

        // TODO: I have no idea why someone switches caps lock led off while user is switching windows
        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.updateLed), userInfo: nil, repeats: true)

        RunLoop.current.run()
    }

}
