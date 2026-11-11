"""OpenGL histogram renderers (port of HistogramRenderer.cpp / HistogramDisplay.cpp).

Both are ``QQuickFramebufferObject.Renderer`` subclasses that run on the Qt
Quick render thread. They use ``QOpenGLShaderProgram`` for the shaders and
PyOpenGL for buffers and draw calls, the same approach as
``camvistra/controls/opengl_display.py``. They need desktop OpenGL
(``Qt.AA_UseDesktopOpenGL``). Vertex data comes from ``geometry.py``.

Differences from the C++ code:

* No vertex array object. The C++ code uses QOpenGLVertexArrayObject,
  which Qt emulates on GL 2.0 anyway. Here the attribute pointers are set on
  every draw, which gives the same result in the 2.0 compatibility context
  the window requests.
* The VBO is re-uploaded only when the geometry changes. The C++ renderer
  re-allocates it on every render().
* ``createFramebufferObject`` is not overridden, so the FBO has no
  depth/stencil attachment (C++: CombinedDepthStencil). PyQt5 doesn't hand
  ownership of a returned QOpenGLFramebufferObject to Qt. Python would then
  delete an FBO that Qt already freed, or free one that Qt still uses. The
  histogram draws flat 2-D triangles with no depth or stencil test, so the
  output is the same.
"""

from __future__ import annotations

import ctypes

import numpy as np
from OpenGL import GL
from PyQt5.QtGui import QOpenGLShader, QOpenGLShaderProgram
from PyQt5.QtQuick import QQuickFramebufferObject

from camvistra import tslog
from camvistra.histogram import geometry
from camvistra.histogram.data import HistogramData

VERTEX_SHADER_RGBA = """attribute vec2 a_position;
attribute vec4 a_color;
varying vec4 v_color;
void main()
{
    gl_Position = vec4(a_position, 0.0, 1.0);
    v_color = a_color;
}
"""

FRAGMENT_SHADER_RGBA = """#ifdef GL_ES
precision mediump float;
#endif
varying vec4 v_color;
void main()
{
    gl_FragColor = v_color;
}
"""

VERTEX_SHADER_RGB = """attribute vec2 a_position;
attribute vec3 a_color;
varying vec3 v_color;
void main()
{
    gl_Position = vec4(a_position, 0.0, 1.0);
    v_color = a_color;
}
"""

FRAGMENT_SHADER_RGB = """#ifdef GL_ES
precision mediump float;
#endif
varying vec3 v_color;
void main()
{
    gl_FragColor = vec4(v_color, 1.0);
}
"""


class _GLProgram:
    """Shader program + VBO with interleaved position/colour attributes."""

    def __init__(self, vertex_src: str, fragment_src: str, color_components: int) -> None:
        self.ok = False
        self.program = QOpenGLShaderProgram()
        self.program.addShaderFromSourceCode(QOpenGLShader.Vertex, vertex_src)
        self.program.addShaderFromSourceCode(QOpenGLShader.Fragment, fragment_src)
        if not self.program.link():
            tslog.log_critical(0, f"Histogram shader link failed: {self.program.log()}")
            return
        self.pos_loc = self.program.attributeLocation("a_position")
        self.color_loc = self.program.attributeLocation("a_color")
        self.components = color_components
        self.stride = (2 + color_components) * 4
        self.vbo = int(GL.glGenBuffers(1))
        self.count = 0
        self.ok = True

    def upload(self, vertices: np.ndarray) -> None:
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, self.vbo)
        if vertices.size:
            GL.glBufferData(GL.GL_ARRAY_BUFFER, vertices.nbytes, vertices, GL.GL_DYNAMIC_DRAW)
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, 0)
        self.count = int(vertices.shape[0])

    def draw(self, blend: bool) -> None:
        if self.count == 0:
            return
        self.program.bind()
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, self.vbo)
        GL.glEnableVertexAttribArray(self.pos_loc)
        GL.glVertexAttribPointer(self.pos_loc, 2, GL.GL_FLOAT, GL.GL_FALSE, self.stride, None)
        GL.glEnableVertexAttribArray(self.color_loc)
        GL.glVertexAttribPointer(self.color_loc, self.components, GL.GL_FLOAT, GL.GL_FALSE,
                                 self.stride, ctypes.c_void_p(8))
        if blend:
            GL.glEnable(GL.GL_BLEND)
            GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA)
        GL.glDrawArrays(GL.GL_TRIANGLES, 0, self.count)
        if blend:
            GL.glDisable(GL.GL_BLEND)
        GL.glDisableVertexAttribArray(self.pos_loc)
        GL.glDisableVertexAttribArray(self.color_loc)
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, 0)
        self.program.release()

    def destroy(self) -> None:
        if self.ok and self.vbo:
            try:
                GL.glDeleteBuffers(1, [self.vbo])
            except Exception:  # no current context during teardown
                pass
            self.vbo = 0


