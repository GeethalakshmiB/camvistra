"""Histogram subsystem (port of CamVistra/Histogram/).

Public API::

    from camvistra.histogram import (HistogramManager, HistogramSelection,
                                     HistogramQuickItem, register_qml_types)
"""

from __future__ import annotations

from camvistra.histogram.data import HistogramData, HistogramSelection
from camvistra.histogram.manager import HistogramManager
from camvistra.histogram.quick_item import HistogramDisplay, HistogramQuickItem

_registered = False


def register_qml_types() -> None:
    """main.cpp: qmlRegisterType<HistogramQuickItem>("HistogramQuickItem", 1, 0, ...).

    The C++ qRegisterMetaType<HistogramData> has no PyQt equivalent; results
    travel through ``pyqtSignal(object)``. Safe to call more than once.
    """
    global _registered
    if _registered:
        return
    from PyQt5.QtQml import qmlRegisterType
    qmlRegisterType(HistogramQuickItem, "HistogramQuickItem", 1, 0, "HistogramQuickItem")
    _registered = True


def __getattr__(name: str):
    if name == "HistogramWindow":  # lazy: pulls in QtQuick views / qml resources
        from camvistra.histogram.window import HistogramWindow
        return HistogramWindow
    raise AttributeError(name)


__all__ = ["HistogramManager", "HistogramSelection", "HistogramQuickItem", "HistogramData",
           "HistogramDisplay", "register_qml_types", "HistogramWindow"]
