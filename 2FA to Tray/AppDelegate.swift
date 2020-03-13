import Cocoa

let defaults = UserDefaults.standard

import KeychainAccess

let keychain = Keychain(service: Bundle.main.bundleIdentifier!)

var otpInstances: [OTP] = []

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldHandleReopen(_ sender: NSApplication,
                                     hasVisibleWindows flag: Bool) -> Bool
  {
    if NSApp.isShiftKeyDown {
      statusItem.button!.performClick(NSApp.currentEvent)
    } else {
      otpInstances[currentlySelectedSeed].copy()
      if let button = statusItem.button {
        button.momentaryHighlight()
      }
    }
    return true
  }
}
