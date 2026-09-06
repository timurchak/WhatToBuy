import argparse

from lupa.lua51 import LuaRuntime

from project import ROOT, runtime_files, version


def validate(expected_version=None):
    if expected_version and version() != expected_version.removeprefix("v"):
        raise ValueError("Release tag does not match TOC version")
    lua = LuaRuntime()
    compile_lua = lua.eval("function(source, name) local f, err = loadstring(source, name); assert(f, err) end")
    for path in runtime_files():
        if path.suffix == ".lua":
            compile_lua(path.read_text(encoding="utf-8"), path.name)
    ns = lua.table()
    lua.execute((ROOT / "Data.lua").read_text(encoding="utf-8"), "WhatToBuy", ns)
    count = 0
    for spec_id, spec in ns.Data.specs.items():
        assert isinstance(spec_id, int) and spec_id > 0
        for mode in ("mythicplus", "raid"):
            assert spec[mode] is not None, f"Missing {mode} for {spec_id}"
            for category in ("enchants", "gems", "epicGems", "consumables"):
                assert spec[mode][category] is not None, f"Missing {category} for {spec_id}"
        count += 1
    assert count == 40, f"Expected 40 specializations, got {count}"
    print(f"Lua 5.1 syntax and manifest OK; {count} specializations; version {version()}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected-version")
    args = parser.parse_args()
    validate(args.expected_version)


if __name__ == "__main__":
    main()
