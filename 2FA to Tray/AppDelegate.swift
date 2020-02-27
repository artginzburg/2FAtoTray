//
//  AppDelegate.swift
//  2FA to Tray
//
//  Created by Arthur Ginzburg on 26.01.2020.
//  Copyright © 2020 DaFuqtor. All rights reserved.
//

import Cocoa
import JavaScriptCore

let defaults = UserDefaults.standard
extension UserDefaults {
  func boolToggle(_ forKey: String) {
    self.set(!self.bool(forKey: forKey), forKey: forKey)
  }
}

extension NSControl.StateValue {
  mutating func toggle() {
    self = self == .on ? .off : .on
  }
  mutating func by(_ bool: Bool) {
    self = bool ? .on : .off
  }
}

import KeychainAccess
let keychain = Keychain(service: Bundle.main.bundleIdentifier!)

extension String {
  func condenseWhitespace() -> String {
    return self.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
  }
}

final class EditableNSTextField: NSTextField {
  
  private let commandKey = NSEvent.ModifierFlags.command.rawValue
  private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
  
  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.type == NSEvent.EventType.keyDown {
      if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
        switch event.charactersIgnoringModifiers! {
        case "x":
          if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
        case "c":
          if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
        case "v":
          if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
        case "z":
          if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) { return true }
        case "a":
          if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self) { return true }
        default:
          break
        }
      } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
        if event.charactersIgnoringModifiers == "Z" {
          if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) { return true }
        }
      }
    }
    return super.performKeyEquivalent(with: event)
  }
}

import AppKit
import Carbon

let clipboard = Clipboard()
class Clipboard {
  private let pasteboard = NSPasteboard.general
  
  func copy(_ string: String) {
    pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
    pasteboard.setString(string, forType: NSPasteboard.PasteboardType.string)
  }
  
  func paste() {
    if !AXIsProcessTrusted() {
      return
    }
    checkAccessibilityPermissions()
    
    DispatchQueue.main.async {
      let vCode = UInt16(kVK_ANSI_V)
      let source = CGEventSource(stateID: .combinedSessionState)
      // Disable local keyboard events while pasting
      source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents],
                                                         state: .eventSuppressionStateSuppressionInterval)
      
      let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: true)
      let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: false)
      keyVDown?.flags = .maskCommand
      keyVUp?.flags = .maskCommand
      keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
      keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
  }
  
  func checkAccessibilityPermissions() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
    AXIsProcessTrustedWithOptions(options)
  }
}

var otpInstances: [OTP] = []
class OTP {
  
  private var fn:JSValue?
  private var timer:Timer?
  var token:String
  var button:NSStatusBarButton?
  var displayItem:NSMenuItem?
  var secret:String
  
  init() {
    fn = nil
    button = nil
    displayItem = nil
    timer = nil
    secret = ""
    token = ""
  }
  
  func start() {
    let bundle = Bundle.main
    let path = bundle.path(forResource: "totp", ofType: "js")!
    let jsSource = try? String.init(contentsOfFile: path)
    let context = JSContext()!
    context.evaluateScript(jsSource)
    fn = context.objectForKeyedSubscript("otp")
    timer = nil
    token = ""
    updateTimer()
    initTimer()
  }
  
  func updateTimer() {
    if self.secret != "" {
      let result = self.fn!.call(withArguments: [self.secret])
      let token = result!.toString()!
      if self.token != token {
        self.token = token
        self.button?.toolTip = token
        self.button?.appearsDisabled = false
        self.displayItem?.title = token
        self.displayItem?.isHidden = false
        self.displayItem?.isEnabled = true
      }
    }
  }
  
  func initTimer() {
    self.timer = Timer.new(every: 1.second) {
      self.updateTimer()
    }
    self.timer!.start()
  }
  
  func copy() {
    clipboard.copy(self.token)
    print("copied the token")
  }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldHandleReopen(_ sender: NSApplication,
                                     hasVisibleWindows flag: Bool) -> Bool
  {
    otpInstances[currentlySelectedSeed].copy()
    if let button = statusItem.button {
      button.highlight(true)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        button.highlight(false)
      }
      print("highlighted statusItem.button")
    }
    print("handled reopen")
    return true
  }
}
