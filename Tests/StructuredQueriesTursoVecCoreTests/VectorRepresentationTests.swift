import CustomDump
import Foundation
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore
import Testing

@Suite
struct `Vector Representation tests` {
  @Test
  func `Stores The Documented Sparse Values Indices And Dimensions`() throws {
    // https://docs.turso.tech/sql-reference/functions/vector#vector32-sparse
    // Layout: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/vector_types.rs#L315
    // Serialization: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs#L15
    let vector: [Float].SparseRepresentation = [0, 0, 1.5, 0, 0, 2.5]
    let fixture: [UInt8] = [
      0, 0, 192, 63, 0, 0, 32, 64,
      2, 0, 0, 0, 5, 0, 0, 0,
      6, 0, 0, 0, 9
    ]
    expectNoDifference(vector.queryBinding, .blob(fixture))
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(try decoder.decode([Float].SparseRepresentation.self), vector.queryOutput)
  }

  @Test
  func `Preserves Sparse Dimensions When Every Value Is Zero`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs#L15
    let zero: [Float].SparseRepresentation = [0, -0.0, 0, 0]
    expectNoDifference(zero.queryBinding, .blob([4, 0, 0, 0, 9]))
    var decoder = BlobQueryDecoder(bytes: [4, 0, 0, 0, 9])
    expectNoDifference(
      try decoder.decode([Float].SparseRepresentation.self)?.map(\.bitPattern),
      [UInt32](repeating: 0, count: 4)
    )
    let empty = [Float].SparseRepresentation(queryOutput: [Float]())
    expectNoDifference(empty.queryBinding, .blob([0, 0, 0, 0, 9]))
    var emptyDecoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 9])
    expectNoDifference(try emptyDecoder.decode([Float].SparseRepresentation.self), [Float]())
  }

  @Test
  func `Preserves Nonzero Sparse IEEE Bit Patterns`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/convert.rs#L19
    let bits: [UInt32] = [0, 1, 0, 0x7f80_0123]
    let vector = [Float].SparseRepresentation(queryOutput: bits.map { Float(bitPattern: $0) })
    let fixture: [UInt8] = [
      1, 0, 0, 0, 35, 1, 128, 127,
      1, 0, 0, 0, 3, 0, 0, 0,
      4, 0, 0, 0, 9
    ]
    expectNoDifference(vector.queryBinding, .blob(fixture))
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(
      try decoder.decode([Float].SparseRepresentation.self)?.map(\.bitPattern),
      bits
    )
  }

  @Test(arguments: [
    [UInt8](), [9], [0, 0, 0, 0, 1], [0, 0, 0, 9],
    [0, 0, 128, 63, 3, 0, 0, 0, 3, 0, 0, 0, 9],
    [0, 0, 128, 63, 0, 0, 0, 0, 0, 0, 0, 0, 9],
    [0, 0, 128, 63, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 9],
    [0, 0, 128, 63, 0, 0, 0, 64, 2, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 9]
  ])
  func `Rejects Malformed Sparse Lengths Tags And Indices`(_ fixture: [UInt8]) {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/vector_types.rs#L315
    // Validate the sorted, unique, in-range indices required by sparse operations.
    var decoder = BlobQueryDecoder(bytes: fixture)
    #expect(throws: VectorDecodingError.invalidBytes) {
      _ = try [Float].SparseRepresentation(decoder: &decoder)
    }
  }

  #if swift(>=6.2)
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Validates Fixed Sparse Dimensions`() throws {
      // https://docs.turso.tech/sql-reference/functions/vector#vector32-sparse
      let vector = EmbeddingVector<6>
        .SparseRepresentation(
          queryOutput: EmbeddingVector<6>([0, 0, 1.5, 0, 0, 2.5])
        )
      let fixture: [UInt8] = [
        0, 0, 192, 63, 0, 0, 32, 64,
        2, 0, 0, 0, 5, 0, 0, 0,
        6, 0, 0, 0, 9
      ]
      expectNoDifference(vector.queryBinding, .blob(fixture))
      var decoder = BlobQueryDecoder(bytes: fixture)
      expectNoDifference(
        try decoder.decode(EmbeddingVector<6>.SparseRepresentation.self),
        vector.queryOutput
      )
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 5, actual: 6)) {
        _ = try EmbeddingVector<5>.SparseRepresentation(decoder: &decoder)
      }
    }
  #endif

  @Test
  func `Uses Little Endian IEEE Bytes And Precision Tags`() throws {
    // https://docs.turso.tech/guides/vector-search#vector-types
    // Wire format: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    let floats: [Float].VectorBytesRepresentation = [1, -2]
    let doubles: [Double].VectorBytesRepresentation = [1, -2]
    let floatBytes: [UInt8] = [0, 0, 128, 63, 0, 0, 0, 192]
    let doubleBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 192, 2]
    expectNoDifference(floats.queryBinding, .blob(floatBytes))
    expectNoDifference(doubles.queryBinding, .blob(doubleBytes))

    var floatDecoder = BlobQueryDecoder(bytes: floatBytes)
    var doubleDecoder = BlobQueryDecoder(bytes: doubleBytes)
    expectNoDifference(try floatDecoder.decode([Float].VectorBytesRepresentation.self), [1, -2])
    expectNoDifference(try doubleDecoder.decode([Double].VectorBytesRepresentation.self), [1, -2])
  }

  @Test
  func `Preserves IEEE Bit Patterns Through Scalar Dispatch`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    // Signed zero, the least subnormal, infinity, and a signaling NaN retain their IEEE bits.
    let floatBits: [UInt32] = [0x8000_0000, 1, 0x7f80_0000, 0x7f80_0123]
    let doubleBits: [UInt64] = [
      0x8000_0000_0000_0000, 1, 0x7ff0_0000_0000_0000, 0x7ff0_0000_0000_0123
    ]
    let floatBytes: [UInt8] = [0, 0, 0, 128, 1, 0, 0, 0, 0, 0, 128, 127, 35, 1, 128, 127]
    let doubleBytes: [UInt8] = [
      0, 0, 0, 0, 0, 0, 0, 128, 1, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 240, 127, 35, 1, 0, 0, 0, 0, 240, 127, 2
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
    var floatDecoder = BlobQueryDecoder(bytes: floatBytes)
    var doubleDecoder = BlobQueryDecoder(bytes: doubleBytes)
    expectNoDifference(
      try floatDecoder.decode([Float].VectorBytesRepresentation.self)?.map(\.bitPattern),
      floatBits
    )
    expectNoDifference(
      try doubleDecoder.decode([Double].VectorBytesRepresentation.self)?.map(\.bitPattern),
      doubleBits
    )
  }

  @Test
  func `Accepts The Optional Turso Float32 Tag`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/vector_types.rs
    var decoder = BlobQueryDecoder(bytes: [0, 0, 128, 63, 1])
    expectNoDifference(try decoder.decode([Float].VectorBytesRepresentation.self), [1])
  }

  @Test
  func `Quantizes Float8 With Scale Shift And Rounded Bytes`() throws {
    // https://docs.turso.tech/guides/vector-search#vector-types
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/convert.rs
    // For [0, 127.5, 255], scale = 1 and shift = 0; Turso rounds the midpoint to 128.
    let vector: [Float].Float8Representation = [0, 127.5, 255]
    let fixture: [UInt8] = [0, 128, 255, 0, 0, 0, 128, 63, 0, 0, 0, 0, 0, 1, 4]
    expectNoDifference(vector.queryBinding, .blob(fixture))
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(try decoder.decode([Float].Float8Representation.self), [0, 128, 255])
  }

  @Test(
    arguments: [
      ([Float](), [UInt8](repeating: 0, count: 10) + [4]),
      ([Float(2)], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 3, 4]),
      ([Float(0), 255], [0, 255, 0, 0, 0, 0, 128, 63, 0, 0, 0, 0, 0, 2, 4]),
      ([Float(0), 85, 170, 255], [0, 85, 170, 255, 0, 0, 128, 63, 0, 0, 0, 0, 0, 0, 4]),
      ([Float(0), 1, 2, 3, 255], [0, 1, 2, 3, 255, 0, 0, 0, 0, 0, 128, 63, 0, 0, 0, 0, 0, 3, 4])
    ]
  )
  func `Handles Float8 Alignment And Constant Vectors`(values: [Float], fixture: [UInt8]) throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    let vector = [Float].Float8Representation(queryOutput: values)
    expectNoDifference(vector.queryBinding, .blob(fixture))
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(try decoder.decode([Float].Float8Representation.self), values)
  }

  @Test(
    arguments: [
      (0, [UInt8(0), 16, 3]), (1, [1, 15, 3]), (7, [127, 9, 3]), (8, [255, 8, 3]),
      (9, [255, 1, 0, 23, 3]), (15, [255, 127, 0, 17, 3]), (16, [255, 255, 0, 16, 3]),
      (17, [255, 255, 1, 15, 3]), (24, [255, 255, 255, 8, 3])
    ]
  )
  func `Preserves Turso Binary Dimensions Across Byte Boundaries`(count: Int, fixture: [UInt8])
    throws
  {
    // https://docs.turso.tech/guides/vector-search#vector-types
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    let values = Array(repeating: true, count: count)
    expectNoDifference(
      [Bool].TursoBytesRepresentation(queryOutput: values).queryBinding,
      .blob(fixture)
    )
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(try decoder.decode([Bool].TursoBytesRepresentation.self), values)
  }

  @Test
  func `Uses Least Significant Bit First In Both Binary Layouts`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/convert.rs
    // SQLiteVec raw binary layout: https://github.com/asg017/sqlite-vec/blob/v0.1.9/sqlite-vec.c
    let bits = [true, false, true, false, false, false, false, true]
    let packed = [Bool].PackedBitsRepresentation(queryOutput: bits)
    let turso = [Bool].TursoBytesRepresentation(queryOutput: bits + [true])
    expectNoDifference(packed.queryBinding, .blob([133]))
    expectNoDifference(turso.queryBinding, .blob([133, 1, 0, 23, 3]))
    var packedDecoder = BlobQueryDecoder(bytes: [133])
    expectNoDifference(try packedDecoder.decode([Bool].PackedBitsRepresentation.self), bits)
  }

  @Test
  func `Rejects Malformed Floating Point Blobs`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: [0, 0])
      _ = try [Float].VectorBytesRepresentation(decoder: &decoder)
    }
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: [0, 0, 128, 63, 2])
      _ = try [Float].VectorBytesRepresentation(decoder: &decoder)
    }
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 0, 0, 240, 63])
      _ = try [Double].VectorBytesRepresentation(decoder: &decoder)
    }
  }

  @Test(arguments: [
    [UInt8](), [4], [0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4],
    [0, 0, 0, 0, 0, 0, 128, 191, 0, 0, 0, 0, 0, 0, 4],
    [0, 0, 0, 0, 0, 0, 128, 127, 0, 0, 0, 0, 0, 0, 4]
  ])
  func `Rejects Malformed Float8 Metadata`(fixture: [UInt8]) {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: fixture)
      _ = try [Float].Float8Representation(decoder: &decoder)
    }
  }

  @Test(arguments: [[UInt8](), [3], [0, 3], [0, 7, 3], [0, 24, 3], [0, 255, 3], [0, 16, 4]])
  func `Rejects Malformed Binary Metadata`(fixture: [UInt8]) {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: fixture)
      _ = try [Bool].TursoBytesRepresentation(decoder: &decoder)
    }
  }

  @Test
  func `Preserves Null For Optional Vector Columns`() throws {
    var decoder = BlobQueryDecoder(bytes: nil)
    expectNoDifference(try decoder.decode([Double].VectorBytesRepresentation.self), nil)
    #expect(throws: QueryDecodingError.self) {
      _ = try [Double].VectorBytesRepresentation(decoder: &decoder)
    }
  }

  #if swift(>=6.2)
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Uses Concrete Inline Representations For Supported Precisions`() throws {
      // https://docs.turso.tech/guides/vector-search#vector-types
      let doubles = [2 of Double].VectorBytesRepresentation(queryOutput: [1, -2])
      expectNoDifference(
        doubles.queryBinding,
        [Double].VectorBytesRepresentation(queryOutput: [1, -2]).queryBinding
      )
      expectNoDifference(doubles, [2 of Double].VectorBytesRepresentation(queryOutput: [1, -2]))
      var decoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 192, 2]
      )
      expectNoDifference(
        try decoder.decode([2 of Double].VectorBytesRepresentation.self).map { [$0[0], $0[1]] },
        [1, -2]
      )
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 1, actual: 2)) {
        _ = try [1 of Double].VectorBytesRepresentation(decoder: &decoder)
      }
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Compares Floating Point Elements With Swift Semantics`() {
      let floats = EmbeddingVector<2>([0, -0])
      let doubles = EmbeddingVector64<2>([0, -0])
      expectNoDifference(floats, EmbeddingVector<2>([0, 0]))
      expectNoDifference(doubles, EmbeddingVector64<2>([0, 0]))
      expectNoDifference(floats.hashValue, EmbeddingVector<2>([0, 0]).hashValue)
      expectNoDifference(doubles.hashValue, EmbeddingVector64<2>([0, 0]).hashValue)
      expectNoDifference(EmbeddingVector<1>([.nan]) == EmbeddingVector<1>([.nan]), false)
      expectNoDifference(EmbeddingVector64<1>([.nan]) == EmbeddingVector64<1>([.nan]), false)
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Encodes Precision And Binary Variants As Scalar Arrays`() throws {
      let double = EmbeddingVector64<2>([1, -2])
      let bits = BinaryEmbeddingVector<3>([true, false, true])
      let encoder = JSONEncoder()
      let decoder = JSONDecoder()
      expectNoDifference(String(decoding: try encoder.encode(double), as: UTF8.self), "[1,-2]")
      expectNoDifference(
        String(decoding: try encoder.encode(bits), as: UTF8.self),
        "[true,false,true]"
      )
      expectNoDifference(
        try decoder.decode(EmbeddingVector64<2>.self, from: encoder.encode(double)),
        double
      )
      expectNoDifference(
        try decoder.decode(BinaryEmbeddingVector<3>.self, from: encoder.encode(bits)),
        bits
      )
      #expect(throws: DecodingError.self) {
        _ = try decoder.decode(EmbeddingVector64<3>.self, from: encoder.encode(double))
      }
      #expect(throws: DecodingError.self) {
        _ = try decoder.decode(BinaryEmbeddingVector<2>.self, from: encoder.encode(bits))
      }
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Decodes Fixed Size Numeric And Binary Representations`() throws {
      // https://docs.turso.tech/guides/vector-search#vector-types
      var doubleDecoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 0, 0, 240, 63, 2])
      var float8Decoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 3, 4])
      var binaryDecoder = BlobQueryDecoder(bytes: [5, 13, 3])
      expectNoDifference(
        try doubleDecoder.decode(EmbeddingVector64<1>.VectorBytesRepresentation.self),
        EmbeddingVector64<1>([1])
      )
      expectNoDifference(
        try float8Decoder.decode(EmbeddingVector<1>.Float8Representation.self),
        EmbeddingVector<1>([1])
      )
      expectNoDifference(
        try binaryDecoder.decode(BinaryEmbeddingVector<3>.TursoBytesRepresentation.self),
        BinaryEmbeddingVector<3>([true, false, true])
      )
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 4, actual: 3)) {
        _ = try BinaryEmbeddingVector<4>.TursoBytesRepresentation(decoder: &binaryDecoder)
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 2, actual: 1)) {
        _ = try EmbeddingVector64<2>.VectorBytesRepresentation(decoder: &doubleDecoder)
      }
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Keeps Generation Mutation And Empty Vector Support`() {
      var doubles = EmbeddingVector64<3>(first: 1) { $0 * 2 }
      doubles[1] = 3
      expectNoDifference(Array(doubles), [1, 3, 4])
      let bits = BinaryEmbeddingVector<2>(initializingWith: {
        $0.append(true)
        $0.append(false)
      })
      expectNoDifference(Array(bits), [true, false])
      expectNoDifference(EmbeddingVector64<0>(repeating: 0), EmbeddingVector64<0>(repeating: 1))
      expectNoDifference(Array(EmbeddingVector64<2> { Double($0 + 1) }), [Double(1), 2])
      expectNoDifference(
        EmbeddingVector64<2>([1, 2]).description,
        "EmbeddingVector64<2>([1.0, 2.0])"
      )
    }
  #endif
}

private struct BlobQueryDecoder: Hashable, Sendable, QueryDecoder {
  var bytes: [UInt8]?

  mutating func decode(_ columnType: [UInt8].Type) -> [UInt8]? { self.bytes }
  mutating func decode(_ columnType: Double.Type) throws -> Double? { throw UnexpectedColumnType() }
  mutating func decode(_ columnType: Int64.Type) throws -> Int64? { throw UnexpectedColumnType() }
  mutating func decode(_ columnType: UInt64.Type) throws -> UInt64? { throw UnexpectedColumnType() }
  mutating func decode(_ columnType: String.Type) throws -> String? { throw UnexpectedColumnType() }
  mutating func decode(_ columnType: Bool.Type) throws -> Bool? { throw UnexpectedColumnType() }
  mutating func decode(_ columnType: Int.Type) throws -> Int? { throw UnexpectedColumnType() }
  mutating func decode(_ columnType: Date.Type) throws -> Date? { throw UnexpectedColumnType() }
  mutating func decode(_ columnType: UUID.Type) throws -> UUID? { throw UnexpectedColumnType() }

  private struct UnexpectedColumnType: Error {}
}