class HistogramQuickRenderer(QQuickFramebufferObject.Renderer):
    """Render-thread half of HistogramQuickItem (HistogramRenderer.cpp)."""

    def __init__(self) -> None:
        super().__init__()
        self._gl: _GLProgram | None = None
        self._init_failed = False
        self.show_red = True
        self.show_green = True
        self.show_blue = True
        self.show_alpha = False
        self.light_theme = False
        self.histogram_mode = 0
        self.data = HistogramData()
        self.has_data = False
        self.geometry_dirty = True
        self.vertices = np.zeros((0, 6), dtype=np.float32)

    def synchronize(self, item) -> None:
        """Copy state from the item. Runs while the GUI thread is blocked."""
        flags = (item.showRed, item.showGreen, item.showBlue, item.showAlpha,
                 item.histogramMode)
        visibility_changed = flags != (self.show_red, self.show_green, self.show_blue,
                                       self.show_alpha, self.histogram_mode)
        theme_changed = item.lightTheme != self.light_theme
        (self.show_red, self.show_green, self.show_blue, self.show_alpha,
         self.histogram_mode) = flags
        self.light_theme = item.lightTheme
        if item.dataDirty():
            self.data = item.pendingData()
            item.clearDirty()
            self.has_data = True
            self.geometry_dirty = True
        if visibility_changed or theme_changed:
            self.geometry_dirty = True

    def _ensure_initialized(self) -> None:
        if self._gl is None and not self._init_failed:
            gl = _GLProgram(VERTEX_SHADER_RGBA, FRAGMENT_SHADER_RGBA, 4)
            if gl.ok:
                self._gl = gl
            else:
                self._init_failed = True

    def render(self) -> None:  # render thread, FBO bound
        self._ensure_initialized()
        fbo = self.framebufferObject()
        GL.glViewport(0, 0, fbo.width(), fbo.height())
        GL.glClearColor(*(geometry.LIGHT_CLEAR if self.light_theme else geometry.DARK_CLEAR))
        GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT)
        if self._gl is None:
            return
        if self.geometry_dirty and self.has_data:
            self.vertices = geometry.build_quick_vertices(
                self.data, self.show_red, self.show_green, self.show_blue, self.show_alpha,
                self.light_theme, self.histogram_mode)
            self._gl.upload(self.vertices)
            self.geometry_dirty = False
        self._gl.draw(blend=True)


class HistogramDisplayRenderer(QQuickFramebufferObject.Renderer):
    """Render-thread half of the legacy HistogramDisplay (C++ ``HistogramRenderer``)."""

    def __init__(self) -> None:
        super().__init__()
        self._gl: _GLProgram | None = None
        self._init_failed = False
        self.bins = ([], [], [], [], False)
        self.geometry_dirty = True

    def synchronize(self, item) -> None:
        self.bins = item.copyBins()
        self.geometry_dirty = True

    def render(self) -> None:
        if self._gl is None and not self._init_failed:
            gl = _GLProgram(VERTEX_SHADER_RGB, FRAGMENT_SHADER_RGB, 3)
            self._gl, self._init_failed = (gl, False) if gl.ok else (None, True)
        fbo = self.framebufferObject()
        GL.glViewport(0, 0, fbo.width(), fbo.height())
        GL.glClearColor(*geometry.DISPLAY_CLEAR)
        GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT)
        if self._gl is not None:
            if self.geometry_dirty:
                self._gl.upload(geometry.build_display_vertices(*self.bins))
                self.geometry_dirty = False
            self._gl.draw(blend=False)
        # The C++ renderer keeps requesting frames; preserved.
        self.update()

