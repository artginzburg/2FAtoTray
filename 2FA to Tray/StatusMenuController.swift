//
//  StatusMenuController.swift
//  2FA to Tray
//
//  Created by Arthur Ginzburg on 26.01.2020.
//  Copyright © 2020 DaFuqtor. All rights reserved.
//

import Cocoa

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
  
  @IBAction func changeSecret(_ sender: Any) {
    otp.showAlert()
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
  
  override func awakeFromNib() {
    UserDefaults.standard.removeObject(forKey: "secret")
    statusItem.menu = statusMenu
    statusMenu.delegate = self
    statusItem.isVisible = true
    if let button = statusItem.button {
      let statusIcon = resize(image: NSImage(named: "StatusIcon")!, w: 22, h: 22)
      statusIcon.isTemplate = true
      button.image = statusIcon
      button.target = self
      otp.button = button
      
      let secret = keychain["secret"]?.condenseWhitespace() ?? ""
      if secret.isEmpty {
        button.appearsDisabled = true
        otp.showAlert()
      } else {
        otp.secret = secret
      }
      otp.start()
      
      if UserDefaults.standard.bool(forKey: "instantMode") {
        otp.copy()
        NSApplication.shared.terminate(self)
      }
      
      let mouseView = mouseHandlerView(frame: button.frame)

      mouseView.onLeftMouseDown = {
        button.highlight(true)
        otp.copy()
        if defaults.bool(forKey: "pasteOnClick") {
          clipboard.paste()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          button.highlight(false)
        }
        if (NSApp.currentEvent?.clickCount == 2) {
//          print("Doubleclick")
          if defaults.bool(forKey: "pasteOnDoubleClick") && AXIsProcessTrusted() {
            clipboard.paste()
          } else {
            otp.showAlert()
          }
        }
      }

      mouseView.onRightMouseDown = {
        button.performClick(NSApp.currentEvent)
      }

      button.addSubview(mouseView)
      
      let hotKey = HotKey(key: .g, modifiers: [.command, .option])
      hotKey.handleKeyDown {
        otp.copy()
        if defaults.bool(forKey: "pasteOnHotkey") {
          clipboard.paste()
        }
      }
    }
  }
  
  @IBOutlet weak var tokenDisplay: NSMenuItem!
  @IBAction func tokenDisplayClicked(_ sender: NSMenuItem) {
    otp.copy()
  }
  @IBAction func pasteTokenClicked(_ sender: NSMenuItem) {
    otp.copy()
    clipboard.paste()
  }
  
  @IBOutlet weak var hotkeyButton: NSMenuItem!
  @IBAction func hotkeyButtonClicked(_ sender: NSMenuItem) {
    defaults.toggleBool("pasteOnHotkey")
  }
  
  @IBOutlet weak var pasteOnClickButton: NSMenuItem!
  @IBAction func pasteOnClickButtonClicked(_ sender: NSMenuItem) {
    defaults.toggleBool("pasteOnClick")
    if defaults.bool(forKey: "pasteOnDoubleClick") {
      defaults.toggleBool("pasteOnDoubleClick")
    }
  }
  
  @IBOutlet weak var permissionsButton: NSMenuItem!
  @IBAction func permissionsButtonClicked(_ sender: NSMenuItem) {
    clipboard.checkAccessibilityPermissions()
  }
  
  @IBOutlet weak var pasteOnDoubleClickButton: NSMenuItem!
  @IBAction func pasteOnDoubleClickButtonClicked(_ sender: NSMenuItem) {
    defaults.toggleBool("pasteOnDoubleClick")
    if defaults.bool(forKey: "pasteOnClick") {
      defaults.toggleBool("pasteOnClick")
    }
  }
  
  
  func menuNeedsUpdate(_ menu: NSMenu) {
    let tokenExists = !otp.token.isEmpty
    if tokenExists {
      tokenDisplay.title = otp.token
    }
    tokenDisplay.isHidden = !tokenExists
    tokenDisplay.isEnabled = tokenExists
    
    hotkeyButton.stateBy(defaults.bool(forKey: "pasteOnHotkey"))
    pasteOnClickButton.stateBy(defaults.bool(forKey: "pasteOnClick"))
    pasteOnDoubleClickButton.stateBy(defaults.bool(forKey: "pasteOnDoubleClick"))
    
    let isProcessTrusted = AXIsProcessTrusted()
    permissionsButton.isHidden = isProcessTrusted
    hotkeyButton.isEnabled = isProcessTrusted
    pasteOnClickButton.isEnabled = isProcessTrusted
    pasteOnDoubleClickButton.isEnabled = isProcessTrusted
  }
}
