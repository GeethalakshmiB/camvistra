import QtQuick 2.12
import QtQuick.Window 2.12

MouseArea {
    id: resizeArea
    property var targetWindow
    property int edges: 0
    property point pressLocal: Qt.point(0, 0)
    property rect initialGeometry: Qt.rect(0, 0, 0, 0)
    property bool manualResize: false

    z: 30000
    enabled: targetWindow && (Qt.platform.os === "windows"
			 ? targetWindow.windowsCustomMaximized !== true
			 : true)
    acceptedButtons: Qt.LeftButton

    // Returns true if a window coordinate is finite and not near the -32768 sentinel that
    // Qt's Windows frameless backend reports transiently.
    function validPos(value) {
        return isFinite(value) && value > -30000 && value < 30000
    }

    // Returns true if a window dimension is finite, >= minValue and below 30000.
    function validSize(value, minValue) {
        return isFinite(value) && value >= minValue && value < 30000
    }

    onPressed: {
		// A Linux maximized window has no native frame because this window is
		// frameless. Restore it here and keep the pressed edge under the pointer
		// so the same drag immediately begins resizing.
		if (Qt.platform.os !== "windows"
				&& targetWindow.visibility === Window.Maximized) {
			var pressGlobalX = targetWindow.x + mouse.x
			var pressGlobalY = targetWindow.y + mouse.y
			var normalWidth = Math.max(targetWindow.minimumWidth,
					Math.round(Screen.desktopAvailableWidth * 0.85))
			var normalHeight = Math.max(targetWindow.minimumHeight,
					Math.round(Screen.desktopAvailableHeight * 0.85))
			targetWindow.showNormal()
			targetWindow.width = normalWidth
			targetWindow.height = normalHeight
			targetWindow.x = (edges & Qt.RightEdge)
					? Math.round(pressGlobalX - normalWidth) : Math.round(pressGlobalX)
			targetWindow.y = (edges & Qt.BottomEdge)
					? Math.round(pressGlobalY - normalHeight) : Math.round(pressGlobalY)
		}

        // Resize is handled entirely in QML/JS rather than handed off to
        // targetWindow.startSystemResize(). On Windows, startSystemResize()
        // hands the drag to the OS's native non-client resize loop, which
        // doesn't cope well with a truly frameless window plus a dynamically
        // computed minimumWidth/minimumHeight -- it can corrupt the window
        // geometry to the -32768 sentinel, the same failure mode the title
        // bar's drag handling had via startSystemMove().
        manualResize = true
        // Use coordinates local to this MouseArea. screenX/screenY is not
        // consistently populated by all Linux/Wayland Qt backends.
        pressLocal = Qt.point(mouse.x, mouse.y)
        // Never trust the window's current geometry blindly -- if some other
        // interaction already left it invalid, capturing it here would just
        // keep copying the corruption forward on every edge that isn't part
        // of this particular drag.
        initialGeometry = Qt.rect(
            validPos(targetWindow.x) ? targetWindow.x : 0,
            validPos(targetWindow.y) ? targetWindow.y : 0,
            validSize(targetWindow.width, targetWindow.minimumWidth) ? targetWindow.width : targetWindow.minimumWidth,
            validSize(targetWindow.height, targetWindow.minimumHeight) ? targetWindow.height : targetWindow.minimumHeight)
    }

    onPositionChanged: {
        if (!manualResize || !pressed)
            return

		var dx = mouse.x - pressLocal.x
		var dy = mouse.y - pressLocal.y
		if (!isFinite(dx) || !isFinite(dy)
				|| Math.abs(dx) > 10000 || Math.abs(dy) > 10000) {
			manualResize = false
			return
		}
        var newX = initialGeometry.x
        var newY = initialGeometry.y
        var newWidth = initialGeometry.width
        var newHeight = initialGeometry.height

        if (edges & Qt.LeftEdge) {
            newWidth = Math.max(targetWindow.minimumWidth, initialGeometry.width - dx)
            newX = initialGeometry.x + initialGeometry.width - newWidth
        } else if (edges & Qt.RightEdge) {
            newWidth = Math.max(targetWindow.minimumWidth, initialGeometry.width + dx)
        }

        if (edges & Qt.TopEdge) {
            newHeight = Math.max(targetWindow.minimumHeight, initialGeometry.height - dy)
            newY = initialGeometry.y + initialGeometry.height - newHeight
        } else if (edges & Qt.BottomEdge) {
            newHeight = Math.max(targetWindow.minimumHeight, initialGeometry.height + dy)
        }

        if (!validPos(newX) || !validPos(newY)
                || !validSize(newWidth, targetWindow.minimumWidth)
                || !validSize(newHeight, targetWindow.minimumHeight))
            return

        targetWindow.x = newX
        targetWindow.y = newY
        targetWindow.width = newWidth
        targetWindow.height = newHeight
    }

    onReleased: manualResize = false
}
