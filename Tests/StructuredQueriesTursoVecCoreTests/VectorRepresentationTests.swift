import CustomDump
import Foundation
import StructuredQueriesSQLite
import StructuredQueriesTursoVecCore
import Testing

@Suite
struct `Vector Representation tests` {
  @Test
  func `Retains Quantized Codes And Parameters When Rebinding`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    // These parameters do not span codes 0...255: decoding must not requantize the values.
    let fixture: [UInt8] = [10, 20, 0, 0, 0, 0, 0, 64, 0, 0, 128, 63, 0, 2, 4]
    let vector = try Quantized8Vector(vectorBytes: fixture)
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(try decoder.decode(Quantized8Vector.self), vector)
    expectNoDifference(vector.codes, [10, 20])
    expectNoDifference(vector.scale, 2)
    expectNoDifference(vector.shift, 1)
    expectNoDifference(vector.decodedValues(), [21, 41])
    expectNoDifference(vector.queryBinding, .blob(fixture))
  }

  @Test
  func `Keeps Large Sparse Vectors Sparse During Decoding And Binding`() throws {
    // https://docs.turso.tech/guides/vector-search#sparse-vectors
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    let fixture: [UInt8] = [
      0, 0, 128, 63, 0, 0, 0, 64,
      0, 0, 0, 0, 255, 201, 154, 59,
      0, 202, 154, 59, 9
    ]
    var decoder = BlobQueryDecoder(bytes: fixture)
    let decoded = try decoder.decode(SparseFloat32Vector.self)
    let vector = try #require(decoded)
    expectNoDifference(vector.dimensions, 1_000_000_000)
    expectNoDifference(vector.indices, [0, 999_999_999])
    expectNoDifference(vector.values, [1, 2])
    expectNoDifference(vector.queryBinding, .blob(fixture))
  }

  @Test
  func `Validates Quantization Before Binding`() throws {
    #expect {
      _ = try Quantized8Vector(quantizing: [1, .nan])
    } throws: { error in
      (error as? TursoVectorError)
        .map {
          $0.code == .invalidQuantization && !$0.reason.isEmpty
        } ?? false
    }
    #expect {
      _ = try Quantized8Vector(quantizing: [-.greatestFiniteMagnitude, .greatestFiniteMagnitude])
    } throws: { error in
      (error as? TursoVectorError)?.code == .invalidQuantization
    }
    #expect {
      _ = try Quantized8Vector(codes: [1], scale: -1, shift: 0)
    } throws: { error in
      (error as? TursoVectorError)?.code == .invalidQuantization
    }
    #expect {
      _ = try Quantized8Vector(codes: [0], scale: 1, shift: .infinity)
    } throws: { error in
      (error as? TursoVectorError)?.code == .invalidQuantization
    }
    #expect {
      _ = try Quantized8Vector(codes: [255], scale: .greatestFiniteMagnitude, shift: 0)
    } throws: { error in
      (error as? TursoVectorError)?.code == .invalidQuantization
    }
  }

  @Test(arguments: [
    (-1, [UInt32](), [Float]()),
    (Int(UInt32.max) + 1, [UInt32](), [Float]()),
    (2, [0], [Float]()),
    (2, [2], [Float(1)]),
    (2, [0, 0], [Float(1), 2]),
    (2, [1, 0], [Float(1), 2])
  ])
  func `Rejects Invalid Sparse Components`(dimensions: Int, indices: [UInt32], values: [Float]) {
    #expect {
      _ = try SparseFloat32Vector(dimensions: dimensions, indices: indices, values: values)
    } throws: { error in
      (error as? TursoVectorError)?.code == .invalidSparseComponents
    }
  }

  @Test
  func `Compares Encoded Components By Bit Pattern`() throws {
    let nan = Float(bitPattern: 0x7f80_0123)
    let fixture: [UInt8] = [
      0, 0, 0, 128, 35, 1, 128, 127,
      0, 0, 0, 0, 2, 0, 0, 0,
      3, 0, 0, 0, 9
    ]
    let sparse = try SparseFloat32Vector(vectorBytes: fixture)
    let same = try SparseFloat32Vector(dimensions: 3, indices: [0, 2], values: [-0.0, nan])
    let differentZero = try SparseFloat32Vector(dimensions: 3, indices: [0, 2], values: [0, nan])
    expectNoDifference(sparse == same, true)
    expectNoDifference(sparse.hashValue, same.hashValue)
    expectNoDifference(sparse == differentZero, false)
    expectNoDifference(sparse.vectorBytes, fixture)
    expectNoDifference(sparse.denseValues().map(\.bitPattern), [0x8000_0000, 0, 0x7f80_0123])
    let quantized = try Quantized8Vector(codes: [1], scale: 0, shift: -0.0)
    let sameQuantized = try Quantized8Vector(codes: [1], scale: 0, shift: -0.0)
    expectNoDifference(quantized, sameQuantized)
    expectNoDifference(quantized.hashValue, sameQuantized.hashValue)
    expectNoDifference(quantized == (try Quantized8Vector(codes: [1], scale: 0, shift: 0)), false)
    expectNoDifference(
      quantized == (try Quantized8Vector(codes: [2], scale: 0, shift: -0.0)),
      false
    )
  }

  @Test
  func `Stores The Documented Sparse Values Indices And Dimensions`() throws {
    // https://docs.turso.tech/sql-reference/functions/vector#vector32-sparse
    // Layout: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/vector_types.rs#L315
    // Serialization: https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs#L15
    let vector = try SparseFloat32Vector(compressing: [0, 0, 1.5, 0, 0, 2.5])
    let fixture: [UInt8] = [
      0, 0, 192, 63, 0, 0, 32, 64,
      2, 0, 0, 0, 5, 0, 0, 0,
      6, 0, 0, 0, 9
    ]
    expectNoDifference(vector.queryBinding, .blob(fixture))
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(try decoder.decode(SparseFloat32Vector.self), vector)
  }

  @Test
  func `Preserves Sparse Dimensions When Every Value Is Zero`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs#L15
    let zero = try SparseFloat32Vector(compressing: [0, -0.0, 0, 0])
    expectNoDifference(zero.queryBinding, .blob([4, 0, 0, 0, 9]))
    var decoder = BlobQueryDecoder(bytes: [4, 0, 0, 0, 9])
    expectNoDifference(
      try decoder.decode(SparseFloat32Vector.self)?.denseValues().map(\.bitPattern),
      [UInt32](repeating: 0, count: 4)
    )
    let empty = try SparseFloat32Vector(compressing: [Float]())
    expectNoDifference(empty.queryBinding, .blob([0, 0, 0, 0, 9]))
    var emptyDecoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 9])
    expectNoDifference(try emptyDecoder.decode(SparseFloat32Vector.self)?.denseValues(), [Float]())
  }

  @Test
  func `Preserves Nonzero Sparse IEEE Bit Patterns`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/convert.rs#L19
    let bits: [UInt32] = [0, 1, 0, 0x7f80_0123]
    let vector = try SparseFloat32Vector(compressing: bits.map { Float(bitPattern: $0) })
    let fixture: [UInt8] = [
      1, 0, 0, 0, 35, 1, 128, 127,
      1, 0, 0, 0, 3, 0, 0, 0,
      4, 0, 0, 0, 9
    ]
    expectNoDifference(vector.queryBinding, .blob(fixture))
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(
      try decoder.decode(SparseFloat32Vector.self)?.denseValues().map(\.bitPattern),
      bits
    )
  }

  @Test(arguments: [
    [9],  // Truncated dimensions.
    [0, 0, 0, 0, 1],  // Wrong format tag.
    [0, 0, 0, 0, 0, 9],  // Incomplete value/index pair.
    [0, 0, 128, 63, 3, 0, 0, 0, 3, 0, 0, 0, 9],
    [0, 0, 128, 63, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 9],
    [0, 0, 128, 63, 0, 0, 0, 64, 2, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 9]
  ])
  func `Rejects Malformed Sparse Lengths Tags And Indices`(_ fixture: [UInt8]) {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/vector_types.rs#L315
    // Validate the sorted, unique, in-range indices required by sparse operations.
    var decoder = BlobQueryDecoder(bytes: fixture)
    #expect(throws: VectorDecodingError.invalidBytes) {
      _ = try SparseFloat32Vector(decoder: &decoder)
    }
  }

  @Test
  func `Preserves IEEE Bit Patterns Through Scalar Dispatch`() throws {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    // Signed zero, the least subnormal, infinity, and a signaling NaN retain their IEEE bits.
    // Float16 uses the generic, untagged codec. This is a serialization format rather than a
    // supported database vector type. Signed zero, subnormal, infinity, and NaN bits survive.
    let halfBits: [UInt16] = [0x8000, 1, 0x7c00, 0x7c01]
    let halfBytes: [UInt8] = [0, 128, 1, 0, 0, 124, 1, 124]
    expectNoDifference(
      [Float16].VectorBytesRepresentation(queryOutput: halfBits.map { Float16(bitPattern: $0) })
        .queryBinding,
      .blob(halfBytes)
    )
    expectNoDifference(try [Float16](vectorBytes: halfBytes).map(\.bitPattern), halfBits)
    #expect(throws: VectorDecodingError.invalidBytes) {
      try Float16.decodeVector([0])
    }
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
    expectNoDifference(try [Float](vectorBytes: floatBytes).map(\.bitPattern), floatBits)
    expectNoDifference(try [Double](vectorBytes: doubleBytes).map(\.bitPattern), doubleBits)
    // The same float32 payload also accepts Turso's optional format tag.
    var floatDecoder = BlobQueryDecoder(bytes: floatBytes + [1])
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
  func `Quantizes Float8 With Scale Shift And Rounded Bytes`() throws {
    // https://docs.turso.tech/guides/vector-search#vector-types
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/convert.rs
    // For [0, 127.5, 255], scale = 1 and shift = 0; Turso rounds the midpoint to 128.
    let vector = try Quantized8Vector(quantizing: [0, 127.5, 255])
    let fixture: [UInt8] = [0, 128, 255, 0, 0, 0, 128, 63, 0, 0, 0, 0, 0, 1, 4]
    expectNoDifference(vector.queryBinding, .blob(fixture))
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(try decoder.decode(Quantized8Vector.self)?.decodedValues(), [0, 128, 255])
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
    let vector = try Quantized8Vector(quantizing: values)
    expectNoDifference(vector.queryBinding, .blob(fixture))
    var decoder = BlobQueryDecoder(bytes: fixture)
    expectNoDifference(try decoder.decode(Quantized8Vector.self)?.decodedValues(), values)
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
    let turso = try [Bool].TursoBytesRepresentation(vectorBytes: [133, 1, 0, 23, 3])
    expectNoDifference(turso.queryOutput, bits + [true])
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
    [4],  // Truncated metadata.
    [UInt8](repeating: 0, count: 10) + [1],  // Wrong format tag.
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4],  // Padding exceeds three bytes.
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 4],
    [0, 0, 0, 0, 0, 0, 128, 191, 0, 0, 0, 0, 0, 0, 4],
    [0, 0, 0, 0, 0, 0, 128, 127, 0, 0, 0, 0, 0, 0, 4]
  ])
  func `Rejects Malformed Float8 Metadata`(fixture: [UInt8]) {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: fixture)
      _ = try Quantized8Vector(decoder: &decoder)
    }
  }

  @Test(arguments: [
    [3],  // Truncated metadata.
    [0, 0, 16, 3],  // Payload and metadata have the wrong alignment.
    [0, 7, 3],  // Too few omitted bits to account for the metadata byte.
    [0, 24, 3],  // Too many omitted bits for the allowed padding.
    [0, 17, 3],  // Valid padding range, but a negative logical dimension count.
    [0, 16, 4]  // Wrong format tag.
  ])
  func `Rejects Malformed Binary Metadata`(fixture: [UInt8]) {
    // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
    #expect(throws: VectorDecodingError.self) {
      var decoder = BlobQueryDecoder(bytes: fixture)
      _ = try [Bool].TursoBytesRepresentation(decoder: &decoder)
    }
  }

  #if swift(>=6.2)
    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Stores Quantized Codes Inline And Retains Their Parameters`() throws {
      // https://github.com/tursodatabase/turso/blob/fc98dacd13a047feb7389f3abd67c4a4f0d0edc4/core/vector/operations/serialize.rs
      let fixture: [UInt8] = [10, 20, 0, 0, 0, 0, 0, 64, 0, 0, 128, 63, 0, 2, 4]
      var decoder = BlobQueryDecoder(bytes: fixture)
      let decoded = try decoder.decode(InlineQuantized8Vector<2>.self)
      let vector = try #require(decoded)
      let codes: [2 of UInt8] = vector.codes
      expectNoDifference([codes[0], codes[1]], [10, 20])
      expectNoDifference(vector.decodedValues(), EmbeddingVector<2>([21, 41]))
      expectNoDifference(vector.queryBinding, .blob(fixture))
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 3, actual: 2)) {
        _ = try InlineQuantized8Vector<3>(decoder: &decoder)
      }
      #expect {
        _ = try InlineQuantized8Vector<2>(codes: [10, 20], scale: -1, shift: 1)
      } throws: { error in
        (error as? TursoVectorError)?.code == .invalidQuantization
      }
      let rounded = try EmbeddingVector<3>([0, 127.5, 255]).quantized8()
      expectNoDifference(rounded.decodedValues(), EmbeddingVector<3>([0, 128, 255]))
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Keeps Sized Sparse Entry Counts Variable`() throws {
      // https://docs.turso.tech/guides/vector-search#sparse-vectors
      let empty = try SizedSparseFloat32Vector<4>(indices: [], values: [])
      let sparse = try SizedSparseFloat32Vector<4>(indices: [1, 3], values: [2, 4])
      expectNoDifference(empty.denseValues(), EmbeddingVector<4>(repeating: 0))
      expectNoDifference(sparse.denseValues(), EmbeddingVector<4>([0, 2, 0, 4]))
      expectNoDifference(
        sparse,
        try EmbeddingVector<4>([0, 2, 0, 4]).sparseFloat32()
      )
      let fixture: [UInt8] = [
        0, 0, 0, 64, 0, 0, 128, 64,
        1, 0, 0, 0, 3, 0, 0, 0,
        4, 0, 0, 0, 9
      ]
      var decoder = BlobQueryDecoder(bytes: fixture)
      expectNoDifference(sparse.queryBinding, .blob(fixture))
      expectNoDifference(try decoder.decode(SizedSparseFloat32Vector<4>.self), sparse)
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 3, actual: 4)) {
        _ = try SizedSparseFloat32Vector<3>(vectorBytes: fixture)
      }
      #expect {
        _ = try SizedSparseFloat32Vector<4>(indices: [4], values: [1])
      } throws: { error in
        (error as? TursoVectorError)?.code == .invalidSparseComponents
      }
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Treats Signed Zeros As Equal And NaNs As Unequal`() {
      let floats = EmbeddingVector<2>([0, -0.0])
      let doubles = EmbeddingVector64<2>([0, -0.0])
      expectNoDifference(floats, EmbeddingVector<2>([0, 0]))
      expectNoDifference(doubles, EmbeddingVector64<2>([0, 0]))
      expectNoDifference(floats.hashValue, EmbeddingVector<2>([0, 0]).hashValue)
      expectNoDifference(doubles.hashValue, EmbeddingVector64<2>([0, 0]).hashValue)
      expectNoDifference(EmbeddingVector<1>([.nan]) == EmbeddingVector<1>([.nan]), false)
      expectNoDifference(EmbeddingVector64<1>([.nan]) == EmbeddingVector64<1>([.nan]), false)
    }

    @Test
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func `Decodes Fixed Float64 Bindings And Validates Dimensions`() throws {
      // https://docs.turso.tech/guides/vector-search#vector-types
      var doubleDecoder = BlobQueryDecoder(bytes: [0, 0, 0, 0, 0, 0, 240, 63, 2])
      expectNoDifference(
        try doubleDecoder.decode(EmbeddingVector64<1>.VectorBytesRepresentation.self),
        EmbeddingVector64<1>([1])
      )
      let inlineDouble = try [1 of Double]
        .VectorBytesRepresentation(
          vectorBytes: [0, 0, 0, 0, 0, 0, 240, 63, 2]
        )
      expectNoDifference(inlineDouble.queryBinding, .blob([0, 0, 0, 0, 0, 0, 240, 63, 2]))
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 2, actual: 1)) {
        _ = try EmbeddingVector64<2>.VectorBytesRepresentation(decoder: &doubleDecoder)
      }
      #expect(throws: VectorDecodingError.dimensionMismatch(expected: 2, actual: 1)) {
        _ = try [2 of Double].VectorBytesRepresentation(vectorBytes: inlineDouble.vectorBytes)
      }
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
