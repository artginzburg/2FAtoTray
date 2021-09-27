//
//  StatusMenuController.swift
//  2FA to Tray
//
//  Created by Arthur Ginzburg on 26.01.2020.
//  Copyright © 2020 DaFuqtor. All rights reserved.
//

import Cocoa

public extension NSImage {
  func rotated(_ angle: CGFloat) -> NSImage {
    let img = NSImage(size: self.size, flipped: false, drawingHandler: { rect -> Bool in
      let (width, height) = (rect.size.width, rect.size.height)
      let transform = NSAffineTransform()
      transform.translateX(by: width / 2, yBy: height / 2)
      transform.rotate(byDegrees: angle)
      transform.translateX(by: -width / 2, yBy: -height / 2)
      transform.concat()
      self.draw(in: rect)
      return true
    })
    img.isTemplate = self.isTemplate // preserve the underlying image's template setting
    return img
  }
  func rotatedZ(_ angle: CGFloat) -> NSImage {
    self.size.width = self.size.width - angle
    return self
  }
  func spinZ(_ angleDegrees: Int = 0, _ times: Int = -1) -> NSImage {
    var newDegrees = angleDegrees
    if (times == -1) {
      var theWidth = self.size.width
      var newTimes = theWidth * 2
      newDegrees = Int(theWidth)
    } else {
      var newTimes = times - 1
    }
    
    newDegrees = newDegrees - 1

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.0000001) {
      self.spinZ(newDegrees, Int(theWidth))
    }
    return self.rotatedZ(CGFloat(newDegrees))
  }
}

var iconDegrees = 0

extension NSStatusBarButton {
  func spin(from: Int = 0, to: Int = -940) {
    let theImage = NSImage(named: "StatusIcon")
    if iconDegrees <= to {
      iconDegrees = from
      
      self.image = theImage?.rotated(CGFloat(iconDegrees))
    } else {
      
      if iconDegrees > from {
        iconDegrees -= 1
      } else if iconDegrees < from - 10 && iconDegrees > from - 30 {
        iconDegrees -= 2
      } else if iconDegrees < from - 30 && iconDegrees > from - 60 {
        iconDegrees -= 3
      } else if iconDegrees < from - 60 && iconDegrees > from - 100 {
        iconDegrees -= 4
      } else if iconDegrees < from - 100 && iconDegrees > from - 150 {
        iconDegrees -= 5
      } else if iconDegrees < from - 150 && iconDegrees > from - 220 {
        iconDegrees -= 6
      } else if iconDegrees < from - 220 && iconDegrees > from - 300 {
        iconDegrees -= 7
      } else if iconDegrees < from - 300 && iconDegrees > from - 390 {
        iconDegrees -= 8
      } else if iconDegrees < from - 390 && iconDegrees > to + 450 {
        iconDegrees -= 9
      } else if iconDegrees < to + 450 && iconDegrees > to + 360 {
        iconDegrees -= 8
      } else if iconDegrees < to + 360 && iconDegrees > to + 280 {
        iconDegrees -= 7
      } else if iconDegrees < to + 280 && iconDegrees > to + 210 {
        iconDegrees -= 6
      } else if iconDegrees < to + 210 && iconDegrees > to + 150 {
        iconDegrees -= 5
      } else if iconDegrees < to + 150 && iconDegrees > to + 100 {
        iconDegrees -= 4
      } else if iconDegrees < to + 100 && iconDegrees > to + 60 {
        iconDegrees -= 3
      } else if iconDegrees < to + 60 && iconDegrees > to + 30 {
        iconDegrees -= 3
      } else if iconDegrees < to + 30 && iconDegrees > to + 10 {
        iconDegrees -= 2
      } else if iconDegrees < to + 10 && iconDegrees > to {
        iconDegrees -= 1
      }
      else {
        iconDegrees -= 1
      }
      
      self.image = theImage?.rotated(CGFloat(iconDegrees))
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.0000001) {
        self.spin()
      }
    }
  }
  
  func fadeOut(_ step: CGFloat = 0.01) {
    if !self.appearsDisabled {
      self.alphaValue -= step
      
      if self.alphaValue > 0.3 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
          self.fadeOut()
        }
      } else {
        self.appearsDisabled = true
        self.alphaValue = 1
      }
    }
  }
  
  func fadeIn(_ step: CGFloat = 0.02) {
      if self.alphaValue == 1 {
        self.appearsDisabled = false
        self.alphaValue = 0.3
      }
      
      self.alphaValue += step
      
      if self.alphaValue < 1 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
          self.fadeIn()
        }
      } else {
        self.appearsDisabled = false
        self.alphaValue = 1
      }
  }
}


