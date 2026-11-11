"""Product name of the application.

Both the C++ application (Source/CamVistra) and this Python port
(Source/CamVistraPy) are named CamVistra, and the shared QML/JS/JSON view
shows that name directly.

``VIEW_TEXT`` lets this build show different text than the shared view files
without editing them: ``tools/build_resources.py`` compiles patched copies of
the listed files into ``camvistra/qml_rc.py`` under the original ``qrc:``
paths. It is empty while both apps use the same name.
"""

from __future__ import annotations

APP_NAME = "CamVistra"

# Prefix of captured stills and recorded videos:
# <prefix>_<camera name>_<YYYY_MM_DD_HH_MM_SS>[_<burst n>].<ext>
CAPTURE_FILE_PREFIX = APP_NAME

# Logger.dll builds <Documents>/<name>/Log/<name>_Log_<time>.txt from this
# variable (default CamVistra); set by camvistra.native before the SDK loads.
LOGGER_APP_NAME_ENV = "CAMVISTRA_APP_NAME"

# qrc path -> exact (old, new) text replacements applied to the compiled copy.
VIEW_TEXT: dict[str, list[tuple[str, str]]] = {}
