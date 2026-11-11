"""Histogram pixel math (port of the compute* functions of HistogramWorker.cpp).

``compute_histogram`` gives the same bins as the C++ worker for every
supported pixel format, selection and pixel step, using numpy only.

How the YUV formats are made fast without per-pixel float math
----------------------------------------------------------------
The C++ code converts every sampled pixel with single-precision math and
truncates the clamped result to a bin::

    R = toBin(y + 1.13983f * v)
    G = toBin(y - 0.39465f * u - 0.58060f * v)
    B = toBin(y + 2.03211f * u)

For fixed chroma (U, V) each of these equals ``clamp(y + d(U, V), 0, 255)``,
with an integer offset ``d`` that doesn't depend on ``y``. The one-time table
build in ``_tables()`` checks this against the exact float32 formula for all
2**24 (y, U, V) values. Only two (U, V) pairs break the rule, both for G,
because of float32 rounding. Each channel then becomes:

* per chroma sample: ``d = LUT[U | V << 8]`` (a 64K-entry table),
* per pixel: ``s = y + d`` (one integer add),
* one ``np.bincount`` over ``s``,
* a final 256-bin "fold" that applies the clamp.

Chroma pairs whose offset depends on ``y`` get their own 256-bin block of
``s`` values (``y`` + block base). The fold maps that block through the exact
per-y results, so the output matches the C++ float formula exactly.
"""

from __future__ import annotations

import os
import threading
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass

import numpy as np

from camvistra.histogram.data import BINS, HistogramData, HistogramSelection
from camvistra.native import sdk

PF = sdk.Pixelformat

# pixelStep(): sample every n-th row/column so that at most ~one 1080p frame
# worth of pixels is visited.
PIXEL_BUDGET = 1920 * 1080

# Rows are processed in bands of about this many pixels so the int scratch
# buffers stay cache-resident.
BAND_PIXELS = 1 << 18

# numpy releases the GIL inside ufuncs/take (and partly inside bincount), so
# bands of large frames are counted on a small thread pool.
THREADS = max(1, min(4, (os.cpu_count() or 2) - 1))
PARALLEL_MIN_PIXELS = 1 << 18

_F = np.float32
K_RV = _F(1.13983)
K_GU = _F(0.39465)
K_GV = _F(0.58060)
K_BU = _F(2.03211)
_HALF = _F(128.0)

ALPHA_TRASH = BINS  # extra bin used to drop masked pixels from the luma count


# --------------------------------------------------------------------------
# Helpers mirrored 1:1 from the anonymous namespace of HistogramWorker.cpp
# --------------------------------------------------------------------------
def pixel_step(pixel_count: int) -> int:
    return max(1, int(pixel_count) // PIXEL_BUDGET)


def _clamp(value: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, value))


def normalized_selection(w: int, h: int, selection: HistogramSelection | None) -> HistogramSelection:
    sel = selection.copy() if selection is not None else HistogramSelection()
    if sel.mode <= 0 or sel.mode > 3 or w <= 0 or h <= 0:
        return HistogramSelection(0, 0, 0, w, h)
    sel.x = _clamp(int(sel.x), 0, w - 1)
    sel.y = _clamp(int(sel.y), 0, h - 1)
    sel.width = _clamp(int(sel.width), 1, w - sel.x)
    sel.height = _clamp(int(sel.height), 1, h - sel.y)
    return sel


def expected_frame_size(pixfmt: int, w: int, h: int) -> int:
    if w <= 0 or h <= 0:
        return 0
    pixels = w * h
    if pixfmt in (PF.RGB32, PF.MJPG):
        return pixels * 4
    if pixfmt in (PF.UYVY, PF.YUYV, PF.Y16):
        return pixels * 2
    if pixfmt == PF.Y8:
        return pixels
    if pixfmt in (PF.NV12, PF.H264, PF.HEVC, PF.YUV420, PF.Y12):
        return pixels * 3 // 2
    return 0


def is_supported(pixfmt: int) -> bool:
    return pixfmt in _KIND


# --------------------------------------------------------------------------
# Offset tables
# --------------------------------------------------------------------------
@dataclass
class _Channel:
    lut: np.ndarray    # intp[65536]: s-offset per chroma key U | V << 8
    fold: np.ndarray   # intp[nbins]: s value -> output bin (256 = dropped)
    nbins: int
    trash: int         # s value used for masked pixels


