"""Animated start-up splash screen (port of the splash in CamVistra/main.cpp).

The logo's "C" is a green ring (with a right-hand opening) carrying navy
swirl strokes around a camera lens. At start-up the image is split into:
  - a static base: the logo with the navy swirls removed from the C,
  - a swirl layer: just the navy strokes (alpha extracted from the C),
  - a lens layer: the circular lens artwork.
The swirl and lens layers rotate about the lens centre each frame; the swirls
stay clipped to the exact C ring so the letter keeps its shape.

All geometry is in source-image pixels of View/icons/CamVistraSplash.png.
If that image changes size, the animation falls back to a static logo.
"""

from __future__ import annotations

import numpy as np
from PyQt5.QtCore import QElapsedTimer, QPointF, QRect, QRectF, QSizeF, Qt, QTimer
from PyQt5.QtGui import QColor, QFont, QImage, QPainter, QPainterPath, QPixmap
from PyQt5.QtWidgets import QSplashScreen

from camvistra import tslog

SPLASH_LOGO = ":/View/icons/CamVistraSplash.png"
INTRO_MS = 850               # fade/scale-in duration (and the intro wait in main)
MINIMUM_DURATION_MS = 3000   # splash stays up at least this long after the intro

# Splash logo geometry, measured from CamVistraSplash.png (2362 x 830).
_EXPECTED_WIDTH = 2362
_EXPECTED_HEIGHT = 830
_CENTER = QPointF(318.0, 417.0)   # lens / C centre
_INNER_RADIUS = 85.0              # inner edge of green C
_OUTER_RADIUS = 158.0             # outer edge of green C
_OPENING_TOP = 369.5              # C opening, top edge
_OPENING_BOTTOM = 463.0           # C opening, bottom edge
_LENS_CLIP_RADIUS = 76.0          # inside the white gap
_CLIP_INSET = 1.0                 # keep swirl ends off the C edge

_GREEN = np.array([105.0, 186.0, 47.0])
_NAVY = np.array([0.0, 56.0, 113.0])


def create_splash_pixmap() -> QPixmap:
    """White 760x330 background with the tagline; the logo is drawn on top."""
    width, height = 760, 330
    pixmap = QPixmap(width, height)
    pixmap.fill(Qt.white)
    painter = QPainter(pixmap)
    painter.setRenderHint(QPainter.SmoothPixmapTransform)
    font = QFont()
    font.setPointSize(15)
    painter.setFont(font)
    painter.setPen(QColor("#123e69"))
    painter.drawText(QRect(16, 265, width - 32, 44), Qt.AlignCenter,
                     "CamVistra — every camera, every interface, one vista.")
    painter.end()
    return pixmap


