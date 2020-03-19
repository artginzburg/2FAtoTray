import Cocoa
import HotKey

let defaults = UserDefaults.standard

import KeychainAccess

let keychain = Keychain(service: Bundle.main.bundleIdentifier!)

var otpInstances: [OTP] = []

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    hotKey = HotKey(key: .g, modifiers: [.command, .option])
  }
  
  public var hotKey: HotKey? {
    didSet {
      guard let hotKey = hotKey else {
        return
      }
      
      hotKey.keyDownHandler = {
        statusItem.button!.isHighlighted = true
        otpInstances[currentlySelectedSeed].copy()
        if defaults.bool(forKey: "pasteOnHotkey") {
          Clipboard.shared.paste()
          enterAfterAutoPaste()
        }
      }
      
      hotKey.keyUpHandler = {
        statusItem.button!.isHighlighted = false
      }
    }
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication,
                                     hasVisibleWindows flag: Bool) -> Bool
  {
    if NSApp.isShiftKeyDown {
      statusItem.button!.performClick(NSApp.currentEvent)
    } else {
      otpInstances[currentlySelectedSeed].copy()
      statusItem.button!.momentaryHighlight()
    }
    return true
  }
}
