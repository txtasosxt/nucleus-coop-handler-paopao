"""Stage the exact tested demo's one-byte XInput patch; never edit the input file."""
import argparse
import hashlib
from pathlib import Path

ORIGINAL_SHA256 = "325C6E008F8DEACCF01DA083A970D3751A195E3F49C5ED9777D9480E0DFE159D"
PATCHED_SHA256 = "AA75B042730B45999DED75C3662FE7E9861E55B52B32E2C27ED964A687AD4847"
EXPECTED_SIZE = 640244
PATCH_OFFSET = 2216


def digest(data):
    return hashlib.sha256(data).hexdigest().upper()


def prepare(source, output_directory):
    source = Path(source).resolve(strict=True)
    original = source.read_bytes()
    if digest(original) == PATCHED_SHA256:
        return "The input already matches the tested XInput patch; no files written."
    if len(original) != EXPECTED_SIZE or digest(original) != ORIGINAL_SHA256:
        raise ValueError("Unsupported demo build/settings file. No files written; do not force the offset on another build.")
    if original[PATCH_OFFSET] != 0:
        raise ValueError("Unexpected backend byte. No files written.")
    modified = bytearray(original)
    modified[PATCH_OFFSET] = 1
    patched = bytes(modified)
    if digest(patched) != PATCHED_SHA256:
        raise ValueError("Patched hash differs from the tested build. No files written.")
    output_directory = Path(output_directory).resolve()
    targets = {
        output_directory / "globalgamemanagers.original-backup": original,
        output_directory / "globalgamemanagers": patched,
    }
    if source in targets:
        raise ValueError("Use a staging folder outside the game directory; the input will not be overwritten.")
    for target, data in targets.items():
        if target.exists() and target.read_bytes() != data:
            raise ValueError("Staging folder has a conflicting file. Use a fresh output directory.")
    output_directory.mkdir(parents=True, exist_ok=True)
    for target, data in targets.items():
        if not target.exists():
            with target.open("xb") as output:
                output.write(data)
    if source.read_bytes() != original:
        raise RuntimeError("The input file changed externally during preparation.")
    return "Verified one-byte XInput patch and original backup staged. Input file unchanged."


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("settings_file", type=Path, help="Your demo's PaoPao Demo_Data/globalgamemanagers")
    parser.add_argument("--output-dir", type=Path, default=Path("build/xinput"))
    args = parser.parse_args()
    try:
        print(prepare(args.settings_file, args.output_dir))
    except (OSError, ValueError, RuntimeError) as error:
        parser.exit(1, str(error) + "\n")


if __name__ == "__main__":
    main()
