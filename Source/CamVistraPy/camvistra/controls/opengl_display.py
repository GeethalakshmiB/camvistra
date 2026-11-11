"""Video preview item (port of CamVistra/Controls/OpenGlDisplay.{h,cpp}).

``FramebufferObject`` is the QML type ``FrameBufferObject`` (module
``qml.components.frameBufferObject 1.0``). Its render-thread counterpart
``OpenGLDisplay`` uploads the latest frame from a native ``sdk.FrameSlot``
and draws it with the GLSL shaders extracted verbatim from the C++ renderer
(``camvistra/controls/shaders.py``).

Threading: the native FramePump writes frames into the slot on its
processing thread and asks for a repaint; ``OpenGLDisplay.render()`` runs on
the Qt Quick render thread and reads the slot under the slot's mutex (the
C++ ``renderMutex``). No pixel data passes through Python objects: texture
uploads read the slot's memory directly through the buffer protocol.

Deliberate deviation from the C++ code: the C++ ``initDrawBuffer`` /
``cleanOpenGLDisplay`` deleted GL objects from the processing/GUI thread,
where no GL context is current. Here they only flag the slot, and the GL
objects are released by the renderer on the render thread.

Requires desktop OpenGL (``Qt.AA_UseDesktopOpenGL`` is set by the app) for
PyOpenGL; GL ES/ANGLE is not supported by this renderer.
"""

from __future__ import annotations

import ctypes
import threading

import numpy as np
from OpenGL import GL
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QOpenGLShader, QOpenGLShaderProgram
from PyQt5.QtQuick import QQuickFramebufferObject

from camvistra import tslog
from camvistra.controls.shaders import SHADERS
from camvistra.native import sdk

PF = sdk.Pixelformat

# Interleaved position (xyz) + texcoord (uv), two triangles.
VERTICES = np.array([
    -1.0, 1.0, 0.0, 0.0, 1.0,
    -1.0, -1.0, 0.0, 0.0, 0.0,
    1.0, -1.0, 0.0, 1.0, 0.0,
    1.0, -1.0, 0.0, 1.0, 0.0,
    1.0, 1.0, 0.0, 1.0, 1.0,
    -1.0, 1.0, 0.0, 0.0, 1.0,
], dtype=np.float32)
STRIDE = 5 * 4
TEXCOORD_OFFSET = ctypes.c_void_p(3 * 4)

# Pixel format -> (shader program, log name); the dispatch of OpenGLDisplay::render().
_PROGRAM_FOR = {
    PF.UYVY: ("UYVY", "shaderUYVY"),
    PF.YUYV: ("YUYV", "shaderYUYV"),
    PF.RGB32: ("RGB32", "shaderRGB32"),
    PF.Y16: ("Y16_10Bpp", "shaderY16_10Bpp"),
    PF.Y8: ("Y8", "shaderY8"),
    PF.H264: ("YUV420p", "shaderYUV420p (H264)"),
    PF.HEVC: ("YUV420p", "shaderYUV420p (HEVC)"),
    PF.YUV420: ("YUV420p", "shaderYUV420p (YUV420)"),
    PF.Y12: ("Y12", "shaderY12"),
    PF.Y10: ("Y10", "shaderY10"),
    PF.NV12: ("NV12", "shaderNV12"),
    PF.BY8: ("BY8", "shaderBY8"),
    PF.BY10: ("BY10", "shaderBY10"),
    PF.BY12: ("BY12", "shaderBY12"),
    PF.BY16: ("BY16", "shaderBY16"),
}

