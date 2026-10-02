import CustomDump
import Foundation
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore
import Testing

@Suite
struct `Vector Representation tests` {
  @Test
  func `Uses Little Endian IEEE Bytes And Precision Tags`() throws {
    // https://docs.turso.tech/features/ai-and-embeddings#types
    // Wire format: https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vectorInt.h
    let floats: [Float].VectorBytesRepresentation = [1, -2]
    let doubles: [Double].VectorBytesRepresentation = [1, -2]
    let halves: [Float16].VectorBytesRepresentation = [1, -2]
    let floatBytes: [UInt8] = [0, 0, 128, 63, 0, 0, 0, 192]
    let doubleBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 192, 2]
    let halfBytes: [UInt8] = [0, 60, 0, 192, 5]
    expectNoDifference(floats.queryBinding, .blob(floatBytes))
    expectNoDifference(doubles.queryBinding, .blob(doubleBytes))
    expectNoDifference(halves.queryBinding, .blob(halfBytes))

    var floatDecoder = BlobQueryDecoder(bytes: floatBytes)
    var doubleDecoder = BlobQueryDecoder(bytes: doubleBytes)
    var halfDecoder = BlobQueryDecoder(bytes: halfBytes)
    expectNoDifference(try floatDecoder.decode([Float].VectorBytesRepresentation.self), [1, -2])
    expectNoDifference(try doubleDecoder.decode([Double].VectorBytesRepresentation.self), [1, -2])
    expectNoDifference(try halfDecoder.decode([Float16].VectorBytesRepresentation.self), [1, -2])
  }

  @Test
  func `Accepts The Optional Turso Float32 Tag`() throws {
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vectorInt.h
    var decoder = BlobQueryDecoder(bytes: [0, 0, 128, 63, 1])
    expectNoDifference(try decoder.decode([Float].VectorBytesRepresentation.self), [1])
  }

  @Test
  func `Truncates BFloat16 And Reconstructs Numeric Values`() throws {
    // https://docs.turso.tech/features/ai-and-embeddings#types
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vectorfloatb16.c
    let vector = [Float].BFloat16Representation(queryOutput: [Float(bitPattern: 0x3f80_ffff), -2])
    expectNoDifference(vector.queryBinding, .blob([128, 63, 0, 192, 6]))
    var decoder = BlobQueryDecoder(bytes: [128, 63, 0, 192, 6])
    expectNoDifference(try decoder.decode([Float].BFloat16Representation.self), [1, -2])
  }

  @Test
  func `Quantizes Float8 With Scale Shift And Rounded Bytes`() throws {
    // https://docs.turso.tech/features/ai-and-embeddings#types
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vector.c
    // For [0, 127.5, 255], scale = 1 and shift = 0; libSQL rounds the midpoint to 128.
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
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vectorInt.h
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
    // https://docs.turso.tech/features/ai-and-embeddings#types
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vectorInt.h
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
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vector.c
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
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vectorInt.h
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
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: [0, 60, 6])
      _ = try [Float16].VectorBytesRepresentation(decoder: &decoder)
    }
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: [0, 6])
      _ = try [Float].BFloat16Representation(decoder: &decoder)
    }
  }

  @Test(arguments: [
    [UInt8](), [4], [0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4],
    [0, 0, 0, 0, 0, 0, 128, 191, 0, 0, 0, 0, 0, 0, 4],
    [0, 0, 0, 0, 0, 0, 128, 127, 0, 0, 0, 0, 0, 0, 4]
  ])
  func `Rejects Malformed Float8 Metadata`(fixture: [UInt8]) {
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vectorInt.h
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: fixture)
      _ = try [Float].Float8Representation(decoder: &decoder)
    }
  }

  @Test(arguments: [[UInt8](), [3], [0, 3], [0, 7, 3], [0, 24, 3], [0, 255, 3], [0, 16, 4]])
  func `Rejects Malformed Binary Metadata`(fixture: [UInt8]) {
    // https://github.com/tursodatabase/libsql/blob/main/libsql-sqlite3/src/vectorInt.h
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
    func `Compares Floating Point Elements With Swift Semantics`() {
      let floats = EmbeddingVector<2>([0, -0])
      let doubles = EmbeddingVector64<2>([0, -0])
      let halves = EmbeddingVector16<2>([0, -0])
      expectNoDifference(floats, EmbeddingVector<2>([0, 0]))
      expectNoDifference(doubles, EmbeddingVector64<2>([0, 0]))
      expectNoDifference(halves, EmbeddingVector16<2>([0, 0]))
      expectNoDifference(floats.hashValue, EmbeddingVector<2>([0, 0]).hashValue)
      expectNoDifference(doubles.hashValue, EmbeddingVector64<2>([0, 0]).hashValue)
      expectNoDifference(halves.hashValue, EmbeddingVector16<2>([0, 0]).hashValue)
      expectNoDifference(EmbeddingVector<1>([.nan]) == EmbeddingVector<1>([.nan]), false)
      expectNoDifference(EmbeddingVector64<1>([.nan]) == EmbeddingVector64<1>([.nan]), false)
      expectNoDifference(EmbeddingVector16<1>([.nan]) == EmbeddingVector16<1>([.nan]), false)
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Encodes Precision And Binary Variants As Scalar Arrays`() throws {
      let double = EmbeddingVector64<2>([1, -2])
      let half = EmbeddingVector16<2>([1, -2])
      let bits = BinaryEmbeddingVector<3>([true, false, true])
      let encoder = JSONEncoder()
      let decoder = JSONDecoder()
      expectNoDifference(String(decoding: try encoder.encode(double), as: UTF8.self), "[1,-2]")
      expectNoDifference(String(decoding: try encoder.encode(half), as: UTF8.self), "[1,-2]")
      expectNoDifference(
        String(decoding: try encoder.encode(bits), as: UTF8.self),
        "[true,false,true]"
      )
      expectNoDifference(
        try decoder.decode(EmbeddingVector64<2>.self, from: encoder.encode(double)),
        double
      )
      expectNoDifference(
        try decoder.decode(EmbeddingVector16<2>.self, from: encoder.encode(half)),
        half
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
      // https://docs.turso.tech/features/ai-and-embeddings#types
      var doubleDecoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 0, 0, 240, 63, 2])
      var halfDecoder = BlobQueryDecoder(bytes: [0, 60, 5])
      var bfloatDecoder = BlobQueryDecoder(bytes: [128, 63, 6])
      var float8Decoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 3, 4])
      var binaryDecoder = BlobQueryDecoder(bytes: [5, 13, 3])
      expectNoDifference(
        try doubleDecoder.decode(EmbeddingVector64<1>.VectorBytesRepresentation.self),
        EmbeddingVector64<1>([1])
      )
      expectNoDifference(
        try halfDecoder.decode(EmbeddingVector16<1>.VectorBytesRepresentation.self),
        EmbeddingVector16<1>([1])
      )
      expectNoDifference(
        try bfloatDecoder.decode(EmbeddingVector<1>.BFloat16Representation.self),
        EmbeddingVector<1>([1])
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
      expectNoDifference(Array(EmbeddingVector16<2> { Float16($0 + 1) }), [Float16(1), 2])
      let bits = BinaryEmbeddingVector<2>(initializingWith: {
        $0.append(true)
        $0.append(false)
      })
      expectNoDifference(Array(bits), [true, false])
      expectNoDifference(EmbeddingVector64<0>(repeating: 0), EmbeddingVector64<0>(repeating: 1))
      expectNoDifference(
        EmbeddingVector16<2>([1, 2]).description,
        "EmbeddingVector16<2>([1.0, 2.0])"
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
