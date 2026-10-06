// Run after building: swift Scripts/check-sqlite-vec-formats.swift [build-directory]
import Foundation

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#endif

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let build = URL(
  fileURLWithPath: CommandLine.arguments.dropFirst().first
    ?? root.appendingPathComponent(".build/debug").path
)
let compilerArguments = [
  "swiftc", "-typecheck", "-I", build.appendingPathComponent("Modules").path,
  "-I", build.path, "-load-plugin-executable",
  build.appendingPathComponent("StructuredQueriesMacros-tool").path + "#StructuredQueriesMacros"
]
let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: directory) }
let source = directory.appendingPathComponent("Client.swift")

let header = #"""
  import StructuredQueriesSQLiteVecCore
  import StructuredQueriesTursoVecCore
  import StructuredQueriesSQLite

  struct ClientFloatRepresentation: Hashable, Sendable, QueryBindable, VectorBytesRepresentable {
    typealias Scalar = Float
    typealias Encoding = [Float].VectorBytesRepresentation
    typealias VectorBytesRepresentation = Self
    typealias QueryOutput = Self
    var vectorBytes: [UInt8]

    init(vectorBytes: [UInt8]) throws {
      let _ = try Float.decodeVector(vectorBytes)
      self.vectorBytes = vectorBytes
    }
  }

  @Table struct Columns: Vec0 {
    @Column(as: [Float].VectorBytesRepresentation.self) var floats: [Float]
    @Column(as: [Double].VectorBytesRepresentation.self) var doubles: [Double]
    @Column(as: [Bool].PackedBitsRepresentation.self) var packed: [Bool]
    @Column(as: [Bool].TursoBytesRepresentation.self) var tursoBits: [Bool]
    var sparse: SparseFloat32Vector
    var quantized: Quantized8Vector
  }

  @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
  func check() throws {
    let floats: [Float].VectorBytesRepresentation = [1, 2]
    let doubles: [Double].VectorBytesRepresentation = [1, 2]
    let packed: [Bool].PackedBitsRepresentation = [true, false, true, false, false, false, false, true]
    let tursoBits: [Bool].TursoBytesRepresentation = [true, false]
    let sparse = try SparseFloat32Vector(compressing: [0, 1])
    let quantized = try Quantized8Vector(quantizing: [1, 2])
  """#

let supported = #"""
    let custom = try ClientFloatRepresentation(vectorBytes: floats.vectorBytes)
    let _ = Vec.distanceL2(custom, to: floats)
    let _ = Vec.normalize(floats, as: ClientFloatRepresentation.self)
    let _ = Vec.distanceL1(floats, to: floats)
    let _ = Vec.distanceL2(Columns.columns.floats, to: floats)
    let _ = Columns.columns.floats.distanceCosine(to: floats)
    let _ = Columns.columns.floats.match(floats)
    let _ = Vec.add(floats, floats)
    let _ = Vec.sub(floats, floats)
    let _ = Vec.normalize(floats)
    let _ = Vec.f32(floats)
    let _ = Vec.bit(floats)
    let _ = Vec.int8(floats)
    let _ = Vec.quantizeInt8(floats, scale: 1)
    let _ = Vec.quantizeBinary(floats)
    let _ = Vec.distanceHamming(packed, to: packed)
    let _ = Columns.columns.packed.distanceHamming(to: packed)
    let _ = Columns.columns.packed.match(packed)
    let _ = Columns.columns.packed.bit()
    let _ = Vec.length(floats)
    let _ = Vec.type(floats)
    let _ = Vec.toJSON(floats)
    let _ = Vec.each(floats)
    let _ = Columns.columns.floats.vecEach()
    let _ = Columns.columns.floats.length()
    let _ = Columns.columns.floats.type()
    let _ = Columns.columns.floats.toJSON()
    let _ = Columns.columns.floats.slice(0..<8)
    let _ = Vec.slice(floats, start: 0, end: 8)
    let _ = Vec.slice(floats, range: 0..<8)
    let _ = Vec.slice(floats, range: 0...7)
    let _ = Vec.slice(floats, start: 0, length: 8)
    let _ = Vec.length(packed)
    let _ = Vec.type(packed)
    let _ = Vec.toJSON(packed)
    let _ = Vec.each(packed)
    let _ = Columns.columns.packed.vecEach()
    let _ = Columns.columns.packed.length()
    let _ = Columns.columns.packed.type()
    let _ = Columns.columns.packed.toJSON()
    let _ = Columns.columns.packed.slice(0..<8)
    let _ = Vec.slice(packed, start: 0, end: 8)
    let _ = Vec.slice(packed, range: 0..<8)
    let _ = Vec.slice(packed, range: 0...7)
    let _ = Vec.slice(packed, start: 0, length: 8)

    #if swift(>=6.2)
      let fixed = EmbeddingVector<2>([1, 2])
      let fixedBits = BinaryEmbeddingVector<8>.PackedBitsRepresentation(
        queryOutput: BinaryEmbeddingVector<8>(repeating: true)
      )
      let _ = Vec.distanceL2(floats, to: fixed)
      let _ = Vec.distanceCosine(fixed, to: floats)
      let _ = Vec.add(fixed, floats, as: EmbeddingVector<2>.self)
      let _ = Vec.sub(fixed, floats, as: [2 of Float].VectorBytesRepresentation.self)
      let _ = Vec.normalize(fixed, as: EmbeddingVector<2>.VectorBytesRepresentation.self)
      let _ = Vec.f32(floats, as: EmbeddingVector<2>.self)
      let _ = Vec.quantizeBinary(fixed, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
      let _ = Vec.distanceHamming(packed, to: fixedBits)
      let _ = Vec.distanceHamming(fixedBits, to: packed)
      let _ = Vec.each(fixedBits)
      let _ = Vec.bit(fixedBits, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
      let _ = Vec.slice(fixedBits, range: 0..<8, as: BinaryEmbeddingVector<8>.PackedBitsRepresentation.self)
      let _ = Vec.slice(floats, range: 0..<1, as: EmbeddingVector<1>.self)
    #endif
  """#

// Each case targets a public entry point, operation restriction, or result-encoding mismatch.
let rejected = [
  "float64 distance": "Vec.distanceL2(doubles, to: doubles)",
  "sparse distance": "Vec.distanceCosine(sparse, to: sparse)",
  "quantized distance": "Vec.distanceL1(quantized, to: quantized)",
  "Turso binary distance": "Vec.distanceHamming(tursoBits, to: tursoBits)",
  "mixed distance": "Vec.distanceL2(floats, to: doubles)",
  "Float32 Hamming": "Vec.distanceHamming(floats, to: floats)",
  "binary L2": "Vec.distanceL2(packed, to: packed)",
  "binary L1": "Vec.distanceL1(packed, to: packed)",
  "binary cosine": "Vec.distanceCosine(packed, to: packed)",
  "binary addition": "Vec.add(packed, packed)",
  "binary subtraction": "Vec.sub(packed, packed)",
  "binary normalization": "Vec.normalize(packed)",
  "binary quantization": "Vec.quantizeBinary(packed)",
  "unsupported addition": "Vec.add(quantized, quantized)",
  "unsupported subtraction": "Vec.sub(sparse, sparse)",
  "unsupported length": "Vec.length(doubles)",
  "unsupported type": "Vec.type(sparse)",
  "unsupported JSON": "Vec.toJSON(quantized)",
  "unsupported slice": "Vec.slice(doubles, range: 0..<1)",
  "unsupported normalization": "Vec.normalize(doubles)",
  "unsupported f32 input": "Vec.f32(doubles)",
  "unsupported bit input": "Vec.bit(tursoBits)",
  "unsupported int8 input": "Vec.int8(quantized)",
  "unsupported int8 quantization": "Vec.quantizeInt8(doubles, scale: 1)",
  "unsupported binary quantization": "Vec.quantizeBinary(sparse)",
  "unsupported iteration": "Vec.each(doubles)",
  "unsupported expression iteration": "Columns.columns.sparse.vecEach()",
  "unsupported column MATCH": "Columns.columns.doubles.match(doubles)",
  "mixed Float32 MATCH": "Columns.columns.floats.match(doubles)",
  "mixed binary MATCH": "Columns.columns.packed.match(tursoBits)",
  "unsupported column distance": "Columns.columns.quantized.distanceL2(to: quantized)",
  "unsupported column operation": "Columns.columns.tursoBits.slice(0..<8)",
  "Float32 column Hamming": "Columns.columns.floats.distanceHamming(to: floats)",
  "binary column arithmetic": "Columns.columns.packed.add(packed)",
  "addition result": "Vec.add(floats, floats, as: [Double].VectorBytesRepresentation.self)",
  "subtraction result": "Vec.sub(floats, floats, as: Quantized8Vector.self)",
  "normalization result": "Vec.normalize(floats, as: SparseFloat32Vector.self)",
  "Float32 slice result":
    "Vec.slice(floats, range: 0..<1, as: [Bool].PackedBitsRepresentation.self)",
  "binary slice result":
    "Vec.slice(packed, range: 0..<8, as: [Float].VectorBytesRepresentation.self)",
  "f32 result": "Vec.f32(floats, as: [Double].VectorBytesRepresentation.self)",
  "bit result": "Vec.bit(packed, as: [Bool].TursoBytesRepresentation.self)",
  "quantized binary result": "Vec.quantizeBinary(floats, as: [Bool].TursoBytesRepresentation.self)"
]

struct CompilerOutput: Hashable, Sendable {
  let status: Int32
  let diagnostics: String
}

func compileClient(_ body: String) throws -> CompilerOutput {
  try (header + "\n" + body + "\n}\n").write(to: source, atomically: true, encoding: .utf8)
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = compilerArguments + [source.path]
  process.currentDirectoryURL = root
  let diagnostics = Pipe()
  process.standardError = diagnostics
  process.standardOutput = FileHandle.nullDevice
  try process.run()
  let output = diagnostics.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()
  return CompilerOutput(
    status: process.terminationStatus,
    diagnostics: String(decoding: output, as: UTF8.self)
  )
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data((message + "\n").utf8))
  exit(1)
}

let accepted = try compileClient(supported)
guard accepted.status == 0 else {
  fail("Supported SQLiteVec client failed to compile:\n" + accepted.diagnostics)
}
print("Supported Float32 and packed-bit clients: accepted")
for (name, expression) in rejected.sorted(by: { $0.key < $1.key }) {
  let result = try compileClient("  let _ = " + expression)
  guard result.status != 0 else {
    fail("Unsupported client unexpectedly compiled: " + name)
  }
  // Missing imports or unavailable macros must not count as an encoding rejection.
  let expected = [
    "requires the types", "no exact matches", "requires that", "referencing instance method",
    "has no member", "cannot convert"
  ]
  guard expected.contains(where: { result.diagnostics.contains($0) }) else {
    fail("Unexpected compiler failure for " + name + ":\n" + result.diagnostics)
  }
}
print("Unsupported encodings, operations, and result types: \(rejected.count) rejected")
