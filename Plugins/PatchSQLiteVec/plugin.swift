import Foundation
import PackagePlugin

@main
struct PatchSQLiteVec: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
    let sourceDirectory = target.directoryURL
    let script = context.package.directoryURL.appending(path: "Scripts/prepare-sqlite-vec.sh")
    let patchDirectory = context.package.directoryURL.appending(path: "Patches/sqlite-vec")
    let patches = try FileManager.default
      .contentsOfDirectory(
        at: patchDirectory,
        includingPropertiesForKeys: nil
      )
      .filter { $0.pathExtension == "patch" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
    let inputs = [
      "sqlite-vec.c", "sqlite-vec.h", "sqlite-vec-platform.h", "SHA256SUMS", "LICENSE-MIT"
    ]
    .map { sourceDirectory.appending(path: $0) }

    return [
      .buildCommand(
        displayName: "Patch sqlite-vec",
        executable: URL(filePath: "/bin/sh"),
        arguments: [script.path, sourceDirectory.path, context.pluginWorkDirectoryURL.path]
          + patches.map(\.path),
        inputFiles: [script] + inputs + patches,
        outputFiles: [context.pluginWorkDirectoryURL.appending(path: "sqlite-vec.c")]
      )
    ]
  }
}
