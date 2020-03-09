import Cocoa

class MouseHandlerView: NSView {
  
  var onLeftMouseDown: (()->())? = nil
  
  override func mouseDown(with event: NSEvent) {
    onLeftMouseDown == nil ? super.mouseDown(with: event) : onLeftMouseDown!()
  }
  
  var onLeftMouseUp: (()->())? = nil
   
  override func mouseUp(with event: NSEvent) {
    onLeftMouseUp == nil ? super.mouseUp(with: event) : onLeftMouseUp!()
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
