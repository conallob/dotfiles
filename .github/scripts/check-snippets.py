#!/usr/bin/env python3
"""Validate UltiSnips snippet file structure.

Checks:
- Every 'snippet' block has a matching 'endsnippet'
- No nested snippet definitions
- No stray 'endsnippet' outside a block

Usage: python3 check-snippets.py <directory>
"""
import sys
import pathlib


def check_file(path: pathlib.Path) -> list[str]:
    errors = []
    in_snippet = False
    current_name = None

    with open(path) as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.rstrip()
            stripped = line.lstrip()

            if stripped.startswith("snippet ") and not in_snippet:
                in_snippet = True
                parts = stripped.split()
                current_name = parts[1] if len(parts) > 1 else "<unnamed>"

            elif stripped == "endsnippet":
                if not in_snippet:
                    errors.append(
                        f"{path}:{lineno}: stray 'endsnippet' outside snippet block"
                    )
                in_snippet = False
                current_name = None

            elif stripped.startswith("snippet ") and in_snippet:
                errors.append(
                    f"{path}:{lineno}: nested 'snippet' inside '{current_name}'"
                )

    if in_snippet:
        errors.append(f"{path}: unclosed snippet '{current_name}' at end of file")

    return errors


def main() -> int:
    directory = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path("dot_vim/UltiSnips")

    if not directory.exists():
        print(f"Directory not found: {directory}")
        return 1

    files = sorted(directory.glob("*.snippets"))
    if not files:
        print(f"No *.snippets files found in {directory}")
        return 0

    all_errors: list[str] = []
    for path in files:
        all_errors.extend(check_file(path))

    if all_errors:
        for error in all_errors:
            print(f"ERROR: {error}")
        return 1

    print(f"OK: {len(files)} snippet file(s) valid ({sum(1 for f in files for _ in [None])} checked)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
