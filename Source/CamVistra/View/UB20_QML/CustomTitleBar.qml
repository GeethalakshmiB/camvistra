import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

Rectangle {
    id: titleBar
	signal maximizeRestoreRequested()
    property var targetWindow
    property point dragStart: Qt.point(0, 0)
    property point windowStart: Qt.point(0, 0)
    property bool manualDrag: false
	property real restoreX: NaN
	property real restoreY: NaN
	property real restoreWidth: NaN
	property real restoreHeight: NaN

	// Returns true if the window is maximized: uses the custom maximized flag on
	// Windows (frameless) and the native window visibility elsewhere.
	function isMaximized() {
		return Qt.platform.os === "windows"
				? targetWindow.windowsCustomMaximized
				: targetWindow.visibility === Window.Maximized
	}

	// Returns true if value is a finite, sane screen coordinate/size (rejects the
	// Win32 -32768 sentinel and other out-of-range values).
	function validGeometryValue(value) {
		// Qt's Windows frameless backend can transiently report -32768
		// (INT16_MIN, a native win32 "unset placement" sentinel) while a
		// manual maximize/restore transition is in flight. Reject anything
		// close to that sentinel so it never gets captured as a "normal"
		// restore position and permanently pins the window off-screen.
		return isFinite(value) && value > -30000 && value < 30000
	}

	// Stores the current window position and size as the restore geometry, but
	// only while not maximized and when the geometry values are valid.
	function rememberNormalGeometry() {
		if (!isMaximized()
				&& validGeometryValue(targetWindow.x)
				&& validGeometryValue(targetWindow.y)
				&& targetWindow.width >= targetWindow.minimumWidth
				&& targetWindow.height >= targetWindow.minimumHeight) {
			restoreX = targetWindow.x
			restoreY = targetWindow.y
			restoreWidth = targetWindow.width
			restoreHeight = targetWindow.height
		}
	}

	// Restores the window from maximized to the remembered geometry, falling back
	// to a centred 85% of the available desktop; the geometry is applied via
	// Qt.callLater so it lands after the native state transition finishes.
	function restoreNormalWindow() {
		var restoredWidth = validGeometryValue(restoreWidth)
				? restoreWidth : Math.round(Screen.desktopAvailableWidth * 0.85)
		var restoredHeight = validGeometryValue(restoreHeight)
				? restoreHeight : Math.round(Screen.desktopAvailableHeight * 0.85)
		var restoredX = validGeometryValue(restoreX) ? restoreX
				: Screen.virtualX + Math.round((Screen.desktopAvailableWidth - restoredWidth) / 2)
		var restoredY = validGeometryValue(restoreY) ? restoreY
				: Screen.virtualY + Math.round((Screen.desktopAvailableHeight - restoredHeight) / 2)

		if (Qt.platform.os !== "windows")
			targetWindow.showNormal()
		targetWindow.windowsCustomMaximized = false
		// Qt's Windows frameless backend can briefly restore to INT_MIN. Apply
		// our validated rectangle once the native state transition has finished.
		Qt.callLater(function() {
			targetWindow.width = restoredWidth
			targetWindow.height = restoredHeight
			targetWindow.x = restoredX
			targetWindow.y = restoredY
			targetWindow.raise()
			targetWindow.requestActivate()
		})
	}

	// Maximizes the window after saving the restore geometry. On Windows it sizes
	// the frameless window manually (1px short of the screen, see inline note);
	// on other platforms it uses showMaximized().
	function maximizeWindow() {
		rememberNormalGeometry()
		if (Qt.platform.os === "windows") {
			targetWindow.windowsCustomMaximized = true
			targetWindow.x = Screen.virtualX
			targetWindow.y = Screen.virtualY
			// Stay 1px short of the full available rect. Qt's Windows backend
			// silently promotes a frameless window to a real WS_MAXIMIZE style
			// whenever its geometry exactly matches the screen's available
			// rect, and since that promotion skips showMaximized(), Windows
			// never records a valid restore rect for it -- the next restore
			// then snaps to its uninitialized (-32768,-32768) sentinel. See
			// the matching fix in main.cpp's WindowsTitleBarEventFilter.
			targetWindow.width = Screen.desktopAvailableWidth - 1
			targetWindow.height = Screen.desktopAvailableHeight - 1
			targetWindow.show()
			targetWindow.raise()
			targetWindow.requestActivate()
		} else {
			targetWindow.showMaximized()
		}
	}

	// Restores a maximized window when the title bar is dragged, positioning it so
	// the cursor (screenX, screenY) stays at the same horizontal ratio of the bar.
	function restoreForDrag(screenX, screenY, ratio) {
		var restoredWidth = validGeometryValue(restoreWidth)
				? restoreWidth : Math.round(Screen.desktopAvailableWidth * 0.85)
		var restoredHeight = validGeometryValue(restoreHeight)
				? restoreHeight : Math.round(Screen.desktopAvailableHeight * 0.85)
		targetWindow.windowsCustomMaximized = false
		if (Qt.platform.os !== "windows")
			targetWindow.showNormal()
		targetWindow.width = restoredWidth
		targetWindow.height = restoredHeight
		targetWindow.x = Math.round(screenX - restoredWidth * ratio)
		targetWindow.y = Math.max(0, Math.round(screenY - titleBar.height / 2))
	}

	// Toggles between maximized and normal window state (maximize button /
	// title-bar double-click).
	function toggleMaximized() {
		if (isMaximized()) {
			restoreNormalWindow()
		} else {
			maximizeWindow()
		}
	}

	onMaximizeRestoreRequested: toggleMaximized()

    color: "#10283b"
    border.color: "#263747"
    border.width: 1
    z: 20000

    Text {
        text: "CamVistra"
        anchors.centerIn: parent
        color: "#dce6ef"
        font.pixelSize: Math.max(13, Math.round(titleBar.height * 0.42))
        font.bold: true
    }

    MouseArea {
		id: titleDragArea
        anchors.left: parent.left
        anchors.right: windowButtons.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        acceptedButtons: Qt.LeftButton
		property real restoreRatio: 0.5

        onPressed: {
            titleBar.manualDrag = false
			restoreRatio = mouse.x / Math.max(1, width)
			titleBar.dragStart = Qt.point(mouse.screenX, mouse.screenY)
			titleBar.windowStart = Qt.point(targetWindow.x, targetWindow.y)
        }

        onPositionChanged: {
			if (!pressed)
				return

			var dx = mouse.screenX - titleBar.dragStart.x
			var dy = mouse.screenY - titleBar.dragStart.y
			if (!isFinite(dx) || !isFinite(dy)
					|| Math.abs(dx) > 10000 || Math.abs(dy) > 10000)
				return
			if (!titleBar.manualDrag && Math.abs(dx) + Math.abs(dy) < 6)
				return

			// Dragging is handled entirely in QML/JS rather than handed off to
			// targetWindow.startSystemMove(). On Windows, startSystemMove()
			// makes the OS treat this area as a native caption, so a double
			// click here can trigger Windows' own native maximize/restore
			// (WM_SYSCOMMAND) independently of our onDoubleClicked handler,
			// racing the manual maximize/restore bookkeeping below and
			// corrupting the window geometry to the -32768 sentinel.

			if (!titleBar.manualDrag) {
                if (titleBar.isMaximized()) {
					titleBar.restoreForDrag(mouse.screenX, mouse.screenY, restoreRatio)
                }
                titleBar.dragStart = Qt.point(mouse.screenX, mouse.screenY)
                titleBar.windowStart = Qt.point(targetWindow.x, targetWindow.y)
                titleBar.manualDrag = true
            }

			if (titleBar.manualDrag) {
                targetWindow.x = titleBar.windowStart.x + mouse.screenX - titleBar.dragStart.x
                targetWindow.y = titleBar.windowStart.y + mouse.screenY - titleBar.dragStart.y
            }
        }

		onReleased: {
			titleBar.manualDrag = false
		}
		onCanceled: {
			titleBar.manualDrag = false
		}
        onDoubleClicked: {
            titleBar.manualDrag = false
			// The Windows C++ event filter performs one atomic QRect change and
			// consumes this event before it reaches QML.
			if (Qt.platform.os === "windows") {
				mouse.accepted = true
				return
			}
			titleBar.maximizeRestoreRequested()
        }
    }

    Row {
        id: windowButtons
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Repeater {
            model: [
                { symbol: "\u2212", action: "minimize" },
                { symbol: "", action: "maximize" },
                { symbol: "\u00d7", action: "close" }
            ]

            delegate: Rectangle {
				id: windowControl
                width: Math.max(42, Math.round(titleBar.height * 1.35))
                height: titleBar.height - 2
                color: controlArea.containsMouse
                       ? (modelData.action === "close" ? "#c42b1c" : "#17334d")
                       : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.symbol
                    color: "white"
                    font.pixelSize: modelData.action === "close" ? 22 : 17
					visible: modelData.action !== "maximize"
                }

				Item {
					anchors.centerIn: parent
					width: 16
					height: 16
					visible: modelData.action === "maximize"

					Rectangle {
						visible: !titleBar.isMaximized()
						x: 2; y: 2; width: 12; height: 12
						color: "transparent"
						border.color: "white"
						border.width: 1
					}

					Rectangle {
						visible: titleBar.isMaximized()
						x: 1; y: 4; width: 10; height: 9
						color: controlArea.containsMouse ? "#17334d" : "#10283b"
						border.color: "white"
						border.width: 1
						z: 2
					}

					Rectangle {
						visible: titleBar.isMaximized()
						x: 5; y: 1; width: 10; height: 9
						color: "transparent"
						border.color: "white"
						border.width: 1
						z: 1
					}
				}

                MouseArea {
                    id: controlArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.action === "minimize")
                            targetWindow.showMinimized()
                        else if (modelData.action === "maximize") {
							titleBar.maximizeRestoreRequested()
                        } else
                            targetWindow.close()
                    }
                }
            }
        }
    }
}
