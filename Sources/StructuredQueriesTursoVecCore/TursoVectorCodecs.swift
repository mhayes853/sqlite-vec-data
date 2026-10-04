import StructuredQueriesVectorCore

// Format definitions: https://github.com/tursodatabase/libsql/blob/d6c75af6353bb1c34985399608e37cd272a35aa1/libsql-sqlite3/src/vectorInt.h
// Conversion rules: https://github.com/tursodatabase/libsql/blob/d6c75af6353bb1c34985399608e37cd272a35aa1/libsql-sqlite3/src/vector.c

/// libSQL bfloat16 values, exposed as Float scalars.
///
/// Binding truncates the low 16 bits of each Float's IEEE representation, matching libSQL.
/// Decoding reconstructs the stored Float values, which may differ from the original values.
enum BFloat16VectorCodec {
  static func encode(_ elements: [Float]) -> [UInt8] {
    elements.flatMap { value in
      let bits = value.bitPattern >> 16
      return [UInt8(truncatingIfNeeded: bits), UInt8(truncatingIfNeeded: bits >> 8)]
    } + [6]
  }

  static func decode(_ bytes: [UInt8]) throws -> [Float] {
    guard bytes.last == 6, bytes.count % 2 == 1 else { throw VectorDecodingError.invalidBytes }
    return stride(from: 0, to: bytes.count - 1, by: 2)
      .map {
        Float(bitPattern: (UInt32(bytes[$0]) | UInt32(bytes[$0 + 1]) << 8) << 16)
      }
  }
}

/// Turso's quantized float8 values, exposed as reconstructed Float scalars.
///
/// This is an unsigned-byte quantization with per-vector scale and shift, rather than an IEEE
/// float8 or SQLiteVec int8 encoding. Binding requires finite values and a finite scale.
/// Conversion is lossy; decoding returns `shift + scale * byte` for each stored component.
enum Float8VectorCodec {
  static func encode(_ elements: [Float]) -> [UInt8] {
    precondition(elements.allSatisfy(\.isFinite), "Float8 vector elements must be finite")
    let shift = elements.min() ?? 0
    let scale = ((elements.max() ?? 0) - shift) / 255
    precondition(scale.isFinite, "Float8 vector range must have a finite scale")
    let padding = (4 - elements.count % 4) % 4
    let quantized = elements.map { value in
      scale == 0
        ? UInt8.zero : UInt8(max(0, min(255, ((value - shift) / scale + 0.5).rounded(.towardZero))))
    }
    return quantized + Array(repeating: 0, count: padding)
      + Float32VectorCodec.encode([scale, shift]) + [0, UInt8(padding), 4]
  }

  static func decode(_ bytes: [UInt8]) throws -> [Float] {
    guard bytes.count >= 11, bytes.count % 4 == 3, bytes.last == 4 else {
      throw VectorDecodingError.invalidBytes
    }
    let alignedCount = bytes.count - 11
    let padding = Int(bytes[bytes.count - 2])
    guard padding <= 3, padding <= alignedCount else { throw VectorDecodingError.invalidBytes }
    let parameters = try Float32VectorCodec.decode(
      Array(bytes[alignedCount..<(alignedCount + 8)])
    )
    guard parameters[0].isFinite, parameters[0] >= 0, parameters[1].isFinite else {
      throw VectorDecodingError.invalidBytes
    }
    let values = bytes.prefix(alignedCount - padding)
      .map { Float($0) * parameters[0] + parameters[1] }
    guard values.allSatisfy(\.isFinite) else { throw VectorDecodingError.invalidBytes }
    return values
  }
}

/// Turso's packed binary vector format, including padding and dimension metadata.
///
/// True corresponds to a positive component (represented by +1 when extracted), and false to
/// a nonpositive component (represented by -1). Unlike SQLiteVec's packed bits, this encoding
/// preserves dimension counts that are not multiples of eight.
enum TursoBitsVectorCodec {
  static func encode(_ elements: [Bool]) -> [UInt8] {
    let byteCount = (elements.count + 7) / 8
    let payload = (0..<byteCount)
      .map { byteIndex in
        (0..<8)
          .reduce(UInt8.zero) { bits, bit in
            let index = byteIndex * 8 + bit
            return bits | (index < elements.count && elements[index] ? UInt8(1) << bit : 0)
          }
      }
    let padding = byteCount.isMultiple(of: 2) ? 1 : 0
    let trailingBits = (byteCount + padding + 1) * 8 - elements.count
    return payload + Array(repeating: 0, count: padding) + [UInt8(trailingBits), 3]
  }

  static func decode(_ bytes: [UInt8]) throws -> [Bool] {
    guard bytes.count >= 3, bytes.count % 2 == 1, bytes.last == 3 else {
      throw VectorDecodingError.invalidBytes
    }
    let trailingBits = Int(bytes[bytes.count - 2])
    // The metadata byte contributes eight omitted bits; padding contributes at most eight more.
    guard (8...23).contains(trailingBits) else { throw VectorDecodingError.invalidBytes }
    let dimensions = (bytes.count - 1) * 8 - trailingBits
    guard dimensions >= 0 else { throw VectorDecodingError.invalidBytes }
    return (0..<dimensions).map { bytes[$0 / 8] & (UInt8(1) << ($0 % 8)) != 0 }
  }
}
