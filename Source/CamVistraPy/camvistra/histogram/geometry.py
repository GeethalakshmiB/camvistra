"""Vertex generation for the histogram renderers (pure numpy, no GL).

Port of the append*/buildGeometry functions of HistogramRenderer.cpp
(``build_quick_vertices``) and HistogramDisplay.cpp (``build_display_vertices``).
Vertices are clip-space triangles, float32 rows of
``x, y, r, g, b, a`` (quick renderer) or ``x, y, r, g, b`` (legacy display).
"""

from __future__ import annotations

import numpy as np

BASE_Y = np.float32(-0.92)
MAX_H = np.float32(1.78)
BIN_W = np.float32(2.0 / 256.0)
HALF_THICKNESS = np.float32(0.004)

RED = (0.95, 0.22, 0.18)
GREEN = (0.22, 0.82, 0.36)
BLUE = (0.24, 0.46, 0.95)
LUMA = (0.86, 0.90, 0.96)

DARK_CLEAR = (0.08, 0.08, 0.08, 1.0)
LIGHT_CLEAR = (1.0, 1.0, 1.0, 1.0)
DISPLAY_CLEAR = (0.04, 0.045, 0.05, 1.0)

_EMPTY6 = np.zeros((0, 6), dtype=np.float32)


def _normalized(bins, max_value: float) -> np.ndarray:
    return np.minimum(np.float32(1.0),
                      np.asarray(bins, dtype=np.float32) / np.float32(max_value))


def _with_color(xy: np.ndarray, rgba) -> np.ndarray:
    out = np.empty((xy.shape[0], 2 + len(rgba)), dtype=np.float32)
    out[:, :2] = xy
    out[:, 2:] = rgba
    return out


def _quads(x0, y0a, x1, y1, y0b=None) -> np.ndarray:
    """Two triangles per quad in the C++ vertex order:
    (x0,y0a) (x1,y0a) (x1,y1) (x0,y0a) (x1,y1) (x0,y0b)."""
    if y0b is None:
        y0b = y1
    n = len(x0)
    xy = np.empty((n, 6, 2), dtype=np.float32)
    xy[:, 0] = np.stack([x0, y0a], 1)
    xy[:, 1] = np.stack([x1, y0a], 1)
    xy[:, 2] = np.stack([x1, y1], 1)
    xy[:, 3] = np.stack([x0, y0a], 1)
    xy[:, 4] = np.stack([x1, y1], 1)
    xy[:, 5] = np.stack([x0, y0b], 1)
    return xy.reshape(-1, 2)


def append_bars(bins, rgb, x_offset: float, width_scale: float, max_value: float) -> np.ndarray:
    if max_value <= 0:
        return _EMPTY6
    norm = _normalized(bins, max_value)
    i = np.nonzero(norm > 0)[0].astype(np.float32)
    norm = norm[norm > 0]
    fill = width_scale >= 0.99
    bar_w = BIN_W if fill else BIN_W * np.float32(width_scale)
    overlap = BIN_W * np.float32(0.02) if fill else np.float32(0)
    if fill:
        x0 = np.maximum(np.float32(-1), np.float32(-1) + i * BIN_W - overlap)
        x1 = np.minimum(np.float32(1), np.float32(-1) + (i + 1) * BIN_W + overlap)
    else:
        x0 = (np.float32(-1) + i * BIN_W + (BIN_W - bar_w) * np.float32(0.5)
              + np.float32(x_offset) * BIN_W)
        x1 = x0 + bar_w
    y1 = BASE_Y + norm * MAX_H
    base = np.full_like(x0, BASE_Y)
    return _with_color(_quads(x0, base, x1, y1), (*rgb, 1.0))


def _points(bins, max_value: float):
    norm = _normalized(bins, max_value)
    i = np.arange(256, dtype=np.float32)
    return np.float32(-1) + (i + np.float32(0.5)) * BIN_W, BASE_Y + norm * MAX_H


