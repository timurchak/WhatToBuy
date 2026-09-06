from zipfile import ZIP_DEFLATED, ZipFile

from project import NAME, ROOT, runtime_files, version
from validate import validate


def main():
    validate()
    destination = ROOT / "dist" / f"{NAME}-{version()}.zip"
    destination.parent.mkdir(exist_ok=True)
    with ZipFile(destination, "w", ZIP_DEFLATED) as archive:
        for source in runtime_files():
            archive.write(source, f"{NAME}/{source.relative_to(ROOT).as_posix()}")
    print(destination)


if __name__ == "__main__":
    main()
