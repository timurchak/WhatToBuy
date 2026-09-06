import argparse
import json
from datetime import datetime
from pathlib import Path

from lupa.lua51 import LuaRuntime

from project import ROOT, runtime_files, version
from collect_wowhead import SPECS


def validate(expected_version=None, data_path=None):
    if expected_version and version() != expected_version.removeprefix("v"):
        raise ValueError("Release tag does not match TOC version")
    lua = LuaRuntime()
    compile_lua = lua.eval("function(source, name) local f, err = loadstring(source, name); assert(f, err) end")
    for path in runtime_files():
        if path.suffix == ".lua":
            compile_lua(path.read_text(encoding="utf-8"), path.name)
    ns = lua.table()
    lua.execute((data_path or ROOT / "Data.lua").read_text(encoding="utf-8"), "WhatToBuy", ns)
    assert ns.Data.schemaVersion == 2 and ns.Data.source == "Wowhead"
    datetime.fromisoformat(ns.Data.generatedAtUtc)
    checks = json.loads((ROOT / "data" / "wowhead_item_checks.json").read_text(encoding="utf-8"))
    assert set(ns.Data.specs.keys()) == set(SPECS), "Specialization coverage differs"

    def check_items(items):
        assert items is not None, "Missing item list"
        assert set(items.keys()) == set(range(1, len(items) + 1)), "Item list is not contiguous"
        seen = set()
        for _, item in items.items():
            assert isinstance(item.id, int) and item.id > 0 and item.id not in seen
            assert str(item.id) in checks, f"Unchecked item {item.id}"
            assert checks[str(item.id)]['sourceUrl'] == f'https://www.wowhead.com/item={item.id}'
            assert checks[str(item.id)]['name'] == item.name and checks[str(item.id)]['rank'] == item.rank
            assert isinstance(item.name, str) and item.name
            assert item.rank in (0, 1, 2, 3) and item.popularity is None
            seen.add(item.id)

    count = 0
    for spec_id, spec in ns.Data.specs.items():
        assert isinstance(spec_id, int) and spec_id > 0
        cls, specialization, role = SPECS[spec_id]
        assert spec.sourceUrl == f'https://www.wowhead.com/guide/classes/{cls}/{specialization}/enchants-gems-pve-{role}'
        datetime.fromisoformat(spec.guideUpdated)
        datetime.fromisoformat(spec.retrievedAtUtc)
        assert spec.mythicplus is None and spec.raid is None
        for category in ("enchants", "consumables"):
            assert spec[category] is not None and list(spec[category].keys()), f"Missing {category} for {spec_id}"
            for _, items in spec[category].items():
                check_items(items)
        for category in ("gems", "epicGems"):
            check_items(spec[category])
            assert len(spec[category]) > 0, f"Missing {category} for {spec_id}"
        for category in ("Flask", "Food Buff", "Combat Potion", "Health Potion"):
            assert spec.consumables[category] is not None, f"Missing {category} for {spec_id}"
        count += 1
    assert count == 40, f"Expected 40 specializations, got {count}"
    print(f"Lua 5.1 syntax and manifest OK; {count} specializations; version {version()}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected-version")
    parser.add_argument("--data", type=Path)
    args = parser.parse_args()
    validate(args.expected_version, args.data)


if __name__ == "__main__":
    main()
