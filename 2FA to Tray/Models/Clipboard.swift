import AppKit
import Carbon

class Clipboard {
  public static let shared = Clipboard()
  private let pasteboard = NSPasteboard.general
  
  var preservedString: String?
  
  func get() -> [NSPasteboardItem]? {
    pasteboard.pasteboardItems
  }
  
  func copy(_ string: String) {
    pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
    pasteboard.setString(string, forType: NSPasteboard.PasteboardType.string)
  }
  
  func paste() {
    checkAccessibilityPermissions()
    if !AXIsProcessTrusted() {
      return
    }
    
    DispatchQueue.main.async {
      let vCode = UInt16(kVK_ANSI_V)
      let source = CGEventSource(stateID: .combinedSessionState)
      // Disable local keyboard events while pasting
      source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents],
                                                         state: .eventSuppressionStateSuppressionInterval)
      
      let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: true)
      let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: false)
      keyVDown?.flags = .maskCommand
      keyVUp?.flags = .maskCommand
      keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
      keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      if defaults.bool(forKey: "preserveClipboard") {
        if let item = self.preservedString {
          self.copy(item)
        }
      }
    }
  }
  
  func checkAccessibilityPermissions() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
    AXIsProcessTrustedWithOptions(options)
  }
}
