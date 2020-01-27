//
//  StatusMenuController.swift
//  2FA to Tray
//
//  Created by Arthur Ginzburg on 26.01.2020.
//  Copyright © 2020 DaFuqtor. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
  
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
    self.otp.showAlert()
  }
  
  let statusItem = NSStatusBar.system.statusItem(withLength: 22)
  
  let otp = OTP()
  
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
    statusItem.menu = statusMenu
    statusItem.isVisible = true
    if let button = statusItem.button {
      let statusIcon = resize(image: NSImage(named: "StatusIcon")!, w: 20, h: 20)
      statusIcon.isTemplate = true
      button.image = statusIcon
      button.target = self
      otp.button = button
      
      let secret = UserDefaults.standard.string(forKey: "secret")?.condenseWhitespace() ?? ""
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
        self.otp.copy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          button.highlight(false)
        }
        if (NSApp.currentEvent?.clickCount == 2) {
          print("Doubleclick")
          self.otp.showAlert()
        }
      }

      mouseView.onRightMouseDown = {
        button.performClick(NSApp.currentEvent)
      }

      button.addSubview(mouseView)
    }
  }
  
  func menuNeedsUpdate(_ menu: NSMenu) {
    
  }
}
