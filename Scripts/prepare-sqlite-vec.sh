#!/bin/sh
# Prepare one translation unit in the build directory; never modify upstream sources.
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
