"""Registration of the shared Qt resources (CamVistra/qml.qrc).

``tools/build_resources.py`` compiles the .qrc into ``camvistra/qml_rc.py``.
In a developer checkout the module is (re)built on demand when the QML
sources are newer; frozen builds ship the pre-compiled module.
"""

from __future__ import annotations

import importlib
import sys
from pathlib import Path

_ROOT = Path(__file__).resolve().parents[1]


def ensure_resources() -> None:
    builder = _ROOT / "tools" / "build_resources.py"
    if not getattr(sys, "frozen", False) and builder.exists():
        sys.path.insert(0, str(builder.parent))
        try:
            import build_resources  # type: ignore
            build_resources.build()
        finally:
            sys.path.pop(0)
    importlib.import_module("camvistra.qml_rc")
