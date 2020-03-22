extension String {
  
  func condenseWhitespace() -> String {
    components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
  }
  
}
