import argparse
import json
from pathlib import Path

from lupa.lua51 import LuaRuntime


def encode(value, depth=0):
    if hasattr(value, "items"):
        pad = "  " * (depth + 1)
        rows = [f"{pad}[{encode(key)}] = {encode(item, depth + 1)}," for key, item in value.items()]
        return "{\n" + "\n".join(rows) + "\n" + "  " * depth + "}"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "nil"
    return str(value)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    lua = LuaRuntime()
    ns = lua.table()
    lua.execute(args.source.read_text(encoding="utf-8-sig"), "WhatToBuy", ns)
    original = ns.ArchonData
    result = lua.table(source=original.source, generatedAtUtc=original.generatedAtUtc, specs=lua.table())
    count = 0
    for _, spec in original.specs.items():
        target = lua.table()
        for mode in ("mythicplus", "raid"):
            if spec[mode] is not None:
                target[mode] = lua.table()
                for category in ("enchants", "epicGems", "gems", "consumables"):
                    target[mode][category] = spec[mode][category]
        result.specs[spec.specID] = target
        count += 1
    destination = Path(__file__).resolve().parents[1] / "Data.lua"
    destination.write_text("local _, ns = ...\n\nns.Data = " + encode(result) + "\n", encoding="utf-8")
    print(f"Imported shopping data for {count} specializations to {destination}")


if __name__ == "__main__":
    main()
