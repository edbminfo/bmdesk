#!/usr/bin/env python3
"""Generate hard.txt for BMDesk hardware/connection settings.

Writes a simple key=value file (unsigned) that the app reads at startup.
No keys, no signing — just plain text config.

Usage:
  python gen_custom_client.py --conn-type incoming
  python gen_custom_client.py --conn-type outgoing

Output: hard.txt written to the script directory.
"""

import argparse
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description="Generate hard.txt for BMDesk")
    parser.add_argument("--conn-type", choices=["incoming", "outgoing"],
                        help="Connection type mode")
    parser.add_argument("-o", "--output", default="hard.txt",
                        help="Output file (default: hard.txt)")
    parser.add_argument("--print-only", action="store_true",
                        help="Print to stdout instead of writing file")

    args = parser.parse_args()

    lines = []
    if args.conn_type:
        lines.append(f"conn-type={args.conn_type}")

    if not lines:
        print("[ERROR] No config specified. Use --conn-type.", file=sys.stderr)
        sys.exit(1)

    content = "\n".join(lines) + "\n"

    if args.print_only:
        print(content, end="")
    else:
        output_path = SCRIPT_DIR / args.output
        with open(output_path, "w") as f:
            f.write(content)
        print(f"[INFO] Wrote {output_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
