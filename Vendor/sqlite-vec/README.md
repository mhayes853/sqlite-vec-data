# Maintaining sqlite-vec

This directory contains unmodified upstream files. `upstream.json` pins their Git revision and
SHA-256 checksums. The source is distributed under the included [MIT license](LICENSE-MIT).

`Sources/CSQLiteVec/sqlite-vec.c` and `sqlite-vec.h` are generated. Edit the ordered patches in
`Patches/sqlite-vec/` or the package-owned `sqlite-vec-arch.c` wrapper, then regenerate:

```sh
python3 Scripts/update-sqlite-vec.py
python3 Scripts/update-sqlite-vec.py --check
```

Generation verifies every checksum, renders the upstream header template, and applies each patch
with `git apply --check` before copying the results. CI checks that committed outputs match.
Normal SwiftPM builds use those outputs without running scripts or fetching sources.

The first patch scopes AVX instructions to the AVX kernel. The second calls the wrapper's private
`sqlite_vec_cpu_supports_avx()` probe before entering it. Unsupported x86 CPUs use the scalar
implementation. Architecture guards keep ARM builds on NEON.

## Update upstream

1. Choose a full upstream commit and download `sqlite-vec.c`, `sqlite-vec.h.tmpl`, `VERSION`, and
   `LICENSE-MIT` from that revision into this directory.
2. Update `upstream.json` with the revision, SHA-256 checksums, and fixed header date. The current
   date preserves the previous vendored build's diagnostic metadata, including its leading `$`.
3. Run the generator. Review and refresh any conflicting patch against the new upstream code.
4. Run `--check` and the Swift tests, then commit the pristine inputs, patches, and generated files
   together. Preserve upstream whitespace; format only package-owned code.

To restore the currently pinned inputs from GitHub and regenerate them:

```sh
python3 Scripts/update-sqlite-vec.py --fetch
```

`--fetch` verifies the downloaded bytes against the recorded checksums. Default generation and
`--check` work offline. The maintainer commands require Python 3 and Git.

## Test AVX dispatch

CI runs SQL distance calculations through the same AVX-enabled binary on emulated CPUs with and
without AVX. With Clang, SQLite development headers, and QEMU user-mode installed:

```sh
clang -O2 -DSQLITE_CORE -DSQLITE_VEC_ENABLE_AVX=1 \
  Tests/CSQLiteVecTests/AVXRuntimeTests.c -lsqlite3 -lm -o /tmp/sqlite-vec-avx-test
qemu-x86_64 -cpu Nehalem /tmp/sqlite-vec-avx-test scalar
qemu-x86_64 -cpu Haswell /tmp/sqlite-vec-avx-test avx
```
