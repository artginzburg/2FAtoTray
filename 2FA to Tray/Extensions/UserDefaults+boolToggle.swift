import Cocoa

extension UserDefaults {
  
  func boolToggle(_ forKey: String) {
    set(!bool(forKey: forKey), forKey: forKey)
  }
  
}
