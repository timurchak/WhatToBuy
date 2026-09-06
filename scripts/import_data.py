import argparse
import json
from pathlib import Path

from project import ROOT
from validate import validate


def encode(value, depth=0):
    if isinstance(value, list):
        value = dict(enumerate(value, 1))
    if hasattr(value, "items"):
        pad = "  " * (depth + 1)
        rows = [f"{pad}[{encode(key)}] = {encode(item, depth + 1)}," for key, item in sorted(value.items(), key=lambda pair: (isinstance(pair[0], str), pair[0]))]
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
    parser.add_argument("source", type=Path, nargs="?", default=ROOT / "data" / "wowhead.json")
    args = parser.parse_args()
    result = json.loads(args.source.read_text(encoding="utf-8-sig"))
    result['specs'] = {int(key): value for key, value in result['specs'].items()}
    destination = ROOT / "Data.lua"
    temporary = ROOT / "Data.pending.lua"
    try:
        temporary.write_text("local _, ns = ...\n\nns.Data = " + encode(result) + "\n", encoding="utf-8")
        validate(data_path=temporary)
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"Imported shopping data for {len(result['specs'])} specializations to {destination}")


if __name__ == "__main__":
    main()
