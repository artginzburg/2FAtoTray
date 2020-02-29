import Cocoa

extension NSControl.StateValue {
  
  mutating func toggle() {
    self = (self == .on) ? .off : .on
  }
  mutating func by(_ bool: Bool) {
    self = bool ? .on : .off
  }
  
}