def append_line(bins, rgb, max_value: float) -> np.ndarray:
    if max_value <= 0:
        return _EMPTY6
    px, py = _points(bins, max_value)
    x0, y0, x1, y1 = px[:-1], py[:-1], px[1:], py[1:]
    dx, dy = x1 - x0, y1 - y0
    length = np.maximum(np.float32(0.0001), np.sqrt(dx * dx + dy * dy))
    nx = -dy / length * HALF_THICKNESS
    ny = dx / length * HALF_THICKNESS
    xy = np.empty((len(x0), 6, 2), dtype=np.float32)
    xy[:, 0] = np.stack([x0 + nx, y0 + ny], 1)
    xy[:, 1] = np.stack([x0 - nx, y0 - ny], 1)
    xy[:, 2] = np.stack([x1 - nx, y1 - ny], 1)
    xy[:, 3] = np.stack([x0 + nx, y0 + ny], 1)
    xy[:, 4] = np.stack([x1 - nx, y1 - ny], 1)
    xy[:, 5] = np.stack([x1 + nx, y1 + ny], 1)
    return _with_color(xy.reshape(-1, 2), (*rgb, 1.0))


def append_filled(bins, rgb, max_value: float, light_theme: bool) -> np.ndarray:
    if max_value <= 0:
        return _EMPTY6
    # Light theme: darker, stronger fill; the outline keeps the channel colour.
    scale = 0.68 if light_theme else 1.0
    alpha = 0.62 if light_theme else 0.42
    fill_rgba = (rgb[0] * scale, rgb[1] * scale, rgb[2] * scale, alpha)
    px, py = _points(bins, max_value)
    x0, x1 = px[:-1], px[1:]
    base = np.full_like(x0, BASE_Y)
    fill = _with_color(_quads(x0, base, x1, py[1:], py[:-1]), fill_rgba)
    return np.concatenate([fill, append_line(bins, rgb, max_value)])


def build_quick_vertices(data, show_red: bool, show_green: bool, show_blue: bool,
                         show_alpha: bool, light_theme: bool, mode: int) -> np.ndarray:
    """HistogramQuickRenderer::buildGeometry. ``mode``: 0 bars, 1 line, 2 filled."""
    shown = [(data.red, RED, -0.32, show_red), (data.green, GREEN, 0.0, show_green),
             (data.blue, BLUE, 0.32, show_blue), (data.alpha, LUMA, 0.0, show_alpha)]
    shown = [s for s in shown if s[3]]
    if not shown:
        return _EMPTY6
    max_value = float(max(int(np.max(s[0])) for s in shown))
    if max_value <= 0:
        return _EMPTY6
    width_scale = 0.32 if (len(shown) > 1 and mode == 0) else 1.0
    parts = []
    for bins, rgb, x_offset, _ in shown:
        if mode == 1:
            parts.append(append_line(bins, rgb, max_value))
        elif mode == 2:
            parts.append(append_filled(bins, rgb, max_value, light_theme))
        else:
            parts.append(append_bars(bins, rgb, x_offset, width_scale, max_value))
    return np.ascontiguousarray(np.concatenate(parts), dtype=np.float32)


def _display_bars(bins, rgb, x_offset: float, width_scale: float) -> np.ndarray:
    """Legacy HistogramRenderer::appendBars: every bin, own max, no fill mode."""
    bins = np.asarray(bins, dtype=np.float32)
    if bins.size != 256:
        return np.zeros((0, 5), dtype=np.float32)
    max_value = float(bins.max())
    if max_value <= 0:
        return np.zeros((0, 5), dtype=np.float32)
    norm = _normalized(bins, max_value)
    i = np.arange(256, dtype=np.float32)
    bar_w = BIN_W * np.float32(width_scale)
    x0 = np.float32(-1) + i * BIN_W + (BIN_W - bar_w) * np.float32(0.5) + np.float32(x_offset) * BIN_W
    x1 = x0 + bar_w
    y1 = BASE_Y + norm * MAX_H
    return _with_color(_quads(x0, np.full_like(x0, BASE_Y), x1, y1), rgb)


def build_display_vertices(luminance, red, green, blue, has_rgb: bool) -> np.ndarray:
    """Legacy HistogramRenderer::rebuildGeometry."""
    if has_rgb and len(red) == 256 and len(green) == 256 and len(blue) == 256:
        parts = [_display_bars(red, RED, -0.32, 0.32),
                 _display_bars(green, GREEN, 0.0, 0.32),
                 _display_bars(blue, BLUE, 0.32, 0.32)]
    else:
        parts = [_display_bars(luminance, LUMA, 0.0, 0.92)]
    return np.ascontiguousarray(np.concatenate(parts), dtype=np.float32)
