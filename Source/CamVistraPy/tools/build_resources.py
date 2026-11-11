"""Compile the shared Qt resource file (CamVistra/qml.qrc) for the Python app.

The QML/JS/JSON/icons under CamVistra/View are shared, unchanged, between the
C++ and the Python builds. This script compiles the same ``qml.qrc`` with
pyrcc5 into ``camvistra/qml_rc.py``; importing that module registers the
``qrc:/View/...`` paths the QML and controllers use.

Branding: the files listed in ``camvistra.branding.VIEW_TEXT`` show the
product name. Branded copies of them are written to ``build/branding`` and
compiled under their original qrc paths (aliases in a generated .qrc), so the
Python app shows its own name while the shared files stay untouched.

Usage:  python tools/build_resources.py [--force]
Re-runs only when the .qrc, any file it lists or the branding table is newer
than the output.
"""

from __future__ import annotations

import argparse
import html
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QRC = ROOT.parent / "CamVistra" / "qml.qrc"
OUT = ROOT / "camvistra" / "qml_rc.py"
BRANDING_PY = ROOT / "camvistra" / "branding.py"
STAGE = ROOT / "build" / "branding"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from camvistra import branding  # noqa: E402

_FILE_RE = re.compile(r"<file([^>]*)>([^<]+)</file>")


def inputs() -> list[Path]:
    files = _FILE_RE.findall(QRC.read_text(encoding="utf-8"))
    return [QRC, BRANDING_PY] + [QRC.parent / f for _, f in files]


def up_to_date() -> bool:
    if not OUT.exists():
        return False
    newest = max(p.stat().st_mtime for p in inputs() if p.exists())
    return OUT.stat().st_mtime >= newest


def _branded_copy(rel: str) -> Path:
    """Write the branded copy of ``rel`` (a qrc path) and return its path."""
    src = QRC.parent / rel
    raw = src.read_bytes()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw[3:].decode("utf-8") if bom else raw.decode("utf-8")
    for old, new in branding.VIEW_TEXT[rel]:
        if old not in text:
            # The shared file changed: the app still builds, with the old name
            # in that spot, until the branding table is updated.
            print(f"warning: branding text {old!r} not found in {rel}", file=sys.stderr)
        text = text.replace(old, new)
    dst = STAGE / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes((b"\xef\xbb\xbf" if bom else b"") + text.encode("utf-8"))
    return dst


def branded_qrc() -> Path:
    """qml.qrc with every entry pointing at the shared file, or at its branded copy."""

    def entry(m: re.Match) -> str:
        attrs, rel = m.group(1), m.group(2).strip()
        if "alias=" in attrs:
            raise SystemExit(f"qml.qrc alias entries are not supported by the branding step: {rel}")
        path = _branded_copy(rel) if rel in branding.VIEW_TEXT else (QRC.parent / rel).resolve()
        # pyrcc5 only resolves paths relative to the .qrc, with forward slashes.
        target = Path(os.path.relpath(path, STAGE)).as_posix()
        return f'<file{attrs} alias="{html.escape(rel)}">{html.escape(target)}</file>'

    STAGE.mkdir(parents=True, exist_ok=True)
    qrc = STAGE / "qml.qrc"
    qrc.write_text(_FILE_RE.sub(entry, QRC.read_text(encoding="utf-8")), encoding="utf-8")
    return qrc


def build(force: bool = False) -> Path:
    if not force and up_to_date():
        return OUT
    missing = [p for p in inputs() if not p.exists()]
    if missing:
        raise SystemExit(f"qml.qrc references missing files: {missing[:5]}")
    qrc = branded_qrc()
    cmd = [sys.executable, "-m", "PyQt5.pyrcc_main", "-o", str(OUT), str(qrc)]
    subprocess.run(cmd, check=True, cwd=STAGE)
    return OUT


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    out = build(ap.parse_args().force)
    print(f"resources -> {out} ({out.stat().st_size / 1e6:.1f} MB)")
