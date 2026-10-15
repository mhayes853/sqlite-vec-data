#!/usr/bin/env python3
"""Reproduce the compiled sqlite-vec sources from pinned inputs and ordered patches."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
from string import Template
import subprocess
import sys
import tempfile
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parent.parent
VENDOR = ROOT / "Vendor/sqlite-vec"
DESTINATION = ROOT / "Sources/CSQLiteVec"
INPUTS = ("sqlite-vec.c", "sqlite-vec.h.tmpl", "VERSION", "LICENSE-MIT")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="Verify without changing files")
    mode.add_argument("--fetch", action="store_true", help="Refetch and verify the pinned inputs")
    args = parser.parse_args()
    metadata = json.loads((VENDOR / "upstream.json").read_text())
    revision = metadata["revision"]
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("upstream.json must pin a full Git commit")

    inputs = {}
    for name in INPUTS:
        if args.fetch:
            url = f"{metadata['repository'].replace('github.com', 'raw.githubusercontent.com')}/{revision}/{name}"
            with urlopen(url, timeout=60) as response:
                data = response.read()
        else:
            data = (VENDOR / name).read_bytes()
        if hashlib.sha256(data).hexdigest() != metadata["sha256"][name]:
            raise ValueError(f"Checksum mismatch for {name}; verify its upstream revision")
        inputs[name] = data

    version = inputs["VERSION"].decode().strip()
    major, minor, patch = version.split("-", 1)[0].split(".")
    header = Template(inputs["sqlite-vec.h.tmpl"].decode()).substitute(
        VERSION=version,
        DATE=metadata["headerDate"],
        SOURCE=revision,
        VERSION_MAJOR=major,
        VERSION_MINOR=minor,
        VERSION_PATCH=patch,
    )

    with tempfile.TemporaryDirectory(prefix="sqlite-vec-") as temporary:
        output = Path(temporary)
        (output / "sqlite-vec.c").write_bytes(inputs["sqlite-vec.c"])
        (output / "sqlite-vec.h").write_bytes(header.encode())
        # Keep git apply independent of the caller's working directory and worktree.
        subprocess.run(["git", "init", "--quiet", str(output)], check=True)
        for patch_file in sorted((ROOT / "Patches/sqlite-vec").glob("*.patch")):
            command = ["git", "-C", str(output), "apply", "--whitespace=error-all"]
            subprocess.run(command + ["--check", str(patch_file)], check=True)
            subprocess.run(command + [str(patch_file)], check=True)

        generated = ("sqlite-vec.c", "sqlite-vec.h")
        if args.check:
            stale = [
                name
                for name in generated
                if not (DESTINATION / name).exists()
                or (DESTINATION / name).read_bytes() != (output / name).read_bytes()
            ]
            if stale:
                raise ValueError(
                    f"Generated sources differ: {', '.join(stale)}. "
                    "Run python3 Scripts/update-sqlite-vec.py"
                )
            print(f"sqlite-vec {version}: checksums, patches, and generated sources match")
        else:
            # No tracked files change until every input and patch has been validated.
            if args.fetch:
                for name, data in inputs.items():
                    (VENDOR / name).write_bytes(data)
            for name in generated:
                shutil.copyfile(output / name, DESTINATION / name)
            print(f"Regenerated sqlite-vec {version} from {revision}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)