def _to_argb(img: QImage) -> np.ndarray:
    """Copy of an ARGB32 image as an (h, w) uint32 array of 0xAARRGGBB."""
    w, h = img.width(), img.height()
    ptr = img.constBits()
    ptr.setsize(img.byteCount())
    rows = np.frombuffer(ptr, dtype=np.uint32).reshape(h, img.bytesPerLine() // 4)
    return rows[:, :w].copy()


def _from_argb(arr: np.ndarray) -> QImage:
    arr = np.ascontiguousarray(arr, dtype=np.uint32)
    h, w = arr.shape
    # copy() detaches the image from the temporary numpy buffer.
    return QImage(arr.tobytes(), w, h, w * 4, QImage.Format_ARGB32).copy()


def _q_round(values: np.ndarray) -> np.ndarray:
    """qRound for the clamped 0..255 range used here."""
    return np.floor(values + 0.5)


class AnimatedSplashScreen(QSplashScreen):
    """Splash screen that fades the CamVistra logo in and spins the "C"."""

    def __init__(self, screen, background: QPixmap, logo: QImage, flags) -> None:
        super().__init__(screen, background, flags)
        self._logo_base = (logo.convertToFormat(QImage.Format_ARGB32)
                           if not logo.isNull() else QImage())
        self._swirl_layer = QImage()
        self._lens_layer = QImage()
        self._layer_rect = QRect()
        self._layers_ready = False
        self._clock = QElapsedTimer()
        self._last_tick_ms = 0
        self._animation_time_ms = 0.0
        self._ring_clip = self._c_ring_clip()
        self._lens_clip = QPainterPath()
        self._lens_clip.addEllipse(_CENTER, _LENS_CLIP_RADIUS, _LENS_CLIP_RADIUS)

        self._prepare_logo_layers()
        self._timer = QTimer(self)
        self._timer.setInterval(16)
        self._timer.setTimerType(Qt.PreciseTimer)
        self._timer.timeout.connect(self._on_tick)

    # ------------------------------------------------------------------
    def start_animation(self) -> None:
        self._animation_time_ms = 0.0
        self._clock.start()
        self._last_tick_ms = 0
        self._timer.start()
        self.update()

    def pump(self) -> None:
        """Advance the animation and repaint now.

        Called between blocking start-up steps so the splash keeps moving
        while the main thread is busy instead of freezing and then jumping.
        """
        if not self.isVisible():
            return
        self._advance_animation()
        self.repaint()

    def hideEvent(self, event) -> None:  # noqa: N802 (Qt override)
        self._timer.stop()
        super().hideEvent(event)

    # ------------------------------------------------------------------
    def _on_tick(self) -> None:
        if not self.isVisible():
            self._timer.stop()
            return
        self._advance_animation()
        self.update()

    def _advance_animation(self) -> None:
        # Advance by real elapsed time, but cap each step so a stall on the
        # main thread (QML compile, WebEngine init, ...) resumes smoothly
        # rather than skipping the fade-in or snapping the lens to a new angle.
        max_step_ms = 33
        now = self._clock.elapsed() if self._clock.isValid() else 0
        step = max(0, min(now - self._last_tick_ms, max_step_ms))
        self._last_tick_ms = now
        self._animation_time_ms += float(step)

    def drawContents(self, painter: QPainter) -> None:  # noqa: N802 (Qt override)
        if self._logo_base.isNull():
            return
        max_logo_width, max_logo_height = 724.0, 245.0
        progress = min(max(self._animation_time_ms / INTRO_MS, 0.0), 1.0)
        eased = progress * progress * (3.0 - 2.0 * progress)

        logo_size = QSizeF(self._logo_base.size())
        logo_size.scale(max_logo_width, max_logo_height, Qt.KeepAspectRatio)
        scale = 0.94 + 0.06 * eased
        width = logo_size.width() * scale
        x = (self.width() - width) / 2.0
        y = 8.0 + 18.0 * (1.0 - eased)
        image_scale = width / self._logo_base.width()
        rotation = self._animation_time_ms * 0.10

        painter.save()
        painter.setRenderHint(QPainter.Antialiasing)
        painter.setRenderHint(QPainter.SmoothPixmapTransform)
        painter.setOpacity(eased)
        # Work in source-image coordinates from here on.
        painter.translate(x, y)
        painter.scale(image_scale, image_scale)
        painter.drawImage(QPointF(0.0, 0.0), self._logo_base)

        if self._layers_ready:
            top_left = QPointF(self._layer_rect.topLeft())
            # Navy swirls, rotated and confined to the C ring (minus its opening).
            painter.save()
            painter.setClipPath(self._ring_clip)
            self._rotate_about_lens_center(painter, rotation)
            painter.drawImage(top_left, self._swirl_layer)
            painter.restore()

            # Lens artwork. Its outer edge is a plain navy circle on white, so
            # rotating the disc keeps the silhouette unchanged.
            painter.save()
            painter.setClipPath(self._lens_clip)
            self._rotate_about_lens_center(painter, rotation)
            painter.drawImage(top_left, self._lens_layer)
            painter.restore()
        painter.restore()

    # ------------------------------------------------------------------
    @staticmethod
    def _rotate_about_lens_center(painter: QPainter, degrees: float) -> None:
        painter.translate(_CENTER)
        painter.rotate(degrees)
        painter.translate(-_CENTER)

    @staticmethod
    def _c_ring_clip() -> QPainterPath:
        outer = QPainterPath()
        outer.addEllipse(_CENTER, _OUTER_RADIUS - _CLIP_INSET, _OUTER_RADIUS - _CLIP_INSET)
        # Subtract the hole and the opening separately: adding both to one
        # odd-even path would cancel their overlap and let swirls leak into it.
        hole = QPainterPath()
        hole.addEllipse(_CENTER, _INNER_RADIUS + _CLIP_INSET, _INNER_RADIUS + _CLIP_INSET)
        opening = QPainterPath()
        opening.addRect(QRectF(_CENTER.x(), _OPENING_TOP - _CLIP_INSET,
                               _OUTER_RADIUS + 4.0,
                               _OPENING_BOTTOM - _OPENING_TOP + 2.0 * _CLIP_INSET))
        return outer.subtracted(hole).subtracted(opening)

    def _prepare_logo_layers(self) -> None:
        if self._logo_base.isNull():
            return
        if (self._logo_base.width() != _EXPECTED_WIDTH
                or self._logo_base.height() != _EXPECTED_HEIGHT):
            tslog.log_result(0, False, f"Splash logo size {self._logo_base.width()}x"
                             f"{self._logo_base.height()} does not match the animation "
                             "geometry; showing it static")
            return

        # Work only on the square around the C.
        half = int(_OUTER_RADIUS) + 4
        rect = QRect(int(_CENTER.x()) - half, int(_CENTER.y()) - half,
                     2 * half + 1, 2 * half + 1).intersected(self._logo_base.rect())
        self._layer_rect = rect

        base = _to_argb(self._logo_base)
        region = base[rect.top():rect.bottom() + 1, rect.left():rect.right() + 1]

        ys, xs = np.mgrid[rect.top():rect.bottom() + 1, rect.left():rect.right() + 1]
        px = xs + 0.5
        py = ys + 0.5
        radius = np.hypot(px - _CENTER.x(), py - _CENTER.y())

        lens_mask = radius <= _LENS_CLIP_RADIUS + 1.0
        in_opening = (px > _CENTER.x()) & (py > _OPENING_TOP) & (py < _OPENING_BOTTOM)
        ring_mask = (~lens_mask & (radius >= _INNER_RADIUS - 1.0)
                     & (radius <= _OUTER_RADIUS + 1.5) & ~in_opening)

        # The C is flat green with navy strokes on top. Treat each pixel as
        # green + alpha * (navy - green): alpha becomes the stroke layer and
        # the base pixel gets the navy contribution removed, leaving the C as
        # clean green without white or mis-coloured patches.
        rgb = np.stack([(region >> 16) & 0xFF, (region >> 8) & 0xFF, region & 0xFF],
                       axis=-1).astype(np.float64)
        direction = _NAVY - _GREEN
        alpha = np.clip(((rgb - _GREEN) @ direction) / float(direction @ direction), 0.0, 1.0)
        stroke = ring_mask & (alpha > 0.02)

        lens = np.zeros_like(region)
        lens[lens_mask] = region[lens_mask]  # opaque lens + surrounding white

        swirl = np.zeros_like(region)
        navy_rgb = np.uint32(0x00003871)  # qRgb(0, 56, 113) without alpha
        swirl_alpha = _q_round(alpha * 255.0).astype(np.uint32)
        swirl[stroke] = navy_rgb | (swirl_alpha[stroke] << np.uint32(24))

        cleaned = np.clip(_q_round(rgb - alpha[..., None] * direction), 0, 255).astype(np.uint32)
        cleaned_argb = (np.uint32(0xFF000000) | (cleaned[..., 0] << np.uint32(16))
                        | (cleaned[..., 1] << np.uint32(8)) | cleaned[..., 2])
        region[stroke] = cleaned_argb[stroke]

        self._logo_base = _from_argb(base)
        self._swirl_layer = _from_argb(swirl)
        self._lens_layer = _from_argb(lens)
        self._build_even_swirls()
        self._layers_ready = True

    def _build_even_swirls(self) -> None:
        """Rebuild the rotating layer as evenly spaced copies of one swirl.

        The logo's own swirls are irregular (one long shallow arc, three
        short steep ones, none behind the C's opening), so they never look
        evenly spread once rotating. Take the swirl whose inner end sits at
        ~166 deg (counter-clockwise from 3 o'clock) and repeat it every
        360 / SWIRL_COUNT degrees around the lens centre.
        """
        swirl_count = 6
        template_start_deg = 155.0  # sector holding only that swirl
        template_span_deg = 45.0

        r = _OUTER_RADIUS + 4.0
        sector = QPainterPath()
        sector.moveTo(_CENTER)
        sector.arcTo(QRectF(_CENTER.x() - r, _CENTER.y() - r, 2.0 * r, 2.0 * r),
                     template_start_deg, template_span_deg)
        sector.closeSubpath()

        source = self._swirl_layer.copy()
        self._swirl_layer.fill(Qt.transparent)
        top_left = QPointF(self._layer_rect.topLeft())
        painter = QPainter(self._swirl_layer)
        painter.setRenderHint(QPainter.Antialiasing)
        painter.setRenderHint(QPainter.SmoothPixmapTransform)
        painter.translate(-top_left)  # source-image coordinates
        for i in range(swirl_count):
            painter.save()
            self._rotate_about_lens_center(painter, i * 360.0 / swirl_count)
            painter.setClipPath(sector)
            painter.drawImage(top_left, source)
            painter.restore()
        painter.end()