import HotKey
private extension HotKey {
  func handleKeyDown(_ handler: @escaping (() -> Void)) {
    keyDownHandler = {
      handler()
      self.handleKeyDown(handler)
    }
  }
}

let statusItem = NSStatusBar.system.statusItem(withLength: 22)

var currentlySelectedSeed:  Int  {
  get {
    let QTYofInstances = otpInstances.count
    if defaults.integer(forKey: "selected") + 1 > QTYofInstances {
      let newSelected = (QTYofInstances - 1 < 0) ? 0 : (QTYofInstances - 1)
      defaults.set(newSelected, forKey: "selected")
    }
    return defaults.integer(forKey: "selected")
  }
  set {
    defaults.set(newValue, forKey: "selected")
    reinitializeStates(newValue)
  }
}

func turnAllStatesOff() {
  if !otpInstances.isEmpty {
    for instance in otpInstances {
      if (instance.displayItem != nil) {
        instance.displayItem?.state = .off
      }
    }
//    print("turned all states off")
  }
}

func setStateForSelected(_ selected: Int) {
  if !otpInstances.isEmpty {
    if (otpInstances[selected].displayItem != nil) {
//      print("set selected state for: \(selected)")
      otpInstances[selected].displayItem?.state = .on
    }
  }
}

func reinitializeStates(_ select: Int) {
  turnAllStatesOff()
  setStateForSelected(select)
//  print("Newly selected instance: \(select)")
}

import LoginServiceKit
import Carbon
import Paddle

class StatusMenuController: NSObject, NSMenuDelegate {
  
  func resize(image: NSImage, w: Int, h: Int) -> NSImage {
    let destSize = NSMakeSize(CGFloat(w), CGFloat(h))
    let newImage = NSImage(size: destSize)
    newImage.lockFocus()
    image.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, image.size.width, image.size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
    newImage.unlockFocus()
    newImage.size = destSize
    return NSImage(data: newImage.tiffRepresentation!)!
  }
  
  @IBOutlet weak var statusMenu: NSMenu!
  
  @IBAction func changeSecret(_ sender: NSMenuItem) {
    showAlert()
  }
  