class _Tables:
    def __init__(self) -> None:
        y = np.arange(BINS, dtype=np.float32)[:, None]  # (y, 1)
        c = np.arange(BINS, dtype=np.float32) - _HALF   # chroma byte -> signed float

        # floor(raw) == trunc(clamp(raw)) after clamping to [0, 255], so the
        # unclamped floor carries all information needed for the fold.
        raw_r = np.floor(y + K_RV * c[None, :]).astype(np.int32)   # [y, V]
        raw_b = np.floor(y + K_BU * c[None, :]).astype(np.int32)   # [y, U]
        d_r, exc_r = self._offsets(raw_r)
        d_b, exc_b = self._offsets(raw_b)

        d_g = np.empty((BINS, BINS), dtype=np.int32)  # [V, U]
        exc_g: dict[int, np.ndarray] = {}
        gu = K_GU * c[None, :]                         # (1, U)
        for v in range(BINS):
            raw = np.floor((y - gu) - K_GV * c[v]).astype(np.int32)  # [y, U]
            d, exc = self._offsets(raw)
            d_g[v] = d
            for u, exact in exc.items():
                exc_g[u | (v << 8)] = exact

        dmin = int(min(d_r.min(), d_g.min(), d_b.min()))
        dmax = int(max(d_r.max(), d_g.max(), d_b.max()))
        self.offset = -dmin                         # s = y + d + offset >= 0
        self.exc_base = self.offset + 255 + dmax + 1

        keys = np.arange(1 << 16)
        key_u, key_v = keys & 0xFF, keys >> 8
        self.red = self._channel(d_r[key_v], {k: exc_r[v] for v in exc_r for k in keys[key_v == v]})
        self.green = self._channel(d_g[key_v, key_u], exc_g)
        self.blue = self._channel(d_b[key_u], {k: exc_b[u] for u in exc_b for k in keys[key_u == u]})
        self.exceptions = {"red": len(exc_r), "green": len(exc_g), "blue": len(exc_b)}

        # Fast path: R depends on V only and B on U only, so index them by the
        # chroma byte directly (256-entry tables).
        if exc_r or exc_b:  # pragma: no cover - guarded invariant
            raise RuntimeError("unexpected R/B rounding exceptions")
        self.red_v = self.red.lut[0::BINS].copy()
        self.blue_u = self.blue.lut[:BINS].copy()

    @staticmethod
    def _offsets(raw: np.ndarray) -> tuple[np.ndarray, dict[int, np.ndarray]]:
        """raw[y, k] = floor of the float formula. Returns (d[k], {k: exact[y]})."""
        yi = np.arange(BINS, dtype=np.int32)[:, None]
        d_all = raw - yi
        d = np.median(d_all, axis=0).astype(np.int32)
        exact = np.clip(raw, 0, 255)
        bad = np.nonzero((np.clip(yi + d[None, :], 0, 255) != exact).any(axis=0))[0]
        return d, {int(k): exact[:, k].astype(np.intp) for k in bad}

    def _channel(self, d: np.ndarray, exceptions: dict[int, np.ndarray]) -> _Channel:
        lut = d.astype(np.intp) + self.offset
        nbins = self.exc_base + BINS * len(exceptions) + 1
        fold = np.full(nbins, BINS, dtype=np.intp)
        fold[:self.exc_base] = np.clip(np.arange(self.exc_base) - self.offset, 0, 255)
        for j, (key, exact) in enumerate(sorted(exceptions.items())):
            base = self.exc_base + BINS * j
            lut[key] = base
            fold[base:base + BINS] = exact
        return _Channel(lut, fold, nbins, nbins - 1)


_tables_lock = threading.Lock()
_tables_obj: _Tables | None = None


def _tables() -> _Tables:
    global _tables_obj
    if _tables_obj is None:
        with _tables_lock:
            if _tables_obj is None:
                _tables_obj = _Tables()
    return _tables_obj


def warm_up() -> None:
    """Build the offset tables (~0.1-0.3 s once per process)."""
    _tables()


def _fold(ch: _Channel, counts: np.ndarray) -> np.ndarray:
    out = np.bincount(ch.fold, weights=counts, minlength=BINS + 1)[:BINS]
    return np.rint(out).astype(np.uint32)


# --------------------------------------------------------------------------
# Scratch buffers and band parallelism
# --------------------------------------------------------------------------
_local = threading.local()


