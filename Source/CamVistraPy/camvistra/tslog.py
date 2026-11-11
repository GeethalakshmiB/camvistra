"""Application logging helpers (port of CamVistra/CamVistraLog.cpp).

Records go to the SDK Logger (same log file and format as the C++ build):

    CamVistra::<Class>::<method> :: Succeeded|Failed[ - detail] :: Code: <n>

(The prefix is the app name, see ``camvistra.branding``.)

The C++ code passes ``__FUNCSIG__``; here the caller's class and function
name are taken from the stack, so call sites don't need to pass anything.
"""

from __future__ import annotations

import sys

from camvistra.branding import APP_NAME
from camvistra.native import app_logger, sdk

DEBUG_INFO = sdk.DEBUG_INFO
DEBUG_VERBOSE = sdk.DEBUG_VERBOSE
DEBUG_CRITICAL = sdk.DEBUG_CRITICAL


def _caller_name(depth: int = 3) -> str:
    frame = sys._getframe(depth)
    func = frame.f_code.co_name
    owner = frame.f_locals.get("self")
    if owner is not None:
        return f"{type(owner).__name__}::{func}"
    cls = frame.f_locals.get("cls")
    if isinstance(cls, type):
        return f"{cls.__name__}::{func}"
    return func


def _write(priority: int, code: int, outcome: str, detail: str) -> None:
    message = f"{APP_NAME}::{_caller_name()} :: {outcome}"
    if detail:
        message += f" - {detail}"
    message += f" :: Code: {code}\n"
    # Logging must never change the result of the application operation.
    try:
        app_logger().writeLog(priority, message)
    except Exception:  # pragma: no cover
        pass


def log_result(code: int, succeeded: bool, detail: str = "") -> int:
    """Log INFO on success / CRITICAL on failure and pass ``code`` through."""
    _write(DEBUG_INFO if succeeded else DEBUG_CRITICAL, int(code),
           "Succeeded" if succeeded else "Failed", detail)
    return code


def log_bool_result(ok: bool, detail: str = "") -> bool:
    _write(DEBUG_INFO if ok else DEBUG_CRITICAL, 1 if ok else 0,
           "Succeeded" if ok else "Failed", detail)
    return ok


def log_info(code: int, detail: str = "") -> None:
    _write(DEBUG_INFO, int(code), "Succeeded", detail)


def log_critical(code: int, detail: str = "") -> None:
    _write(DEBUG_CRITICAL, int(code), "Failed", detail)


# ---- Qt / QML messages ------------------------------------------------------
# QML console.log/info/debug output is diagnostic chatter ("Disabled control:
# ..."): it goes to the log file only. Warnings and errors (QML TypeErrors,
# console.warn, Qt warnings) are logged and still printed to the terminal.

_QML_CATEGORIES = {"qml", "js", "default"}


def _qt_message_handler(mode, context, message) -> None:
    from PyQt5.QtCore import QtMsgType, qFormatLogMessage
    try:
        category = context.category or "default"
        quiet = mode in (QtMsgType.QtDebugMsg, QtMsgType.QtInfoMsg) and category in _QML_CATEGORIES
        priority = DEBUG_VERBOSE if quiet else (
            DEBUG_INFO if mode in (QtMsgType.QtDebugMsg, QtMsgType.QtInfoMsg) else DEBUG_CRITICAL)
        where = f" ({context.file}:{context.line})" if context.file and not quiet else ""
        try:
            app_logger().writeLog(priority, f"{APP_NAME}::{category} :: {message}{where}\n")
        except Exception:  # pragma: no cover
            pass
        if not quiet:
            sys.stderr.write(qFormatLogMessage(mode, context, message) + "\n")
    except Exception:  # pragma: no cover - never let logging raise into Qt
        pass


def install_qt_message_handler() -> None:
    """Route Qt/QML messages through the application log (call once at startup)."""
    from PyQt5.QtCore import qInstallMessageHandler
    qInstallMessageHandler(_qt_message_handler)
