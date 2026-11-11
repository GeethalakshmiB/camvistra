"""Shared histogram data types (port of CamVistra/Histogram/HistogramData.h)."""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

BINS = 256


def _zero_bins() -> np.ndarray:
    return np.zeros(BINS, dtype=np.uint32)


@dataclass
class HistogramData:
    """One computed histogram. Bin arrays are ``uint32[256]`` like the C++ struct."""

    red: np.ndarray = field(default_factory=_zero_bins)
    green: np.ndarray = field(default_factory=_zero_bins)
    blue: np.ndarray = field(default_factory=_zero_bins)
    alpha: np.ndarray = field(default_factory=_zero_bins)
    camera_index: int = -1
    max_count: float = 1.0  # pre-normalised, set by the worker
    monochrome: bool = False


@dataclass
class HistogramSelection:
    """Region the histogram is computed over, in frame pixels.

    mode: 0 full frame, 1 ROI, 2 vertical line, 3 horizontal line.
    """

    mode: int = 0
    x: int = 0
    y: int = 0
    width: int = 0
    height: int = 0

    def copy(self) -> "HistogramSelection":
        return HistogramSelection(self.mode, self.x, self.y, self.width, self.height)