  func showAlert() {
    let theShow = {
      if otpInstances.isEmpty {
//        print("otpInstances is empty")
        return
      }
      if (NSApplication.shared.modalWindow) != nil {
        return
      }
      let currentlySelectedInstance = otpInstances[currentlySelectedSeed]
      let alert = NSAlert()
      alert.messageText = "Change secret seed"
      alert.informativeText = "Enter a code which should look like this:"
      
      alert.addButton(withTitle: "OK")
      alert.addButton(withTitle: "Cancel")
      alert.addButton(withTitle: "Delete secret from disk")
      
      let textfield = EditableNSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 19))
      textfield.alignment = .center
      textfield.placeholderString = "AADEM4YUY5GYZHHP"
      textfield.maximumNumberOfLines = 1;
      textfield.isBordered = false
      textfield.font = .systemFont(ofSize: 16)
      textfield.backgroundColor = .windowBackgroundColor
      alert.accessoryView = textfield
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        textfield.becomeFirstResponder()
      }
      
      let previousSecret = currentlySelectedInstance.secret
      if !previousSecret.isEmpty {
        textfield.stringValue = previousSecret
      }
      
      let response = alert.runModal()
      if response == .alertFirstButtonReturn {
//        print("Pressed OK")
        let value = textfield.stringValue
        if value.isEmpty {
//          print("Entered value is empty")
          self.removeInstance(currentlySelectedInstance)
        } else {
          currentlySelectedInstance.secret = value.condenseWhitespace()
        }
      } else if response == .alertSecondButtonReturn {
//        print("Pressed Cancel")
        if currentlySelectedInstance.secret.isEmpty {
          self.removeInstance(currentlySelectedInstance)
        }
      } else if response == .alertThirdButtonReturn {
//        print("Pressed Delete secret")
        currentlySelectedInstance.secret = ""
        currentlySelectedInstance.token = ""
        currentlySelectedInstance.button?.toolTip = ""
        self.removeInstance(currentlySelectedInstance)
      }
      self.reinitializeKeychain()
      self.initializeInstances()
    }
    
    let (paddle, paddleProduct) = initializePaddle()
    if paddleProduct!.activated {
      theShow()
    } else {
      if Int(truncating: (paddleProduct?.trialDaysRemaining)!) > 0 {
        theShow()
      } else {
        paddle?.showProductAccessDialog(with: paddleProduct!)
      }
    }
  }
  
  func removeInstance(_ instance: OTP) {
    if (instance.displayItem != nil) {
      statusMenu.removeItem(instance.displayItem!)
    }
    otpInstances.remove(at: currentlySelectedSeed)
  }
  
  func reinitializeKeychain() {
    var secrets: [String] = []
    
//    print("QTY of instances: \(otpInstances.count)")
    
    if otpInstances.isEmpty {
//      print("otpInstances is Empty")
    } else {
      for inst in otpInstances {
        if inst.secret.isEmpty {
          removeInstance(inst)
//          print("removed an instance due to empty secret")
        } else {
          secrets.append(inst.secret)
        }
      }
      print(secrets)
    }
    
    do {
      if secrets.count == 0 {
        do {
          try keychain.remove("secret")
//          print("removed keychain item")
        } catch let error {
          print("error: \(error)")
        }
        return
      }
      let stringified = try JSONStringify(value: secrets).stringify()
      print(stringified)
      do {
        try keychain
          .synchronizable(true)
          .accessibility(.afterFirstUnlock)
          .set(stringified, key: "secret")
      } catch let error {
        print("error: \(error)")
      }
    } catch let error { print(error) }
  }
  
  class mouseHandlerView: NSView {
    
    var onLeftMouseDown: (()->())? = nil
    
    override func mouseDown(with event: NSEvent) {
      onLeftMouseDown == nil ? super.mouseDown(with: event) : onLeftMouseDown!()
    }
    
    var onRightMouseDown: (()->())? = nil
    
    override func rightMouseDown(with event: NSEvent) {
      onRightMouseDown == nil ? super.rightMouseDown(with: event) : onRightMouseDown!()
    }
    
    var onOtherMouseDown: (()->())? = nil
    
    override func otherMouseDown(with event: NSEvent) {
      onOtherMouseDown == nil ? super.otherMouseDown(with: event) : onOtherMouseDown!()
    }
    
  }
  
  @objc func tokenDisplayClicked(_ sender: NSMenuItem) {
    currentlySelectedSeed = statusMenu.index(of: sender) - 1
    if !otpInstances.isEmpty {
      for instance in otpInstances {
        if (instance.displayItem != nil) {
          instance.displayItem?.state = .off
        }
      }
    }
    sender.state.toggle()
    otpInstances[currentlySelectedSeed].copy()
  }
  
  func initializeInstances() {
    for instance in otpInstances {
      if (instance.displayItem != nil) {
        statusMenu.removeItem(instance.displayItem!)
      }
    }
    otpInstances.removeAll()
//    print("Removed all instances")
    
    let secrets = keychain["secret"]
    if secrets == nil {
//      print("Keychain 'secret' is empty")
      if let button = statusItem.button {
        button.appearsDisabled = true
      }
      return
    }
    if let datan = secrets?.decodeUrl().data(using: String.Encoding.utf8) {
//      print("Initializing instances from keychain")
      if let jsonc = datan.dataToJSON() {
        let dataArray = (jsonc as! NSArray) as Array
//        print("Stored secrets already: \(dataArray.count)")
        
        var newInstIndex = 0
        
        for secret in dataArray {
//          print("\(secret) will be initialized")
          let theSecret = (secret as! String).condenseWhitespace()
          
          let newOtpInstance = OTP()
          newOtpInstance.secret = theSecret
          
          newOtpInstance.button = statusItem.button
          
          let newTokenDisplay = NSMenuItem()
          statusMenu.insertItem(newTokenDisplay, at: newInstIndex + 1)
          newTokenDisplay.isEnabled = true
          newTokenDisplay.isHidden = false
          newTokenDisplay.target = self
          newTokenDisplay.action = #selector(tokenDisplayClicked(_:))
          newOtpInstance.displayItem = newTokenDisplay
          
          newOtpInstance.start()
          otpInstances.append(newOtpInstance)
          newInstIndex += 1
        }
        
      }
    }
    reinitializeStates(currentlySelectedSeed)
  }
  
  override func awakeFromNib() {
    defaults.removeObject(forKey: "secret")
    statusItem.menu = statusMenu
    statusMenu.delegate = self
    statusItem.isVisible = true
    
    if let button = statusItem.button {
      let statusIcon = resize(image: NSImage(named: "StatusIcon")!, w: 22, h: 22)
      statusIcon.isTemplate = true
      button.image = statusIcon.rotatedZ(5)
      button.target = self
      
      
      initializeInstances()
      
      if otpInstances.isEmpty {
        tryToAddInstance()
      }
      
      
      let mouseView = mouseHandlerView(frame: button.frame)
      
      let doubleClickAction = {
        if defaults.bool(forKey: "pasteOnDoubleClick") {
          clipboard.paste()
          self.enterAfterAutoPaste()
        } else {
          self.showAlert()
        }
      }
      
      mouseView.onLeftMouseDown = {
        if otpInstances.isEmpty {
          self.tryToAddInstance()
          return
        }
        button.highlight(true)
        otpInstances[currentlySelectedSeed].copy()
        if defaults.bool(forKey: "pasteOnClick") {
          clipboard.paste()
          self.enterAfterAutoPaste()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          button.highlight(false)
        }
        if (NSApp.currentEvent?.clickCount == 2) {
          doubleClickAction()
        }
      }
      
      mouseView.onRightMouseDown = {
        let (paddle, paddleProduct) = initializePaddle()
        if paddleProduct!.activated {
          button.performClick(NSApp.currentEvent)
        } else {
          if Int(truncating: (paddleProduct?.trialDaysRemaining)!) > 0 {
            button.performClick(NSApp.currentEvent)
          } else {
            paddle?.showProductAccessDialog(with: paddleProduct!)
          }
        }
      }
      
      button.addSubview(mouseView)
      
      let hotKey = HotKey(key: .g, modifiers: [.command, .option])
      hotKey.handleKeyDown {
        otpInstances[currentlySelectedSeed].copy()
        if defaults.bool(forKey: "pasteOnHotkey") {
          clipboard.paste()
          self.enterAfterAutoPaste()
        }
      }
    }
    
    permissionsButton.toolTip = "Open Accessibility Preferences"
    hotkeyButton.toolTip = "⌥⌘G"
  }
  
  func tryToAddInstance() {
    let newInstance = OTP()
    newInstance.button = statusItem.button
    newInstance.start()
    otpInstances.append(newInstance)
    currentlySelectedSeed = otpInstances.count - 1
    showAlert()
  }
  
  @IBAction func copyTokenClicked(_ sender: NSMenuItem) {
    if otpInstances.isEmpty {
      return
    }
    otpInstances[currentlySelectedSeed].copy()
  }
  @IBAction func pasteTokenClicked(_ sender: NSMenuItem) {
    if otpInstances.isEmpty {
      return
    }
    otpInstances[currentlySelectedSeed].copy()
    clipboard.paste()
  }
  @IBAction func addNewClicked(_ sender: NSMenuItem) {
    tryToAddInstance()
  }
  
  func enterAfterAutoPaste() {
    if !defaults.bool(forKey: "enterAfterAutoPaste") {
      return
    }
    if !AXIsProcessTrusted() {
      return
    }
    clipboard.checkAccessibilityPermissions()
    
    DispatchQueue.main.async {
      let keyCode = UInt16(kVK_Return)
      let source = CGEventSource(stateID: .combinedSessionState)
      // Disable local keyboard events while pasting
      source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents],
                                                         state: .eventSuppressionStateSuppressionInterval)
      
      let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
      keyDown?.flags = .maskCommand
      keyUp?.flags = .maskCommand
      keyDown?.post(tap: .cgAnnotatedSessionEventTap)
      keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
  }
  
  @IBOutlet weak var hotkeyButton: NSMenuItem!
  @IBAction func hotkeyButtonClicked(_ sender: NSMenuItem) {
    defaults.boolToggle("pasteOnHotkey")
  }
  
  @IBOutlet weak var pasteOnClickButton: NSMenuItem!
  @IBAction func pasteOnClickButtonClicked(_ sender: NSMenuItem) {
    defaults.boolToggle("pasteOnClick")
    if defaults.bool(forKey: "pasteOnDoubleClick") {
      defaults.boolToggle("pasteOnDoubleClick")
    }
  }
  
  @IBOutlet weak var permissionsButton: NSMenuItem!
  @IBAction func permissionsButtonClicked(_ sender: NSMenuItem) {
    let prefpaneUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(prefpaneUrl)
  }
  
  @IBOutlet weak var pasteOnDoubleClickButton: NSMenuItem!
  @IBAction func pasteOnDoubleClickButtonClicked(_ sender: NSMenuItem) {
    defaults.boolToggle("pasteOnDoubleClick")
    if defaults.bool(forKey: "pasteOnClick") {
      defaults.boolToggle("pasteOnClick")
    }
  }
  
  @IBOutlet weak var launchAtLoginButton: NSMenuItem!
  @IBAction func launchAtLoginClicked(_ sender: NSMenuItem) {
    if LoginServiceKit.isExistLoginItems() {
      LoginServiceKit.removeLoginItems()
    } else {
      LoginServiceKit.addLoginItems()
    }
  }
  
  @IBOutlet weak var enterAfterAutoPasteButton: NSMenuItem!
  @IBAction func enterAfterAutoPasteClicked(_ sender: NSMenuItem) {
    defaults.boolToggle("enterAfterAutoPaste")
//    print("switched enterAfterAutoPaste pref")
  }
  
  func menuNeedsUpdate(_ menu: NSMenu) {
    launchAtLoginButton.state.by(LoginServiceKit.isExistLoginItems())
    hotkeyButton.state.by(defaults.bool(forKey: "pasteOnHotkey"))
    pasteOnClickButton.state.by(defaults.bool(forKey: "pasteOnClick"))
    pasteOnDoubleClickButton.state.by(defaults.bool(forKey: "pasteOnDoubleClick"))
    enterAfterAutoPasteButton.state.by(defaults.bool(forKey: "enterAfterAutoPaste"))
    
    let isProcessTrusted = AXIsProcessTrusted()
    permissionsButton.isHidden = isProcessTrusted
    hotkeyButton.isEnabled = isProcessTrusted
    pasteOnClickButton.isEnabled = isProcessTrusted
    pasteOnDoubleClickButton.isEnabled = isProcessTrusted
    enterAfterAutoPasteButton.isEnabled = isProcessTrusted
  }
}

