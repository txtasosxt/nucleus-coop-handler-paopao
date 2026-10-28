"""Stage an exact-build PAO PAO XInput patch and backup; never edit the input file."""
import argparse
import hashlib
from pathlib import Path

SUPPORTED_BUILDS = {
    "325C6E008F8DEACCF01DA083A970D3751A195E3F49C5ED9777D9480E0DFE159D": {
        "name": "PAO PAO Demo (app 3498580)", "size": 640244, "offset": 2216,
        "patched_sha256": "AA75B042730B45999DED75C3662FE7E9861E55B52B32E2C27ED964A687AD4847",
    },
    "F034DEAC724D8A4E5545BDFC3B7C46C5E872842E457515C37A76C821BBFC6D80": {
        "name": "PAO PAO (app 3024130, build 26220223)", "size": 642212, "offset": 2164,
        "patched_sha256": "30BAA662AC2EDA2F8A392855022535D1A22B4E2386A65E78AF94E755C36DDDB0",
    },
}


def digest(data):
    return hashlib.sha256(data).hexdigest().upper()


def prepare(source, output_directory):
    source = Path(source).resolve(strict=True)
    original = source.read_bytes()
    original_digest = digest(original)
    if any(original_digest == build["patched_sha256"] for build in SUPPORTED_BUILDS.values()):
        return "The input already matches the tested XInput patch; no files written."
    build = SUPPORTED_BUILDS.get(original_digest)
    if build is None or len(original) != build["size"]:
        raise ValueError("Unsupported game build/settings file. No files written; do not force an offset on another build.")
    offset = build["offset"]
    if original[offset] != 0:
        raise ValueError("Unexpected backend byte. No files written.")
    modified = bytearray(original)
    modified[offset] = 1
    patched = bytes(modified)
    if digest(patched) != build["patched_sha256"]:
        raise ValueError("Patched hash differs from the tested build. No files written.")
    output_directory = Path(output_directory).resolve()
    targets = {
        output_directory / "globalgamemanagers.original-backup": original,
        output_directory / "globalgamemanagers": patched,
    }
    if output_directory == source.parent or any(target.resolve() == source for target in targets):
        raise ValueError("Use a staging folder outside the game directory; the input will not be overwritten.")
    for target, data in targets.items():
        if target.is_symlink():
            raise ValueError("Staging targets must not be symbolic links. Use a fresh output directory.")
        if target.exists() and target.read_bytes() != data:
            raise ValueError("Staging folder has a conflicting file. Use a fresh output directory.")
    output_directory.mkdir(parents=True, exist_ok=True)
    for target, data in targets.items():
        if not target.exists():
            with target.open("xb") as output:
                output.write(data)
    if source.read_bytes() != original:
        raise RuntimeError("The input file changed externally during preparation.")
    return "Verified one-byte XInput patch and original backup staged for " + build["name"] + ". Input file unchanged."


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("settings_file", type=Path, help="The game's active Data-folder globalgamemanagers, or its original backup")
    parser.add_argument("--output-dir", type=Path, default=Path("build/xinput"))
    args = parser.parse_args()
    try:
        print(prepare(args.settings_file, args.output_dir))
    except (OSError, ValueError, RuntimeError) as error:
        parser.exit(1, str(error) + "\n")


if __name__ == "__main__":
    main()
