#if os(macOS) || os(Linux)
  import CustomDump
  import Foundation
  import Testing

  @Suite
  struct `Vec Format tests` {
    @Test
    func `Public Clients Accept Supported Encodings And Reject Unsupported Formats`() throws {
      let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      var build = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
      while !FileManager.default.fileExists(atPath: build.appendingPathComponent("Modules").path),
        build.path != "/"
      {
        build = build.deletingLastPathComponent()
      }
      // macOS can host the test bundle in Xcode's xctest executable rather than the package binary.
      if build.path == "/" {
        build = root.appendingPathComponent(".build/debug")
      }
      try #require(
        FileManager.default.fileExists(atPath: build.appendingPathComponent("Modules").path),
        "Could not locate the test executable's build directory"
      )
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      process.arguments = [
        "swift", root.appendingPathComponent("Scripts/check-sqlite-vec-formats.swift").path,
        build.path
      ]
      process.currentDirectoryURL = root
      let output = Pipe()
      process.standardOutput = output
      process.standardError = output
      try process.run()
      let diagnostics = output.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      expectNoDifference(
        process.terminationStatus,
        0,
        String(decoding: diagnostics, as: UTF8.self)
      )
    }
  }
#endif
