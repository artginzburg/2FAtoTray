extension String {
  
  func condenseWhitespace() -> String {
    self.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
  }
  
}
