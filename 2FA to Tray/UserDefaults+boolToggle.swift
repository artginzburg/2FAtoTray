import Cocoa

extension UserDefaults {
  
  func boolToggle(_ forKey: String) {
    self.set(!self.bool(forKey: forKey), forKey: forKey)
  }
  
}
