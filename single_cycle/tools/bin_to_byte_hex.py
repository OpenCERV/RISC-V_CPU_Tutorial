#!/usr/bin/env python3
"""Convert a flat RV32 binary to the byte-per-line HEX format used by imem.v."""

import pathlib
import sys


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: bin_to_byte_hex.py INPUT.bin OUTPUT.hex")

    data = pathlib.Path(sys.argv[1]).read_bytes()
    pathlib.Path(sys.argv[2]).write_text(
        "\n".join(f"{byte:02x}" for byte in data) + "\n",
        encoding="ascii",
    )


if __name__ == "__main__":
    main()
