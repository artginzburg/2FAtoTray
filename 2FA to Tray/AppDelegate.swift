//
//  AppDelegate.swift
//  2FA to Tray
//
//  Created by Arthur Ginzburg on 26.01.2020.
//  Copyright © 2020 DaFuqtor. All rights reserved.
//

import Cocoa
import JavaScriptCore

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

class OTP {
  
  private var fn:JSValue?
  private var timer:Timer?
  var token:String
  var button:NSStatusBarButton?
  var secret:String
  
  init() {
    fn = nil
    button = nil
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
        self.button!.toolTip = token
      }
    }
  }
  
  func initTimer() {
    self.timer = Timer.new(every: 2.second) {
      self.updateTimer()
    }
    self.timer!.start()
  }
  
  func copy() {
    if self.token.isEmpty {
      self.showAlert()
    } else {
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(self.token, forType: NSPasteboard.PasteboardType.string)
    }
  }
  
  func showAlert() {
    if (NSApplication.shared.modalWindow) != nil {
      return
    }
    let alert = NSAlert()
    alert.messageText = "Change secret seed"
    alert.informativeText = "Enter a code which should look like this:"
    
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "Delete secret from disk")
    
    let textfield = EditableNSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 150.0, height: 22.0))
    textfield.alignment = .center
    textfield.placeholderString = "AADEM4YUY5GYZHHP"
    alert.accessoryView = textfield
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      textfield.becomeFirstResponder()
    }

    let response = alert.runModal()
    
    if response == .alertFirstButtonReturn {
      let value = textfield.stringValue
      if !value.isEmpty {
        let secret = value.condenseWhitespace()
        print(secret)
        UserDefaults.standard.set(secret, forKey: "secret")
        self.button?.appearsDisabled = false
        self.secret = secret
      } else {
        print("Empty value")
      }
    } else if response == .alertThirdButtonReturn {
      print("Delete secret")
      UserDefaults.standard.removeObject(forKey: "secret")
      self.secret = ""
      self.token = ""
      self.button?.toolTip = ""
      self.button?.appearsDisabled = true
    }
  }
  
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
}
