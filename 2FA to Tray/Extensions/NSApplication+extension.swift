import Cocoa

extension NSApplication {
  var isLeftMouseDown: Bool { currentEvent?.type == .leftMouseDown }
  var isOptionKeyDown: Bool { NSEvent.modifierFlags.contains(.option) }
  var isCommandKeyDown: Bool { NSEvent.modifierFlags.contains(.command) }
  var isShiftKeyDown: Bool { NSEvent.modifierFlags.contains(.shift) }
}