# Program -> (texture sampler uniforms (name, unit), filter)
_TEXTURES = {
    "UYVY": ([("uyvy_texture", 0)], GL.GL_LINEAR),
    "YUYV": ([("yuyv_texture", 0)], GL.GL_LINEAR),
    "RGB32": ([("texture", 0)], GL.GL_LINEAR),
    "Y16_10Bpp": ([("grey_texture", 0)], GL.GL_LINEAR),
    "Y8": ([("grey_texture", 0)], GL.GL_LINEAR),
    "YUV420p": ([("y_texture", 0), ("u_texture", 1), ("v_texture", 2)], GL.GL_LINEAR),
    "Y12": ([("y_texture", 0)], GL.GL_NEAREST),
    "Y10": ([("y_texture", 0)], GL.GL_LINEAR),
    "NV12": ([("y_texture", 0), ("uv_texture", 1)], GL.GL_LINEAR),
    "BY8": ([("bayer_texture", 0)], GL.GL_NEAREST),
    "BY10": ([("bayer_texture", 0)], GL.GL_NEAREST),
    "BY12": ([("bayer_texture", 0)], GL.GL_NEAREST),
    "BY16": ([("bayer_texture", 0)], GL.GL_NEAREST),
}


class OpenGLDisplay(QQuickFramebufferObject.Renderer):
    """Render-thread half: owns the GL program, textures and VBO."""

    def __init__(self, slot) -> None:
        super().__init__()
        self._slot = slot
        self._program: QOpenGLShaderProgram | None = None
        self._program_name = ""
        self._textures: list[int] = []
        # Storage allocated per texture: (internal, w, h, fmt, dtype). Frames of
        # the same shape only update the pixels (glTexSubImage2D) instead of
        # re-creating the texture storage every frame (glTexImage2D).
        self._tex_storage: dict[int, tuple] = {}
        self._vbo = 0
        self._pos_loc = -1
        self._tex_loc = -1
        self._y10 = np.zeros(0, dtype=np.uint8)

    # ---- GL resource management ---------------------------------------
    def _release_gl(self) -> None:
        if self._program is not None:
            if self._program.isLinked():
                self._program.release()
                self._program.removeAllShaders()
            self._program = None
        if self._textures:
            GL.glDeleteTextures(self._textures)
            self._textures = []
        self._tex_storage.clear()
        if self._vbo:
            GL.glDeleteBuffers(1, [self._vbo])
            self._vbo = 0

    def _build_program(self, pixfmt: int) -> int:
        choice = _PROGRAM_FOR.get(pixfmt)
        if choice is None:
            tslog.log_critical(pixfmt, "No shader available for pixel format")
            return 0
        name, log_name = choice
        self._release_gl()
        self._vbo = int(GL.glGenBuffers(1))
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, self._vbo)
        GL.glBufferData(GL.GL_ARRAY_BUFFER, VERTICES.nbytes, VERTICES, GL.GL_STATIC_DRAW)

        prog = QOpenGLShaderProgram()
        prog.addShaderFromSourceCode(QOpenGLShader.Vertex, SHADERS[name]["vertex"])
        prog.addShaderFromSourceCode(QOpenGLShader.Fragment, SHADERS[name]["fragment"])
        ok = prog.link()
        prog.bind()
        self._pos_loc = prog.attributeLocation("a_position")
        self._tex_loc = prog.attributeLocation("a_texCoord")

        samplers, filt = _TEXTURES[name]
        self._textures = [int(t) for t in np.atleast_1d(GL.glGenTextures(len(samplers)))]
        for tex in self._textures:
            GL.glBindTexture(GL.GL_TEXTURE_2D, tex)
            GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, filt)
            GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, filt)
            GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_CLAMP_TO_EDGE)
            GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_T, GL.GL_CLAMP_TO_EDGE)
        for uniform, unit in samplers:
            prog.setUniformValue(prog.uniformLocation(uniform), unit)
        if name == "Y12":
            prog.setUniformValue(prog.uniformLocation("videoWidth"), float(self._slot.width))
            prog.setUniformValue(prog.uniformLocation("videoHeight"), float(self._slot.height))
        if name == "NV12":
            prog.release()
        self._program, self._program_name = prog, name
        result = 1 if ok else 0
        tslog.log_result(result, ok, f"Shader chosen: {log_name}")
        return result

    # ---- per-frame --------------------------------------------------------
    def render(self) -> None:  # called on the Qt Quick render thread
        slot = self._slot
        slot.lock()
        try:
            if slot.take_reset():
                self._release_gl()
            if not (slot.gotFrame and slot.fboInitialized):
                # No frame yet (camera not streaming, or stream stopped). The
                # FBO's storage is uninitialised GPU memory, which shows up as
                # coloured noise once the tile is enlarged (e.g. double-click
                # in multi-camera view). Clear it to fully transparent, as the
                # C++ does, so the tile looks as before its first render: an
                # empty preview area with only its status bar.
                GL.glClearColor(0.0, 0.0, 0.0, 0.0)
                GL.glClear(GL.GL_COLOR_BUFFER_BIT)
                return
            if self._program is None and not self._build_program(slot.pixfmt):
                return
            self._draw(slot)
        finally:
            slot.unlock()

    def _upload(self, unit: int, tex: int, internal, w: int, h: int, fmt, dtype, data) -> None:
        GL.glActiveTexture(GL.GL_TEXTURE0 + unit)
        GL.glBindTexture(GL.GL_TEXTURE_2D, tex)
        shape = (internal, w, h, fmt, dtype)
        if self._tex_storage.get(tex) == shape:
            GL.glTexSubImage2D(GL.GL_TEXTURE_2D, 0, 0, 0, w, h, fmt, dtype, data)
        else:
            GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, internal, w, h, 0, fmt, dtype, data)
            self._tex_storage[tex] = shape

    def _draw(self, slot) -> None:
        prog, name = self._program, self._program_name
        w, h = slot.width, slot.height
        buf = np.frombuffer(slot, dtype=np.uint8)
        prog.bind()
        tex = self._textures
        u8 = GL.GL_UNSIGNED_BYTE
        if name in ("UYVY", "YUYV", "Y16_10Bpp"):
            # Two pixels per RGBA texel.
            self._upload(0, tex[0], GL.GL_RGBA, w // 2, h, GL.GL_RGBA, u8, buf)
        elif name == "RGB32":
            self._upload(0, tex[0], GL.GL_RGB, w, h, GL.GL_RGBA, u8, buf)
        elif name == "Y8":
            self._upload(0, tex[0], GL.GL_LUMINANCE, w, h, GL.GL_LUMINANCE, u8, buf)
        elif name == "YUV420p":
            y_size = w * h
            self._upload(0, tex[0], GL.GL_LUMINANCE, w, h, GL.GL_LUMINANCE, u8, buf)
            self._upload(1, tex[1], GL.GL_LUMINANCE, w // 2, h // 2, GL.GL_LUMINANCE, u8, buf[y_size:])
            self._upload(2, tex[2], GL.GL_LUMINANCE, w // 2, h // 2, GL.GL_LUMINANCE, u8,
                         buf[y_size + y_size // 4:])
        elif name == "Y12":
            self._upload(0, tex[0], GL.GL_RGB, w // 2, h, GL.GL_RGB, u8, buf)
            prog.setUniformValue(prog.uniformLocation("videoWidth"), float(w))
            prog.setUniformValue(prog.uniformLocation("videoHeight"), float(h))
        elif name == "Y10":
            # Packed 10-bit: 4 MSB bytes + 1 LSB byte per group of 4 pixels.
            pixels = w * h
            if self._y10.size != pixels:
                self._y10 = np.zeros(pixels, dtype=np.uint8)
            groups = min(buf.size // 5, pixels // 4)
            self._y10[:groups * 4] = buf[:groups * 5].reshape(groups, 5)[:, :4].ravel()
            self._upload(0, tex[0], GL.GL_LUMINANCE, w, h, GL.GL_LUMINANCE, u8, self._y10)
        elif name == "NV12":
            y_size = w * h
            self._upload(0, tex[0], GL.GL_LUMINANCE, w, h, GL.GL_LUMINANCE, u8, buf)
            self._upload(1, tex[1], GL.GL_LUMINANCE_ALPHA, w // 2, h // 2, GL.GL_LUMINANCE_ALPHA, u8,
                         buf[y_size:])
        elif name == "BY8":
            self._upload(0, tex[0], GL.GL_LUMINANCE, w, h, GL.GL_LUMINANCE, u8, buf)
            GL.glUniform2f(prog.uniformLocation("texSize"), float(w), float(h))
        elif name in ("BY10", "BY12", "BY16"):
            # One little-endian 16-bit sample per pixel.
            self._upload(0, tex[0], GL.GL_LUMINANCE, w, h, GL.GL_LUMINANCE, GL.GL_UNSIGNED_SHORT,
                         buf[:buf.size // 2 * 2].view(np.uint16))
            GL.glUniform2f(prog.uniformLocation("texSize"), float(w), float(h))

        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, self._vbo)
        GL.glEnableVertexAttribArray(self._pos_loc)
        GL.glVertexAttribPointer(self._pos_loc, 3, GL.GL_FLOAT, GL.GL_FALSE, STRIDE, None)
        GL.glEnableVertexAttribArray(self._tex_loc)
        GL.glVertexAttribPointer(self._tex_loc, 2, GL.GL_FLOAT, GL.GL_FALSE, STRIDE, TEXCOORD_OFFSET)
        GL.glActiveTexture(GL.GL_TEXTURE0)
        GL.glDrawArrays(GL.GL_TRIANGLES, 0, 6)
        GL.glDisableVertexAttribArray(self._pos_loc)
        GL.glDisableVertexAttribArray(self._tex_loc)
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, 0)
        GL.glBindTexture(GL.GL_TEXTURE_2D, 0)
        prog.release()


class FramebufferObject(QQuickFramebufferObject):
    """GUI-thread half: the QML item. Holds the native frame slot."""

    _updateRequested = pyqtSignal()

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self.slot = sdk.FrameSlot()
        self._renderer: OpenGLDisplay | None = None
        self._initialized = False
        # C++ updatePending: at most one queued repaint request at a time.
        self._update_pending = False
        self._update_lock = threading.Lock()
        # Frames arrive on the native processing thread; the queued signal
        # moves the scene-graph update onto this item's GUI thread.
        self._updateRequested.connect(self._apply_update, Qt.QueuedConnection)

    def createRenderer(self):  # noqa: N802 - Qt API; called on the render thread
        # Qt takes ownership of the returned renderer and may delete it (e.g.
        # when the scene graph is invalidated) and ask again, so always hand
        # out a new one. All frame state lives in the slot, so nothing is lost;
        # the slot is flagged so the new renderer builds its GL objects afresh.
        renderer = OpenGLDisplay(self.slot)
        if self._renderer is not None:
            self.slot.initDrawBuffer(self.slot.size)  # raises the slot's GL-reset flag
        self._renderer = renderer
        self._initialized = True
        self.slot.fboInitialized = True
        return renderer

    # ---- API used by PreviewController (mirrors the C++ inline methods) -----
    def isFboInitialized(self) -> bool:
        return self._initialized

    def setData(self, width: int, height: int, pixfmt: int) -> int:
        return self.slot.setData(width, height, pixfmt)

    def initDrawBuffer(self, size: int) -> int:
        return self.slot.initDrawBuffer(size)

    def displayVideoFrame(self, data) -> None:
        if self.slot.displayVideoFrame(data) == 1:
            self.request_update()

    def request_update(self) -> None:
        """Thread-safe repaint request (queued to the GUI thread).

        Like the C++ displayVideoFrame(), keeps at most one GUI-thread repaint
        request pending. At camera rates above the display refresh, extra
        queued events only add GUI work; the renderer always uploads the
        newest frame in the slot when the pending update is processed.
        """
        with self._update_lock:
            if self._update_pending:
                return
            self._update_pending = True
        self._updateRequested.emit()

    def _apply_update(self) -> None:
        self.update()
        with self._update_lock:
            self._update_pending = False

    # (The C++ FramebufferObject::clearShader() has no callers; not ported.)

    def cleanOpenGLDisplay(self) -> bool:
        ok = self.slot.cleanOpenGLDisplay()
        tslog.log_info(1, "cleanOpenGLDisplay called")
        return ok

    def stopFrame(self) -> int:
        self._initialized = False
        if self._renderer is not None:
            self.slot.fboInitialized = False
            return self.slot.stopFrame()
        return 0

    def startStream(self) -> int:
        self._initialized = True
        if self._renderer is not None:
            self.slot.fboInitialized = True
            return 1
        return 0
