/*
 * ported to swift from https://github.com/nelsonjchen/fntoggle/blob/95c649235593269568989fafb8da6b08ccdd6b37/fntoggle/main.m
 * Schism Tracker - a cross-platform Impulse Tracker clone
 * copyright (c) 2003-2005 Storlek <storlek@rigelseven.com>
 * copyright (c) 2005-2008 Mrs. Brisby <mrs.brisby@nimh.org>
 * copyright (c) 2009 Storlek & Mrs. Brisby
 * copyright (c) 2010-2012 Storlek
 * URL: http://schismtracker.org/
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

import Foundation

enum IOServiceError: Error {
    case failedToGetMasterPort
    case failedToCreateMatchingDictionary
    case failedToChangeSetting
    case failedToGetSetting
}

func changeSetting(setting: Bool) throws {
    var enabled = setting ? UInt32(0) : UInt32(1)

    var connect: io_connect_t = 0

    let classToMatch = IOServiceMatching(kIOHIDSystemClass)

    let service = IOServiceGetMatchingService(kIOMasterPortDefault, classToMatch)

    guard IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect) == kIOReturnSuccess else {
        NSLog("Failed to changeSetting: failed to open service")
        throw IOServiceError.failedToChangeSetting
    }

    guard IOHIDSetParameter(connect, kIOHIDFKeyModeKey as CFString, &enabled, 1) == kIOReturnSuccess else {
        NSLog("Failed to changeSetting: failed to set parameter")
        throw IOServiceError.failedToChangeSetting
    }

    guard IOServiceClose(connect) == kIOReturnSuccess else {
        NSLog("Failed to changeSetting: failed to close service")
        throw IOServiceError.failedToChangeSetting
    }
}

func getSetting() throws -> Bool {
    var connect: io_connect_t = 0

    let classToMatch = IOServiceMatching(kIOHIDSystemClass)

    let service = IOServiceGetMatchingService(kIOMasterPortDefault, classToMatch)

    guard IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect) == kIOReturnSuccess else {
        NSLog("Failed to getSetting: failed to open service")
        throw IOServiceError.failedToGetSetting
    }

    var value = UInt32(0)
    var actualSize = UInt32(0)

    guard IOHIDGetParameter(connect, kIOHIDFKeyModeKey as CFString, 1, &value, &actualSize) == kIOReturnSuccess else {
        NSLog("Failed to getSetting: failed to get parameter")
        throw IOServiceError.failedToGetSetting
    }

    guard IOServiceClose(connect) == kIOReturnSuccess else {
        NSLog("Failed to getSetting: failed to close service")
        throw IOServiceError.failedToGetSetting
    }

    return value == 0
}

func getSettingSafe() -> Bool {
    do {
        return try getSetting()
    } catch {
        return false
    }
}

func saveState() {
    CFPreferencesSetAppValue("fnState" as CFString, kCFBooleanFalse, "com.apple.keyboard" as CFString)
    CFPreferencesAppSynchronize("com.apple.keyboard" as CFString)
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFNotificationName.init(rawValue: "com.apple.keyboard.fnstatedidchange" as CFString), nil, nil, true)
}