def _buf(name: str, n: int) -> np.ndarray:
    """Per-thread reusable flat intp buffer (fresh 16 MB allocations page-fault)."""
    bufs = getattr(_local, "bufs", None)
    if bufs is None:
        bufs = _local.bufs = {}
    buf = bufs.get(name)
    if buf is None or buf.size < n:
        buf = bufs[name] = np.empty(max(n, 1), dtype=np.intp)
    return buf[:n]


_pool_lock = threading.Lock()
_pool_obj: ThreadPoolExecutor | None = None


def _pool() -> ThreadPoolExecutor:
    global _pool_obj
    if _pool_obj is None:
        with _pool_lock:
            if _pool_obj is None:
                _pool_obj = ThreadPoolExecutor(max_workers=THREADS,
                                               thread_name_prefix="histogram-band")
    return _pool_obj


def _run_bands(rows: int, per_row: int, job):
    """Run ``job(a0, a1)`` over row bands (in parallel when worthwhile)."""
    band = max(1, BAND_PIXELS // max(1, per_row))
    ranges = [(a0, min(rows, a0 + band)) for a0 in range(0, rows, band)]
    if THREADS <= 1 or rows * per_row < PARALLEL_MIN_PIXELS:
        return [job(a0, a1) for a0, a1 in ranges]
    # One task per thread, each looping over interleaved bands, keeps the
    # per-task overhead low and the per-thread buffers hot.
    n = min(THREADS, len(ranges))
    tasks = [ranges[i::n] for i in range(n)]
    return [r for part in _pool().map(lambda rs: [job(a0, a1) for a0, a1 in rs], tasks)
            for r in part]


# --------------------------------------------------------------------------
# Counting kernels
# --------------------------------------------------------------------------
def _count_plain(view: np.ndarray, left: bool = False, right: bool = False) -> np.ndarray:
    """256-bin count of a uint8 view shaped (rows, cols) or (rows, groups, q).

    ``left``/``right`` drop the first/last element of the first/last group of
    every row (3-D views only), used when a selection starts or ends mid-pair.
    """
    rows = view.shape[0]
    per_row = int(np.prod(view.shape[1:])) or 1

    def job(a0: int, a1: int) -> np.ndarray:
        part = view[a0:a1]
        buf = _buf("s", part.size).reshape(part.shape)
        np.copyto(buf, part, casting="unsafe")
        if left:
            buf[:, 0, 0] = ALPHA_TRASH
        if right:
            buf[:, -1, -1] = ALPHA_TRASH
        return np.bincount(buf.ravel(), minlength=BINS + 1)

    counts = np.sum(_run_bands(rows, per_row, job), axis=0)
    return counts[:BINS].astype(np.uint32)


def _count_yuv(y4: np.ndarray, u2: np.ndarray, v2: np.ndarray,
               top: bool, bottom: bool, left: bool, right: bool
               ) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """R/G/B/luma counts for luma ``y4[A, P, C, Q]`` sharing chroma ``u2/v2[A, C]``.

    Each chroma sample (a, c) covers the P x Q luma block ``y4[a, :, c, :]``.
    The edge flags drop the first/last luma row/column of the block grid when
    the selection doesn't start/end on a chroma boundary.
    """
    t = _tables()
    A, P, C, Q = y4.shape
    g_lut, b_lut, r_lut = t.green.lut, t.blue_u, t.red_v

    def mask(sb: np.ndarray, value: int, first: bool, last: bool) -> None:
        # sb is laid out [Q, rows, P, C] so every add has a long inner loop.
        if top and first:
            sb[:, 0, 0, :] = value
        if bottom and last:
            sb[:, -1, -1, :] = value
        if left:
            sb[0, :, :, 0] = value
        if right:
            sb[Q - 1, :, :, C - 1] = value

    def job(a0: int, a1: int):
        n = a1 - a0
        first, last = a0 == 0, a1 == A
        ub, vb, yb = u2[a0:a1], v2[a0:a1], y4[a0:a1]
        kb = _buf("k", n * C).reshape(n, C)
        np.multiply(vb, 256, out=kb, dtype=np.intp)
        np.add(kb, ub, out=kb)
        sb = _buf("s", Q * n * P * C).reshape(Q, n, P, C)
        out = []
        for d, trash, nbins in ((r_lut[vb], t.red.trash, t.red.nbins),
                                (g_lut[kb], t.green.trash, t.green.nbins),
                                (b_lut[ub], t.blue.trash, t.blue.nbins)):
            dexp = d[:, None, :]
            for q in range(Q):
                np.add(yb[..., q], dexp, out=sb[q])
            mask(sb, trash, first, last)
            out.append(np.bincount(sb.ravel(), minlength=nbins))
        for q in range(Q):
            np.copyto(sb[q], yb[..., q], casting="unsafe")
        mask(sb, ALPHA_TRASH, first, last)
        out.append(np.bincount(sb.ravel(), minlength=BINS + 1))
        return out

    parts = _run_bands(A, P * C * Q, job)
    rc, gc, bc, ac = (np.sum([p[i] for p in parts], axis=0) for i in range(4))
    return _fold(t.red, rc), _fold(t.green, gc), _fold(t.blue, bc), ac[:BINS].astype(np.uint32)


def _yuv_from_indices(data: np.ndarray, yi: np.ndarray, ui: np.ndarray, vi: np.ndarray):
    """Generic path: explicit byte indices for every sampled pixel."""
    t = _tables()
    y = np.take(data, yi, mode="clip").astype(np.intp).ravel()
    key = np.take(data, vi, mode="clip").astype(np.intp).ravel() * 256
    key += np.take(data, ui, mode="clip").ravel()
    out = []
    for ch in (t.red, t.green, t.blue):
        s = np.take(ch.lut, key)
        s += y
        out.append(_fold(ch, np.bincount(s, minlength=ch.nbins)))
    out.append(np.bincount(y, minlength=BINS)[:BINS].astype(np.uint32))
    return tuple(out)


def _plain_from_indices(data: np.ndarray, idx: np.ndarray) -> np.ndarray:
    vals = np.take(data, idx, mode="clip").ravel()
    return np.bincount(vals, minlength=BINS)[:BINS].astype(np.uint32)


# --------------------------------------------------------------------------
# Per-format computations
# --------------------------------------------------------------------------
class _Area:
    """Normalised selection + sampling grid."""

    def __init__(self, w: int, h: int, selection: HistogramSelection | None) -> None:
        sel = normalized_selection(w, h, selection)
        self.x0, self.y0 = sel.x, sel.y
        self.x1, self.y1 = sel.x + sel.width, sel.y + sel.height
        self.step = pixel_step(sel.width * sel.height)

    def grid(self) -> tuple[np.ndarray, np.ndarray]:
        s = self.step
        rows = np.arange(self.y0, self.y1, s, dtype=np.intp)[:, None]
        cols = np.arange(self.x0, self.x1, s, dtype=np.intp)[None, :]
        return rows, cols


def _rgb32(data, w, h, area: _Area):
    if area.step == 1:
        px = data[:w * h * 4].reshape(h, w, 4)[area.y0:area.y1, area.x0:area.x1]
        return tuple(_count_plain(px[..., c]) for c in range(4)), False
    rows, cols = area.grid()
    i = (rows * w + cols) * 4
    return tuple(_plain_from_indices(data, i + c) for c in range(4)), False


def _packed422(data, w, h, area: _Area, y_off: tuple[int, int], u_off: int, v_off: int):
    x0, x1, y0, y1 = area.x0, area.x1, area.y0, area.y1
    if area.step == 1 and w % 2 == 0:
        m0, m1 = x0 // 2, (x1 - 1) // 2 + 1
        mp = data[:w * h * 2].reshape(h, w // 2, 4)[y0:y1, m0:m1]
        y4 = mp[:, None, :, y_off[0]::2]           # (rows, 1, pairs, 2)
        return _count_yuv(y4, mp[..., u_off], mp[..., v_off],
                          False, False, x0 % 2 == 1, x1 % 2 == 1), False
    rows, cols = area.grid()
    base = (rows * w + (cols & ~1)) * 2
    yi = base + np.where(cols & 1, y_off[1], y_off[0])
    return _yuv_from_indices(data, yi, base + u_off, base + v_off), False


def _uyvy(data, w, h, area):
    return _packed422(data, w, h, area, (1, 3), 0, 2)


def _yuyv(data, w, h, area):
    return _packed422(data, w, h, area, (0, 2), 1, 3)


def _planar420(data, w, h, area: _Area, nv12: bool):
    x0, x1, y0, y1 = area.x0, area.x1, area.y0, area.y1
    y_size = w * h
    cw, ch = w // 2, h // 2
    if area.step == 1 and w % 2 == 0 and h % 2 == 0:
        r0, r1 = y0 // 2, (y1 - 1) // 2 + 1
        m0, m1 = x0 // 2, (x1 - 1) // 2 + 1
        y4 = data[:y_size].reshape(ch, 2, cw, 2)[r0:r1, :, m0:m1, :]
        if nv12:
            uv = data[y_size:y_size + ch * w].reshape(ch, cw, 2)[r0:r1, m0:m1]
            u2, v2 = uv[..., 0], uv[..., 1]
        else:
            u2 = data[y_size:y_size + cw * ch].reshape(ch, cw)[r0:r1, m0:m1]
            v2 = data[y_size + cw * ch:y_size + 2 * cw * ch].reshape(ch, cw)[r0:r1, m0:m1]
        return _count_yuv(y4, u2, v2, y0 % 2 == 1, y1 % 2 == 1,
                          x0 % 2 == 1, x1 % 2 == 1), False
    rows, cols = area.grid()
    yi = rows * w + cols
    if nv12:
        ui = y_size + (rows // 2) * w + (cols // 2) * 2
        vi = ui + 1
    else:
        ui = y_size + (rows // 2) * cw + (cols // 2)
        vi = ui + cw * ch
    return _yuv_from_indices(data, yi, ui, vi), False


def _nv12(data, w, h, area):
    return _planar420(data, w, h, area, True)


def _yuv420(data, w, h, area):
    return _planar420(data, w, h, area, False)


def _mono(alpha: np.ndarray):
    z = np.zeros(BINS, dtype=np.uint32)
    return (z, z.copy(), z.copy(), alpha), True


def _y8(data, w, h, area: _Area):
    if area.step == 1:
        v = data[:w * h].reshape(h, w)[area.y0:area.y1, area.x0:area.x1]
        return _mono(_count_plain(v))
    rows, cols = area.grid()
    return _mono(_plain_from_indices(data, rows * w + cols))


def _y16(data, w, h, area: _Area):
    # bin = (little-endian uint16) >> 8 = the high byte.
    if area.step == 1:
        v = data[:w * h * 2].reshape(h, w, 2)[area.y0:area.y1, area.x0:area.x1, 1]
        return _mono(_count_plain(v))
    rows, cols = area.grid()
    return _mono(_plain_from_indices(data, (rows * w + cols) * 2 + 1))


def _y12(data, w, h, area: _Area):
    # Packed 2 pixels / 3 bytes; bin = value >> 4 = byte 0 (even) or 1 (odd col).
    x0, x1 = area.x0, area.x1
    half = w // 2
    if area.step == 1 and w % 2 == 0:
        m0, m1 = x0 // 2, (x1 - 1) // 2 + 1
        v = data[:h * half * 3].reshape(h, half, 3)[area.y0:area.y1, m0:m1, :2]
        return _mono(_count_plain(v, x0 % 2 == 1, x1 % 2 == 1))
    rows, cols = area.grid()
    return _mono(_plain_from_indices(data, (rows * half + cols // 2) * 3 + (cols & 1)))


_KIND = {
    PF.RGB32: _rgb32, PF.MJPG: _rgb32,
    PF.UYVY: _uyvy,
    PF.YUYV: _yuyv,
    PF.NV12: _nv12,
    PF.H264: _yuv420, PF.HEVC: _yuv420, PF.YUV420: _yuv420,
    PF.Y8: _y8,
    PF.Y16: _y16,
    PF.Y12: _y12,
}


def max_channel_count(hist: HistogramData) -> float:
    m = float(max(int(a.max()) for a in (hist.red, hist.green, hist.blue, hist.alpha)))
    return m if m > 0.0 else 1.0


def compute_histogram(data, width: int, height: int, pixfmt: int,
                      selection: HistogramSelection | None = None,
                      camera_index: int = -1) -> HistogramData | None:
    """HistogramWorker::process() for one frame.

    Returns None where the C++ code emits nothing: unsupported format, bad
    dimensions, or a buffer smaller than the format's frame size.
    """
    fn = _KIND.get(int(pixfmt))
    if fn is None or width <= 0 or height <= 0:
        return None
    buf = np.frombuffer(data, dtype=np.uint8) if not isinstance(data, np.ndarray) \
        else data.reshape(-1).view(np.uint8)
    expected = expected_frame_size(pixfmt, width, height)
    if expected == 0 or buf.size < expected:
        return None
    area = _Area(width, height, selection)
    (r, g, b, a), mono = fn(buf, width, height, area)
    hist = HistogramData(r, g, b, a, camera_index, 1.0, mono)
    hist.max_count = max_channel_count(hist)
    return hist
