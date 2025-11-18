#if swift(>=6.2)
  import CustomDump

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  func expectElementsAreEqual<let count: Int>(_ lhs: [count of Float], _ rhs: [count of Float]) {
    var a1 = [Float]()
    var a2 = [Float]()
    for i in 0..<count {
      a1.append(lhs[i])
      a2.append(rhs[i])
    }
    expectNoDifference(a1, a2)
  }
#endif
