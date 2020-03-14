import Cocoa

extension NSApplication {
  var isLeftMouseDown: Bool { currentEvent?.type == .leftMouseDown }
  var isOptionKeyDown: Bool { NSEvent.modifierFlags.contains(.option) }
  var isCommandKeyDown: Bool { NSEvent.modifierFlags.contains(.command) }
  var isShiftKeyDown: Bool { NSEvent.modifierFlags.contains(.shift) }
}

extension NSMenuItem {
  
  func hideKeyEquivalent() {
    let newMenuItem: NSMenuItem = self.copy() as! NSMenuItem
    newMenuItem.allowsKeyEquivalentWhenHidden = true
    newMenuItem.isHidden = true
    keyEquivalent = ""
    keyEquivalentModifierMask = []
    menu?.addItem(newMenuItem)
    print(self.title)
    print("hidden key eq")
  }
  func addHiddenKeyEquivalent(_ equivalent: String = "", _ modifiers: NSEvent.ModifierFlags = []) {
    let oldKeyEquivalent = keyEquivalent
    let oldKeyEquivalentModifierMask = keyEquivalentModifierMask
    keyEquivalent = equivalent
    keyEquivalentModifierMask = modifiers
    hideKeyEquivalent()
    keyEquivalent = oldKeyEquivalent
    keyEquivalentModifierMask = oldKeyEquivalentModifierMask
  }
  
}
