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

enum IOServiceError: ErrorType {
    case FailedToGetMasterPort
    case FailedToCreateMatchingDictionary
    case FailedToChangeSetting
    case FailedToGetSetting
}

func createConnect() throws -> io_connect_t {
    let masterPort = UnsafeMutablePointer<mach_port_t>.alloc(1)
    let iterator = UnsafeMutablePointer<io_iterator_t>.alloc(1)
    let connect = UnsafeMutablePointer<io_connect_t>.alloc(1)
    
    guard IOMasterPort(bootstrap_port, masterPort) == KERN_SUCCESS else {
        throw IOServiceError.FailedToGetMasterPort
    }
    
    guard let classToMatch = IOServiceMatching(kIOHIDSystemClass) else {
        throw IOServiceError.FailedToCreateMatchingDictionary
    }
    
    guard IOServiceGetMatchingServices(masterPort.memory, classToMatch, iterator) == KERN_SUCCESS else {
        throw IOServiceError.FailedToCreateMatchingDictionary
    }
    
    let nextObject = IOIteratorNext(iterator.memory)
    
    IOObjectRelease(iterator.memory)
    
    guard IOServiceOpen(nextObject, mach_task_self_, UInt32(kIOHIDParamConnectType), connect) == KERN_SUCCESS else {
        throw IOServiceError.FailedToCreateMatchingDictionary
    }
    
    return connect.memory
}

func changeSetting(setting: Bool) throws {
    let connect = try createConnect()
    let newValue = UnsafeMutablePointer<Int>.alloc(1)
    newValue.memory = Int(setting)
    NSLog("setting FKeyModeKey value to be %d", newValue.memory)
    guard IOHIDSetParameter(connect, kIOHIDFKeyModeKey, newValue, IOByteCount(sizeof(Int))) == KERN_SUCCESS else {
        IOServiceClose(connect)
        throw IOServiceError.FailedToChangeSetting
    }
    IOServiceClose(connect)
}

func getSetting() throws -> Bool {
    let connect = try createConnect()
    let result = UnsafeMutablePointer<Int>.alloc(1)
    let actualSize = UnsafeMutablePointer<IOByteCount>.alloc(1)
    
    guard IOHIDGetParameter(connect, kIOHIDFKeyModeKey, IOByteCount(sizeof(Int)), result, actualSize) == KERN_SUCCESS else {
        IOServiceClose(connect)
        throw IOServiceError.FailedToGetSetting
    }
    
    NSLog("FKeyModeKey is %d", result.memory)

    IOServiceClose(connect)
    
    return Bool(result.memory)
}

func getSettingSafe() -> Bool {
    do {
        return try getSetting()
    } catch {
        return false
    }
}

func saveState() {
    CFPreferencesSetAppValue("fnState", kCFBooleanFalse, "com.apple.keyboard")
    CFPreferencesAppSynchronize("com.apple.keyboard")
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), "com.apple.keyboard.fnstatedidchange", nil, nil, true)
}