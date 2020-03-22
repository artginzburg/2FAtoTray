import Cocoa
import JavaScriptCore

class OTP {
  
  private var fn:JSValue?
  private var timer:Timer?
  var token:String
  var button:NSStatusBarButton?
  var displayItem:NSMenuItem?
  var secret:String
  var name:String
  var digits:Int
  
  init() {
    fn = nil
    button = nil
    displayItem = nil
    timer = nil
    secret = ""
    name = ""
    digits = 6
    token = ""
  }
  
  func start() {
    let bundle = Bundle.main
    let path = bundle.path(forResource: "totp", ofType: "js")!
    let jsSource = try? String.init(contentsOfFile: path)
    let context = JSContext()!
    context.evaluateScript(jsSource)
    fn = context.objectForKeyedSubscript("otp")
    timer = nil
    token = ""
    updateTimer()
    initTimer()
  }
  
  func updateTimer() {
    if self.secret != "" {
      let result = self.fn!.call(withArguments: [self.secret, self.digits])
      let token = result!.toString()!
      if self.token != token {
        self.token = token
        self.button?.toolTip = token
        self.button?.appearsDisabled = false
        let showNames = defaults.bool(forKey: "showNames")
        self.displayItem?.title = showNames ? "\(token) · \(self.name)" : token
        self.displayItem?.isHidden = false
        self.displayItem?.isEnabled = true
      }
    }
  }
  
  func initTimer() {
    self.timer = Timer.new(every: 1.second) {
      self.updateTimer()
    }
    self.timer!.start()
  }
  
  func copy() {
    Clipboard.shared.copy(self.token)
    print("copied the token")
  }
}
