"""About dialog data (port of CamVistra/Controller/src/AboutController.cpp).

QML context property: ``abtController``.
"""

from __future__ import annotations

from PyQt5.QtCore import QByteArray, QFile, QIODevice, QObject, QSettings, pyqtSlot


class AboutController(QObject):
    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        version = QSettings(":/View/JSON/release.ini", QSettings.IniFormat)
        version.beginGroup("release")
        self.app_name = str(version.value("applicationname", ""))
        self.app_ver_number = str(version.value("version", ""))
        self.app_rev_number = str(version.value("revision", ""))
        self.app_release_date = str(version.value("releasedate", ""))
        version.endGroup()

    @pyqtSlot(result=str)
    def getApplicationName(self) -> str:
        return self.app_name

    @pyqtSlot(result=str)
    def getApplicationVersionNumber(self) -> str:
        return self.app_ver_number

    def _read(self, path: str) -> QByteArray:
        f = QFile(path)
        if f.open(QIODevice.ReadOnly):
            data = f.readAll()
            f.close()
            return data
        return QByteArray(self.tr("Not available/Unable to read").encode("utf-8"))

    @pyqtSlot(result=QByteArray)
    def getCopyRight(self) -> QByteArray:
        return self._read(":/View/JSON/copyright.txt")

    @pyqtSlot(result=QByteArray)
    def getDescription(self) -> QByteArray:
        return self._read(":/View/JSON/description.txt")
