import argparse
import os
import shutil
import time
from pathlib import Path

from project import NAME, ROOT, runtime_files
from validate import validate


def deploy(wow_root):
    validate()
    retail = wow_root.expanduser().resolve(strict=True)
    addons = (retail / "Interface" / "AddOns").resolve(strict=True)
    target = addons / NAME
    if addons != retail / "Interface" / "AddOns" or target.is_symlink() or target.resolve() != target:
        raise ValueError("Deployment target must not be redirected")
    if target == ROOT or target in ROOT.parents or ROOT in target.parents:
        raise ValueError("Deployment target overlaps the repository")
    files = runtime_files()
    staging = addons / f".{NAME}.staging"
    if staging.exists():
        raise ValueError(f"Staging directory already exists: {staging}")
    staging.mkdir()
    try:
        for source in files:
            destination = staging / source.relative_to(ROOT)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
        if target.exists():
            if not (target / f"{NAME}.toc").is_file():
                raise ValueError(f"Not a recognized {NAME} installation: {target}")
            shutil.rmtree(target)
        staging.rename(target)
    finally:
        if staging.exists():
            shutil.rmtree(staging)
    print(f"Deployed {len(files)} files to {target}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--wow-root", type=Path, default=Path(os.environ.get(
        "WOW_RETAIL_PATH", r"F:\G\World of Warcraft\_retail_")))
    parser.add_argument("--watch", action="store_true")
    args = parser.parse_args()
    previous = None
    while True:
        state = [(p, p.stat().st_mtime_ns) for p in runtime_files()]
        if state != previous:
            deploy(args.wow_root)
            previous = state
        if not args.watch:
            return
        time.sleep(1)


if __name__ == "__main__":
    main()
