import Cocoa

final class EditableNSTextField: NSTextField {
  
  private let commandKey = NSEvent.ModifierFlags.command.rawValue
  private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
  
  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.type == NSEvent.EventType.keyDown {
      if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
        
        var action: Selector?
        
        switch event.charactersIgnoringModifiers! {
          case "x":
            action = #selector(NSText.cut(_:))
          case "c":
            action = #selector(NSText.copy(_:))
          case "v":
            action = #selector(NSText.paste(_:))
          case "z":
            action = Selector(("undo:"))
          case "a":
            action = #selector(NSResponder.selectAll(_:))
          default:
            break
        }
        
        if NSApp.sendAction(action!, to: nil, from: self) { return true }
        
      } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
        if event.charactersIgnoringModifiers == "Z" {
          if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) { return true }
        }
      }
    }
    return super.performKeyEquivalent(with: event)
  }
}
