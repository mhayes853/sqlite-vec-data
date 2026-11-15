#!/bin/sh
# Prepare one translation unit in the build directory; never modify upstream sources.
#
# The PatchSQLiteVec build plugin runs this script for the CSQLiteVec target. It verifies
# Sources/CSQLiteVec/SHA256SUMS, applies Patches/sqlite-vec/*.patch in filename order, and prepends
# the package's sqlite-vec-platform.h include. Each patch begins with a line describing its change.
# Checksum mismatches and patch conflicts fail the build.
#
# Updating sqlite-vec
#   The pinned release and commit are SQLITE_VEC_VERSION and SQLITE_VEC_SOURCE in
#   Sources/CSQLiteVec/sqlite-vec.h.
#   1. Replace sqlite-vec.c and LICENSE-MIT with the new upstream commit's files, and render its
#      sqlite-vec.h.tmpl into sqlite-vec.h with that version, date, and commit.
#   2. Regenerate the checksums:
#        cd Sources/CSQLiteVec && shasum -a 256 sqlite-vec.c sqlite-vec.h LICENSE-MIT > SHA256SUMS
#   3. Run `swift test`. Refresh conflicting patches against the new source, preserving upstream
#      whitespace; .gitattributes keeps the vendored files byte-for-byte.
#   4. Commit the source, header, license, checksums, and patch changes together.
#
# Testing AVX dispatch
#   CI compiles Tests/CSQLiteVecTests/AVXRuntimeTests.c against this script's output and runs it
#   under QEMU on CPUs with and without AVX. To reproduce locally with Clang, SQLite headers, and
#   qemu-user installed, run the "Test AVX Runtime Dispatch" step in .github/workflows/ci.yml.
set -eu

if [ "$#" -lt 2 ]; then
  echo "usage: $0 source-directory output-directory [patch ...]" >&2
  exit 1
fi
source_directory=$1
output_directory=$2
shift 2

(
  cd "$source_directory"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum --check SHA256SUMS
  else
    shasum -a 256 --check SHA256SUMS
  fi
)

mkdir -p "$output_directory"
temporary=$(mktemp -d "$output_directory/.prepare.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
cp "$source_directory/sqlite-vec.c" "$temporary/sqlite-vec.c"
# Isolate git apply from the package checkout and the caller's working directory.
git init --quiet "$temporary"
for patch in "$@"; do
  git -C "$temporary" apply --whitespace=error-all --check "$patch"
  git -C "$temporary" apply --whitespace=error-all "$patch"
done

{
  printf '#include "sqlite-vec-platform.h"\n'
  cat "$temporary/sqlite-vec.c"
} > "$temporary/prepared.c"
mv "$temporary/prepared.c" "$output_directory/sqlite-vec.c"
