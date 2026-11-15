import CustomDump
import StructuredQueriesVectorCore
import Testing

@Suite
struct `VectorScalar tests` {
  @Test
  func `Preserves IEEE Bits In Raw Payloads`() throws {
    // Independent little-endian fixtures include signed zero, subnormals, infinities, and NaNs.
    let floatBits: [UInt32] = [0x8000_0000, 1, 0x7f80_0000, 0x7f80_0123]
    let doubleBits: [UInt64] = [
      0x8000_0000_0000_0000, 1, 0x7ff0_0000_0000_0000, 0x7ff0_0000_0000_0123
    ]
    let floatBytes: [UInt8] = [0, 0, 0, 128, 1, 0, 0, 0, 0, 0, 128, 127, 35, 1, 128, 127]
    let doubleBytes: [UInt8] = [
      0, 0, 0, 0, 0, 0, 0, 128, 1, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 240, 127, 35, 1, 0, 0, 0, 0, 240, 127
    ]
    expectNoDifference(
      [Float].VectorBytesRepresentation(queryOutput: floatBits.map { Float(bitPattern: $0) })
        .queryBinding,
      .blob(floatBytes)
    )
    expectNoDifference(
      [Double].VectorBytesRepresentation(queryOutput: doubleBits.map { Double(bitPattern: $0) })
        .queryBinding,
      .blob(doubleBytes)
    )
    expectNoDifference(try [Float](vectorBytes: floatBytes).map(\.bitPattern), floatBits)
    expectNoDifference(try [Double](vectorBytes: doubleBytes).map(\.bitPattern), doubleBits)
  }

  @Test
  func `Rejects Incomplete Raw Components`() {
    #expect(
      throws: VectorDecodingError.invalidBytes(
        reason: "Expected a multiple of 4 bytes for Float components, found 3."
      )
    ) {
      try Float.decodeVector([0, 0, 0])
    }
    #expect(
      throws: VectorDecodingError.invalidBytes(
        reason: "Expected a multiple of 8 bytes for Double components, found 7."
      )
    ) {
      try Double.decodeVector([UInt8](repeating: 0, count: 7))
    }
  }

  #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test
    func `Preserves IEEE Bits In Raw Float16 Payloads`() throws {
      let halfBits: [UInt16] = [0x8000, 1, 0x7c00, 0x7c01]
      let halfBytes: [UInt8] = [0, 128, 1, 0, 0, 124, 1, 124]
      expectNoDifference(
        [Float16].VectorBytesRepresentation(queryOutput: halfBits.map { Float16(bitPattern: $0) })
          .queryBinding,
        .blob(halfBytes)
      )
      expectNoDifference(try [Float16](vectorBytes: halfBytes).map(\.bitPattern), halfBits)
    }

    @Test
    func `Rejects Incomplete Raw Float16 Components`() {
      #expect(
        throws: VectorDecodingError.invalidBytes(
          reason: "Expected a multiple of 2 bytes for Float16 components, found 1."
        )
      ) {
        try Float16.decodeVector([0])
      }
    }
  #endif
}