enum StringifyError: Error {
  case isNotValidJSONObject
}

struct JSONStringify {
  
  let value: Any
  
  func stringify(prettyPrinted: Bool = false) throws -> String {
    let options: JSONSerialization.WritingOptions = prettyPrinted ? .prettyPrinted : .init(rawValue: 0)
    if JSONSerialization.isValidJSONObject(self.value) {
      let data = try JSONSerialization.data(withJSONObject: self.value, options: options)
      if let string = String(data: data, encoding: .utf8) {
        return string
        
      }
    }
    throw StringifyError.isNotValidJSONObject
  }
}
protocol Stringifiable {
  func stringify(prettyPrinted: Bool) throws -> String
}

extension Stringifiable {
  func stringify(prettyPrinted: Bool = false) throws -> String {
    return try JSONStringify(value: self).stringify(prettyPrinted: prettyPrinted)
  }
}

extension Dictionary: Stringifiable {}
extension Array: Stringifiable {}

extension String
{
  func decodeUrl() -> String
  {
    return self.removingPercentEncoding!
  }
}

extension Data
{
  func dataToJSON() -> Any? {
    do {
      return try JSONSerialization.jsonObject(with: self, options: [])
    } catch let myJSONError {
      print(myJSONError)
    }
    return nil
  }
}
