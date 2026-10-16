import CustomDump
import StructuredQueriesVectorCore
import Testing

@Suite
struct `VectorScalar tests` {
  @Test
  func `Preserves IEEE Bits In Raw Payloads`() throws {
    // Independent little-endian fixtures include signed zero, subnormals, infinities, and NaNs.
    let halfBits: [UInt16] = [0x8000, 1, 0x7c00, 0x7c01]
    let halfBytes: [UInt8] = [0, 128, 1, 0, 0, 124, 1, 124]
    expectNoDifference(
      [Float16].VectorBytesRepresentation(queryOutput: halfBits.map { Float16(bitPattern: $0) })
        .queryBinding,
      .blob(halfBytes)
    )
    expectNoDifference(try [Float16](vectorBytes: halfBytes).map(\.bitPattern), halfBits)
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
    #expect(throws: VectorDecodingError.invalidBytes) { try Float16.decodeVector([0]) }
    #expect(throws: VectorDecodingError.invalidBytes) { try Float.decodeVector([0, 0, 0]) }
    #expect(throws: VectorDecodingError.invalidBytes) {
      try Double.decodeVector([UInt8](repeating: 0, count: 7))
    }
  }
}
