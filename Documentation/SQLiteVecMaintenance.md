# Maintaining sqlite-vec

`Sources/CSQLiteVec` contains the pristine sqlite-vec C source, public header, and MIT license.
The pinned upstream is [v0.1.9, commit e9f598abfa0c06b328d8fe5da9c3760cce74be10](https://github.com/asg017/sqlite-vec/tree/e9f598abfa0c06b328d8fe5da9c3760cce74be10).
`SHA256SUMS` records the exact bytes of those three files.

SwiftPM's `PatchSQLiteVec` build plugin verifies the checksums, copies the C source into its build
directory, and applies `Patches/sqlite-vec/*.patch` in filename order. It then prepends the private
`sqlite-vec-platform.h` include and compiles the result. Source files stay untouched. Inputs and
outputs are declared for incremental builds; checksum failures and patch conflicts fail the build.

The package requires Swift 6.3 with `experimentalCGen`. Builds work offline and use Git, `/bin/sh`,
and either `sha256sum` or `shasum`, available in standard Linux and macOS development environments.
No regeneration command or duplicate source checkout is needed.

## Update upstream

1. Choose a full upstream commit. Replace `sqlite-vec.c` and `LICENSE-MIT` with that revision's
   files, and render its `sqlite-vec.h.tmpl` into `sqlite-vec.h` with the version, date, and revision.
   The current header preserves its original diagnostic date, including the leading `$`.
2. Update this document's pinned revision and regenerate the checksums:

   ```sh
   cd Sources/CSQLiteVec
   shasum -a 256 sqlite-vec.c sqlite-vec.h LICENSE-MIT > SHA256SUMS
   ```

3. Run `swift test`. Refresh conflicting patches against the new source, preserving upstream
   whitespace. Format only package-owned code.
4. Commit the source, header, license, checksums, and any patch changes together.

The first patch restricts AVX instructions to the AVX kernel. The second checks the private
`sqlite_vec_cpu_supports_avx()` probe before entering it. Unsupported x86 CPUs use scalar code;
architecture guards select NEON on ARM.

## Test AVX dispatch

CI tests SQL distances on emulated CPUs with and without AVX, using the same preparation script
as the plugin. With Clang, SQLite development headers, and QEMU user-mode installed, run from
the package root:

```sh
generated=$(mktemp -d)
sh Scripts/prepare-sqlite-vec.sh "$PWD/Sources/CSQLiteVec" "$generated" \
  "$PWD"/Patches/sqlite-vec/*.patch
clang -O2 -DSQLITE_CORE -DSQLITE_VEC_ENABLE_AVX=1 \
  -I "$generated" -I Sources/CSQLiteVec \
  Tests/CSQLiteVecTests/AVXRuntimeTests.c -lsqlite3 -lm -o "$generated/avx-test"
qemu-x86_64 -cpu Nehalem "$generated/avx-test" scalar
qemu-x86_64 -cpu Haswell "$generated/avx-test" avx
```
