import Cocoa

extension NSStatusBarButton {
  
  func momentaryHighlight() {
    self.highlight(true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.highlight(false)
    }
  }
  
}
