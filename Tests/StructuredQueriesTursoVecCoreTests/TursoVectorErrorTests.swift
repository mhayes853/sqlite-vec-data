import CustomDump
import StructuredQueriesTursoVecCore
import Testing

@Suite
struct `TursoVectorError tests` {
  @Test(arguments: ["invalidQuantization", "invalidSparseComponents", "futureValidation"])
  func `Preserves Known And Unknown Raw Codes`(rawValue: String) {
    let code = TursoVectorError.Code(rawValue: rawValue)
    expectNoDifference(code.rawValue, rawValue)
    expectNoDifference(code, TursoVectorError.Code(rawValue: rawValue))
    expectNoDifference(Set([code, TursoVectorError.Code(rawValue: rawValue)]).count, 1)
    switch code {
    case .invalidQuantization:
      expectNoDifference(rawValue, "invalidQuantization")
    case .invalidSparseComponents:
      expectNoDifference(rawValue, "invalidSparseComponents")
    default:
      expectNoDifference(rawValue, "futureValidation")
    }
  }

  @Test
  func `Keeps Diagnostic Reasons Separate From Codes`() {
    let inputError = TursoVectorError(
      code: .invalidQuantization,
      reason: "The input is not finite."
    )
    let scaleError = TursoVectorError(
      code: .invalidQuantization,
      reason: "The scale is negative."
    )
    expectNoDifference(inputError.code, scaleError.code)
    expectNoDifference(inputError.reason, "The input is not finite.")
    expectNoDifference(String(describing: inputError), inputError.reason)
    expectNoDifference(inputError == scaleError, false)
  }

  @Test
  func `Reports A Reason For Invalid Quantization Input`() {
    let error = #expect(throws: TursoVectorError.self) {
      try Quantized8Vector(quantizing: [1, .nan])
    }
    expectNoDifference(error?.code, .invalidQuantization)
    expectNoDifference(error?.reason, "Quantization input values must be finite.")
  }
}
