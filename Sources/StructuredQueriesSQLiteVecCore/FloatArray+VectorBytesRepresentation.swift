import StructuredQueriesCore

// MARK: - Array

extension Array where Element == Float {
  public struct VectorBytesRepresentation: QueryBindable, QueryDecodable, QueryRepresentable {
    public var queryOutput: [Float]

    public var queryBinding: QueryBinding {
      var bytes = [UInt8]()
      bytes.reserveCapacity(self.queryOutput.count * MemoryLayout<Float>.stride)
      for i in 0..<self.queryOutput.count {
        let (a, b, c, d) = unpack(self.queryOutput[i])
        bytes.append(a)
        bytes.append(b)
        bytes.append(c)
        bytes.append(d)
      }
      return .blob(bytes)
    }

    public init(decoder: inout some QueryDecoder) throws {
      let queryOutput = try [UInt8](decoder: &decoder)
      let size = MemoryLayout<Float>.stride
      self.queryOutput = [Float]()
      self.queryOutput.reserveCapacity(queryOutput.count / size)
      for i in 0..<(queryOutput.count / size) {
        self.queryOutput.append(
          pack(
            queryOutput[i * size],
            queryOutput[i * size + 1],
            queryOutput[i * size + 2],
            queryOutput[i * size + 3]
          )
        )
      }
    }

    public init(queryOutput: [Float]) {
      self.queryOutput = queryOutput
    }
  }
}

// MARK: - InlineArray

#if swift(>=6.2)
  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  extension InlineArray where Element == Float {
    public struct VectorBytesRepresentation: QueryBindable, QueryDecodable, QueryRepresentable {
      public var queryOutput: InlineArray<count, Float>

      public var queryBinding: QueryBinding {
        var bytes = [UInt8]()
        bytes.reserveCapacity([count of Float].count * MemoryLayout<Float>.stride)
        for i in 0..<[count of Float].count {
          let (a, b, c, d) = unpack(self.queryOutput[i])
          bytes.append(a)
          bytes.append(b)
          bytes.append(c)
          bytes.append(d)
        }
        return .blob(bytes)
      }

      public init(decoder: inout some QueryDecoder) throws {
        let queryOutput = try [UInt8](decoder: &decoder)
        let size = MemoryLayout<Float>.stride
        guard queryOutput.count == [count of Float].count * size else {
          throw InvalidBytesError()
        }
        self.queryOutput = [count of Float] { span in
          for i in 0..<[count of Float].count {
            span.append(
              pack(
                queryOutput[i * size],
                queryOutput[i * size + 1],
                queryOutput[i * size + 2],
                queryOutput[i * size + 3]
              )
            )
          }
        }
      }

      public init(queryOutput: InlineArray<count, Float>) {
        self.queryOutput = queryOutput
      }

      private struct InvalidBytesError: Error {}
    }
  }
#endif

// MARK: - Helpers

private func pack(_ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) -> Float {
  Float(bitPattern: UInt32(a) | (UInt32(b) << 8) | (UInt32(c) << 16) | (UInt32(d) << 24))
}

private func unpack(_ float: Float) -> (UInt8, UInt8, UInt8, UInt8) {
  let bits = float.bitPattern.littleEndian
  let a = UInt8(bits & 0xFF)
  let b = UInt8((bits >> 8) & 0xFF)
  let c = UInt8((bits >> 16) & 0xFF)
  let d = UInt8((bits >> 24) & 0xFF)
  return (a, b, c, d)
}
