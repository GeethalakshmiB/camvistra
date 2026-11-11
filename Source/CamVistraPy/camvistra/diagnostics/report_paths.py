"""Report/partial-file locations (port of CamVistra/Diagnostics/ReportPaths.cpp).

Reports live as a sibling of the app's log folder: the platform Documents
folder (``QStandardPaths.DocumentsLocation``), then ``<app name>/Reports``
(``CamVistra/Reports``, the same folder the C++ build uses).
Both functions create the directory if missing and return its absolute path
(forward slashes, as Qt returns them).

Python addition (tests only): :func:`set_reports_directory_override` redirects
both directories to another root. With no override (the default) behaviour
is identical to the C++ build.
"""

from __future__ import annotations

import contextlib
import threading

from PyQt5.QtCore import QDir, QStandardPaths

from camvistra.branding import APP_NAME

_override_lock = threading.Lock()
_override: str | None = None


def set_reports_directory_override(path: str | None) -> None:
    """Use ``path`` instead of ``<Documents>/<app name>/Reports`` (None resets)."""
    global _override
    with _override_lock:
        _override = QDir.fromNativeSeparators(str(path)) if path is not None else None


@contextlib.contextmanager
def reports_directory_override(path):
    """Context manager form of :func:`set_reports_directory_override`."""
    with _override_lock:
        previous = _override
    set_reports_directory_override(path)
    try:
        yield
    finally:
        set_reports_directory_override(previous)


def _documents_location() -> str:
    return QStandardPaths.writableLocation(QStandardPaths.DocumentsLocation)


def _ensure_dir(path: str) -> str:
    QDir().mkpath(path)
    return path


def reports_directory() -> str:
    with _override_lock:
        override = _override
    if override is not None:
        return _ensure_dir(override)
    return _ensure_dir(f"{_documents_location()}/{APP_NAME}/Reports")


def partial_directory() -> str:
    """Working area for SessionFlushWriter's crash-recovery NDJSON files: a
    hidden subfolder of reports_directory() scanned by CrashRecoveryScanner."""
    return _ensure_dir(reports_directory() + "/.partial")
