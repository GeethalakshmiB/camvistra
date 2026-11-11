"""Feature switches shared by the Python port.

DIAGNOSTICS_ENABLED mirrors the C++ app, where every diagnostics call
(orphaned-session scan at start-up, per-camera sessions, FPS/latency/control
reports and the shutdown report) is commented out since commit 7334cc3c.
Set it to True to turn diagnostics back on in the Python app.
"""

DIAGNOSTICS_ENABLED = False
