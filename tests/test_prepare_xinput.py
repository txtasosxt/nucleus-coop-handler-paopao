"""Safety checks with synthetic data; no game files or external packages needed."""
import importlib.util
from pathlib import Path
import shutil
import unittest
from unittest.mock import patch
from uuid import uuid4

spec = importlib.util.spec_from_file_location(
    "prepare_xinput", Path(__file__).resolve().parents[1] / "tools" / "prepare_xinput.py"
)
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)


class PrepareTests(unittest.TestCase):
    def setUp(self):
        # Python 3.14 temporary directories use restrictive Windows ACLs that can
        # exclude a restricted runner. Ordinary mkdir inherits the workspace ACLs.
        self.build_root = (Path(__file__).resolve().parents[1] / "build").resolve()
        self.root = self.build_root / ("patch-test-" + uuid4().hex)
        self.root.mkdir(parents=True)
        self.addCleanup(self.cleanup_fixture)
        self.source = self.root / "game" / "globalgamemanagers"
        self.source.parent.mkdir()
        self.original = b"example\0settings"
        self.modified = b"example\1settings"
        self.source.write_bytes(self.original)
        self.output = self.root / "staged"
        self.builds = {tool.digest(self.original): {
            "name": "synthetic fixture", "size": len(self.original), "offset": 7,
            "patched_sha256": tool.digest(self.modified),
        }}
        self.fixture = patch.object(tool, "SUPPORTED_BUILDS", self.builds)
        self.fixture.start()
        self.addCleanup(self.fixture.stop)

    def cleanup_fixture(self):
        resolved = self.root.resolve()
        if resolved.parent != self.build_root or not resolved.name.startswith("patch-test-"):
            raise RuntimeError("Refusing to remove a fixture outside its build directory")
        shutil.rmtree(resolved)

    def test_stages_patch_and_exact_backup_without_changing_source(self):
        tool.prepare(self.source, self.output)
        self.assertEqual(self.source.read_bytes(), self.original)
        self.assertEqual((self.output / "globalgamemanagers").read_bytes(), self.modified)
        self.assertEqual((self.output / "globalgamemanagers.original-backup").read_bytes(), self.original)
        tool.prepare(self.source, self.output)  # Matching staging output is reusable.

    def test_unknown_build_refused_before_creating_output(self):
        self.source.write_bytes(b"unknown build")
        with self.assertRaisesRegex(ValueError, "Unsupported game build"):
            tool.prepare(self.source, self.output)
        self.assertFalse(self.output.exists())

    def test_already_patched_does_not_write(self):
        self.source.write_bytes(self.modified)
        self.assertIn("already matches", tool.prepare(self.source, self.output))
        self.assertFalse(self.output.exists())

    def test_wrong_patch_hash_refused_before_writing(self):
        self.builds[tool.digest(self.original)]["patched_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "Patched hash differs"):
            tool.prepare(self.source, self.output)
        self.assertFalse(self.output.exists())

    def test_install_directory_not_used_as_staging(self):
        with self.assertRaisesRegex(ValueError, "outside the game directory"):
            tool.prepare(self.source, self.source.parent)
        self.assertEqual(self.source.read_bytes(), self.original)
        self.assertFalse((self.source.parent / "globalgamemanagers.original-backup").exists())

    def test_renamed_backup_still_cannot_stage_in_its_directory(self):
        renamed = self.source.with_name("globalgamemanagers.backup")
        self.source.rename(renamed)
        with self.assertRaisesRegex(ValueError, "outside the game directory"):
            tool.prepare(renamed, renamed.parent)
        self.assertFalse(self.source.exists())

    def test_conflicting_backup_preserved_and_no_patch_written(self):
        self.output.mkdir()
        backup = self.output / "globalgamemanagers.original-backup"
        backup.write_bytes(b"another original")
        with self.assertRaisesRegex(ValueError, "conflicting file"):
            tool.prepare(self.source, self.output)
        self.assertEqual(backup.read_bytes(), b"another original")
        self.assertFalse((self.output / "globalgamemanagers").exists())


if __name__ == "__main__":
    unittest.main()
