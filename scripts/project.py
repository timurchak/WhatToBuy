import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NAME = "WhatToBuy"


def runtime_files():
    toc = ROOT / f"{NAME}.toc"
    files = [toc, ROOT / "Media" / "Icon.tga"]
    for line in toc.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            path = (ROOT / line.replace("\\", "/")).resolve()
            if not path.is_relative_to(ROOT) or not path.is_file():
                raise ValueError(f"Invalid runtime file: {line}")
            files.append(path)
    if not all(path.is_file() for path in files):
        raise ValueError("Missing runtime files")
    return files


def version():
    return re.search(r"^## Version: (.+)$", (ROOT / f"{NAME}.toc").read_text(), re.M)[1].strip()
