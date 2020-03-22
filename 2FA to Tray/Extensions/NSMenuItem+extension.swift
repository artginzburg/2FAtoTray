import Cocoa

extension NSMenuItem {
  
  func hideKeyEquivalent() {
    let newMenuItem: NSMenuItem = copy() as! NSMenuItem
    newMenuItem.allowsKeyEquivalentWhenHidden = true
    newMenuItem.isHidden = true
    keyEquivalent = ""
    keyEquivalentModifierMask = []
    menu?.addItem(newMenuItem)
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
