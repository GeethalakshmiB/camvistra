import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import HistogramQuickItem 1.0

Rectangle {
    id: histogramRoot

    property bool lightTheme: false
    property int histogramMode: 0
    property bool curvesChecked: false
    property string selectedCurveChannel: "red"
    property int selectionMode: histogramWindow ? histogramWindow.selectionMode : 0
    property color selectionColor: histogramWindow ? histogramWindow.selectionColor : "#20b7ff"
    property color pageColor: lightTheme ? "#ffffff" : "#07111d"
    property color panelColor: lightTheme ? "#f5f5f5" : "#0d1926"
    property color panelBorderColor: lightTheme ? "#cfcfcf" : "#263949"
    property color axisColor: lightTheme ? "#777777" : "#5f788d"
    property color gridColor: lightTheme ? "#dddddd" : "#172837"
    property color primaryTextColor: lightTheme ? "#202020" : "#dce6ef"
    property color secondaryTextColor: lightTheme ? "#505050" : "#b8c7d4"
    property color mutedTextColor: lightTheme ? "#707070" : "#71869a"
    property color offControlColor: lightTheme ? "#ffffff" : "#0e1b28"
    property color offBorderColor: lightTheme ? "#b8b8b8" : "#36536b"

    color: pageColor

    MouseArea {
        anchors.fill: parent
        visible: selectionColorPickerPopup.visible
        z: 1.5
        onClicked: selectionColorPickerPopup.close()
    }

    // ── Top control bar: wraps on narrow window sizes ─────────────────────────
    Item {
        id: topControlFlow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        z: 2
    }

    // Camera this histogram belongs to ("<name> (Camera N)"), in the free space
    // to the right of the selection-mode row
    Text {
        id: cameraTitle
        anchors.left: selectionControls.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: selectionControls.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: typeof cameraLabel !== "undefined" ? cameraLabel : ""
        color: histogramRoot.primaryTextColor
        font.pixelSize: 14
        font.bold: true
        elide: Text.ElideRight
        z: 2
    }

    // ── Histogram plot ────────────────────────────────────────────────────────
    HistogramQuickItem {
        id: histItem
        objectName: "histogramItem"
        lightTheme: histogramRoot.lightTheme
        histogramMode: histogramRoot.histogramMode
        anchors.left: parent.left
        anchors.leftMargin: 56
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.05
        anchors.top: selectionControls.bottom
        anchors.topMargin: 18
        height: Math.max(120, Math.min(parent.height * 0.62,
                                       infoPanel.y - y - 50))

        Component.onCompleted: {
            if (typeof histogramWindow !== "undefined")
                histogramWindow.registerHistogramItem(histItem)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: {
                var bin = Math.floor(mouse.x / width * 256)
                histItem.setHoverBin(Math.max(0, Math.min(255, bin)))
            }
            onExited: {
                histItem.setHoverBin(-1)
            }
        }
    }

    // ── Axis overlay (lines + tick labels) ───────────────────────────────────
    Item {
        id: axisOverlay
        anchors.fill: histItem
        z: 1

        // Y-axis line
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: histogramRoot.axisColor
        }

        // X-axis line
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: histogramRoot.axisColor
        }

        // Mid grid line
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: histogramRoot.gridColor
        }

        // Y-axis tick labels
        Text {
            anchors.right: parent.left
            anchors.rightMargin: 6
            anchors.top: parent.top
            anchors.topMargin: 2
            text: histItem.yAxisMax
            color: histogramRoot.secondaryTextColor
            font.pixelSize: 11
        }
        Text {
            anchors.right: parent.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(histItem.yAxisMax / 2)
            color: histogramRoot.mutedTextColor
            font.pixelSize: 10
        }
        Text {
            anchors.right: parent.left
            anchors.rightMargin: 6
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            text: "0"
            color: histogramRoot.secondaryTextColor
            font.pixelSize: 11
        }

        // X-axis tick labels (below the plot)
        Text {
            anchors.left: parent.left
            anchors.top: parent.bottom
            anchors.topMargin: 4
            text: "0"
            color: histogramRoot.secondaryTextColor
            font.pixelSize: 11
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 4
            text: "128"
            color: histogramRoot.secondaryTextColor
            font.pixelSize: 11
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.bottom
            anchors.topMargin: 4
            text: "255"
            color: histogramRoot.secondaryTextColor
            font.pixelSize: 11
        }
    }

    // ── X-axis title: "Pixel Intensity" ──────────────────────────────────────
    Text {
        anchors.horizontalCenter: histItem.horizontalCenter
        anchors.top: histItem.bottom
        anchors.topMargin: 22
        text: "Pixel Intensity"
        color: histogramRoot.primaryTextColor
        font.pixelSize: 11
        font.bold: true
    }

    // ── Y-axis title: "Pixel Count" (rotated, positioned on the left side) ─────
    Text {
        id: yAxisLabel
        text: "Pixel Count"
        color: histogramRoot.primaryTextColor
        font.pixelSize: 11
        font.bold: true
        rotation: -90
        transformOrigin: Item.Center
        anchors.left: parent.left
        anchors.leftMargin: -13
        anchors.verticalCenter: histItem.verticalCenter
    }

    // ── Info panel: Avg + current bin values ─────────────────────────────────
    Rectangle {
        id: infoPanel
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.horizontalCenter: histItem.horizontalCenter
        width: Math.min(340, Math.max(220, parent.width - 32))
        height: 44
        radius: 4
        color: histogramRoot.panelColor
        border.color: histogramRoot.panelBorderColor
        z: 2

        Column {
            anchors.centerIn: parent
            spacing: 3

            // Average row
            Text {
                width: infoPanel.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: histItem.monochrome
                    ? "Avg   Y " + histItem.averageAlpha.toFixed(1)
                    : "Avg   R " + histItem.averageRed.toFixed(1)
                    + "   G " + histItem.averageGreen.toFixed(1)
                    + "   B " + histItem.averageBlue.toFixed(1)
                    + (histItem.showAlpha ? "   A " + histItem.averageAlpha.toFixed(1) : "")
                color: histogramRoot.primaryTextColor
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            // Hover-bin row — always fixed width, shows "---" when not hovering
            Text {
                width: infoPanel.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: histItem.monochrome
                    ? (histItem.hoverBin >= 0
                        ? "Bin " + histItem.hoverBin + "   Y " + histItem.binAlpha
                        : "Bin ---   Y ---")
                    : histItem.hoverBin >= 0
                    ? "Bin " + histItem.hoverBin
                      + "   R " + histItem.binRed
                      + "   G " + histItem.binGreen
                      + "   B " + histItem.binBlue
                      + "   A " + histItem.binAlpha
                    : "Bin ---   R ---   G ---   B ---   A ---"
                color: histItem.hoverBin >= 0
                    ? histogramRoot.primaryTextColor
                    : histogramRoot.mutedTextColor
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    // ── Top control bar (row 1): Theme | Mode | Curves | Channel ─────────────

    // Theme (top-left)
    Rectangle {
        id: themeControls
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 6
        width: themeRow.implicitWidth + 14
        height: 30
        radius: 4
        color: histogramRoot.panelColor
        border.color: histogramRoot.panelBorderColor
        z: 2

        Row {
            id: themeRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Theme"
                color: histogramRoot.primaryTextColor
                font.pixelSize: 11
            }

            Repeater {
                model: [
                    { label: "Dark",  light: false },
                    { label: "Light", light: true  }
                ]
                delegate: Rectangle {
                    property bool selected: histogramRoot.lightTheme === modelData.light
                    objectName: modelData.label === "Dark" ? "btnDark" : "btnLight"
                    width: 42; height: 20; radius: 3
					color: selected ? "#0b84f3" : histogramRoot.offControlColor
                    border.width: 1
					border.color: selected ? "#0b84f3" : histogramRoot.offBorderColor
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: selected ? "white" : histogramRoot.primaryTextColor
                        font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: histogramRoot.lightTheme = modelData.light
                    }
                }
            }

        }
    }

    // Channel toggles (top-right) — no Avg/Bin text here any more
    Rectangle {
        id: channelControls
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 6
        width: channelRow.implicitWidth + 14
        height: 30
        radius: 4
        color: histogramRoot.panelColor
        border.color: histogramRoot.panelBorderColor
        z: 2

        ListModel {
            id: channelModel
            ListElement { label: "R"; channel: "red";   channelColor: "#ff4444" }
            ListElement { label: "G"; channel: "green"; channelColor: "#44cc66" }
            ListElement { label: "B"; channel: "blue";  channelColor: "#4488ff" }
            ListElement { label: "A"; channel: "alpha"; channelColor: "#bbbbbb" }
        }

        Row {
            id: channelRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                id: channelRepeater
                model: channelModel

                delegate: Rectangle {
                    id: channelBtn
                    objectName: "btnChannel" + label
                    property color accentColor: channelColor
                    property string channelName: channel
                    property bool channelAllowed: !histItem.monochrome || channelName === "alpha"
                    property bool isActive: histItem.monochrome
                        ? channelName === "alpha" && histItem.showAlpha
                        : histogramRoot.curvesChecked
                        ? (histogramRoot.selectedCurveChannel === channelName)
                        : (channelName === "red"   && histItem.showRed   ||
                           channelName === "green" && histItem.showGreen ||
                           channelName === "blue"  && histItem.showBlue  ||
                           channelName === "alpha" && histItem.showAlpha)

                    visible: channelAllowed
                    width: channelAllowed ? 34 : 0; height: 22; radius: 3
                    color: isActive
                        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.20)
                        : histogramRoot.offControlColor
                    border.width: 1
                    border.color: isActive ? accentColor : histogramRoot.offBorderColor

                    Rectangle {
                        width: 6; height: 6; radius: 3
                        anchors.left: parent.left
                        anchors.leftMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: accentColor
                        opacity: isActive ? 1.0 : 0.45
                    }

                    Text {
                        anchors.centerIn: parent
                        text: histItem.monochrome && channelName === "alpha" ? "Y" : label
                        color: isActive ? accentColor : histogramRoot.mutedTextColor
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (histItem.monochrome) {
                                histItem.showRed = false
                                histItem.showGreen = false
                                histItem.showBlue = false
                                histItem.showAlpha = true
                                histogramRoot.selectedCurveChannel = "alpha"
                                return
                            }

                            if (histogramRoot.curvesChecked) {
                                histogramRoot.selectedCurveChannel = channelName
                                histItem.showRed   = (channelName === "red")
                                histItem.showGreen = (channelName === "green")
                                histItem.showBlue  = (channelName === "blue")
                                histItem.showAlpha = (channelName === "alpha")
                            } else {
                                if (channelName === "red")
                                    histItem.showRed   = !histItem.showRed
                                else if (channelName === "green")
                                    histItem.showGreen = !histItem.showGreen
                                else if (channelName === "blue")
                                    histItem.showBlue  = !histItem.showBlue
                                else if (channelName === "alpha")
                                    histItem.showAlpha = !histItem.showAlpha
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: selectionControls
        anchors.top: topControlFlow.bottom
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.topMargin: 6
        width: Math.min(selectionRow.implicitWidth + 14, parent.width - 12)
        height: 30
        radius: 4
        color: histogramRoot.panelColor
        border.color: histogramRoot.panelBorderColor
        z: 2

        ButtonGroup { id: selectionModeGroup }

        Rectangle {
            id: selectionColorPickerPopup
            x: Math.max(0, Math.min(colorPreviewSwatch.x,
                                    histogramRoot.width - selectionControls.x - width - 6))
            y: selectionControls.height + 6
            width: 260
            height: 140
            visible: false
            z: 20
			color: "#0d1926"
			border.color: "#36536b"
            border.width: 1
            radius: 6

            property color selectedColor: Qt.hsva(hueValue, satValue, valValue, 1.0)
            property real hueValue: 0.55
            property real satValue: 0.86
            property real valValue: 1.0

            function open() {
                visible = true
            }

            function close() {
                visible = false
            }

            // Initialises the picker's hue/saturation/value from colour c (hue clamped to 0 for
            // achromatic colours whose hsvHue is -1).
            function loadColor(c) {
                hueValue = c.hsvHue < 0 ? 0 : c.hsvHue
                satValue = c.hsvSaturation
                valValue = c.hsvValue
            }

            // Applies the picked colour as the histogram selection colour and forwards it to the
            // native histogramWindow (if present) via setSelectionColor().
            function applySelectionColor() {
                histogramRoot.selectionColor = selectedColor
                if (typeof histogramWindow !== "undefined")
                    histogramWindow.setSelectionColor(selectedColor)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Item {
                    id: selectionSvBox
                    Layout.fillWidth: true
                    height: 100

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.hsva(selectionColorPickerPopup.hueValue, 1.0, 1.0, 1.0)
                        radius: 4
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#ffffffff" }
                            GradientStop { position: 1.0; color: "#00ffffff" }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#00000000" }
                            GradientStop { position: 1.0; color: "#ff000000" }
                        }
                    }
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: "transparent"
                        border.color: "white"
                        border.width: 2
                        x: selectionColorPickerPopup.satValue * selectionSvBox.width - width / 2
                        y: (1.0 - selectionColorPickerPopup.valValue) * selectionSvBox.height - height / 2

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.centerIn: parent
                            color: "transparent"
                            border.color: "black"
                            border.width: 1
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        onPressed: updateSV(mouseX, mouseY)
                        onPositionChanged: if (pressed) updateSV(mouseX, mouseY)
                        onReleased: selectionColorPickerPopup.applySelectionColor()
                        function updateSV(mx, my) {
                            selectionColorPickerPopup.satValue = Math.max(0, Math.min(1, mx / selectionSvBox.width))
                            selectionColorPickerPopup.valValue = Math.max(0, Math.min(1, 1.0 - my / selectionSvBox.height))
                        }
                    }
                }

                Item {
                    id: selectionHueSlider
                    Layout.fillWidth: true
                    height: 16

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.000; color: "#ff0000" }
                            GradientStop { position: 0.167; color: "#ffff00" }
                            GradientStop { position: 0.333; color: "#00ff00" }
                            GradientStop { position: 0.500; color: "#00ffff" }
                            GradientStop { position: 0.667; color: "#0000ff" }
                            GradientStop { position: 0.833; color: "#ff00ff" }
                            GradientStop { position: 1.000; color: "#ff0000" }
                        }
                    }
                    Rectangle {
                        width: 6
                        height: parent.height + 4
                        radius: 3
                        color: "white"
                        border.color: "#333333"
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter
                        x: selectionColorPickerPopup.hueValue * selectionHueSlider.width - width / 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        onPressed: selectionColorPickerPopup.hueValue = Math.max(0, Math.min(0.9999, mouseX / selectionHueSlider.width))
                        onPositionChanged: if (pressed) selectionColorPickerPopup.hueValue = Math.max(0, Math.min(0.9999, mouseX / selectionHueSlider.width))
                        onReleased: selectionColorPickerPopup.applySelectionColor()
                    }
                }
            }
        }

        Row {
            id: selectionRow
            anchors.centerIn: parent
            spacing: 8
            scale: Math.min(1.0, (selectionControls.width - 14) / implicitWidth)

            Repeater {
                model: [
                    { label: "Full Frame", mode: 0 },
                    { label: "ROI", mode: 1 },
                    { label: "Vertical Line", mode: 2 },
                    { label: "Horizontal Line", mode: 3 }
                ]

                delegate: RadioButton {
                    id: selectionRadio
                    objectName: "btnSelection" + modelData.label.replace(" ", "")
                    ButtonGroup.group: selectionModeGroup
                    text: modelData.label
                    checked: histogramRoot.selectionMode === modelData.mode
                    implicitHeight: 22
                    padding: 0
                    spacing: 4

                    indicator: Rectangle {
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        x: 0
                        y: parent.height / 2 - height / 2
                        color: histogramRoot.offControlColor
						border.color: selectionRadio.checked ? "#0b84f3" : histogramRoot.offBorderColor
                        border.width: 1

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.centerIn: parent
							color: "#0b84f3"
                            visible: selectionRadio.checked
                        }
                    }

                    contentItem: Text {
                        text: selectionRadio.text
                        color: histogramRoot.primaryTextColor
                        font.pixelSize: 10
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 18
                    }

                    onClicked: {
                        histogramRoot.selectionMode = modelData.mode
                        if (typeof histogramWindow !== "undefined")
                            histogramWindow.setSelectionMode(modelData.mode)
                    }
                }
            }

            Rectangle {
                id: colorPreviewSwatch
                width: 24
                height: 20
                radius: 3
                color: selectionColorPickerPopup.visible
                    ? selectionColorPickerPopup.selectedColor
                    : histogramRoot.selectionColor
                border.color: selectionColorPickerPopup.visible ? "#ffffff" : histogramRoot.offBorderColor
                border.width: selectionColorPickerPopup.visible ? 2 : 1
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (selectionColorPickerPopup.visible) {
                            selectionColorPickerPopup.close()
                        } else {
                            selectionColorPickerPopup.loadColor(histogramRoot.selectionColor)
                            selectionColorPickerPopup.open()
                        }
                    }
                }
            }
        }
    }

    // Curves (top-right area, left of channel panel)
    Rectangle {
        id: curvesControls
        anchors.top: parent.top
        anchors.right: channelControls.left
        anchors.rightMargin: 6
        anchors.topMargin: 6
        width: curvesRow.implicitWidth + 14
        height: 30
        radius: 4
        color: histogramRoot.panelColor
        border.color: histogramRoot.panelBorderColor
        z: 2

        Row {
            id: curvesRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Curves"
                color: histogramRoot.primaryTextColor
                font.pixelSize: 11
            }

            CheckBox {
                id: curvesToggle
                objectName: "curvesToggle"
                text: ""
                checked: histogramRoot.curvesChecked
                implicitWidth: 20
                implicitHeight: 20
                padding: 0
                property color curvesAccent: "#1e90d4"

                onCheckedChanged: {
                    histogramRoot.curvesChecked = checked
                    if (checked) {
                        histogramRoot.histogramMode = 2
                        histogramRoot.selectedCurveChannel = "red"
                        histItem.showRed   = true
                        histItem.showGreen = false
                        histItem.showBlue  = false
                        histItem.showAlpha = false
                    } else {
                        histogramRoot.histogramMode = 1
                        histItem.showRed   = true
                        histItem.showGreen = true
                        histItem.showBlue  = true
                    }
                }

                indicator: Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: curvesToggle.checked ? curvesToggle.curvesAccent : histogramRoot.offControlColor
                    border.color: curvesToggle.checked ? curvesToggle.curvesAccent : histogramRoot.offBorderColor
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: curvesToggle.checked ? "\u2713" : ""
                        font.pixelSize: 13
                        font.bold: true
                        color: curvesToggle.checked ? "#ffffff" : "#888888"
                    }
                }
            }
        }
    }

    // Mode
    Rectangle {
        id: styleControls
        anchors.top: parent.top
        anchors.right: curvesControls.left
        anchors.rightMargin: 6
        anchors.topMargin: 6
        width: styleRow.implicitWidth + 14
        height: 30
        radius: 4
        color: histogramRoot.panelColor
        border.color: histogramRoot.panelBorderColor
        z: 2

        Row {
            id: styleRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: histogramRoot.curvesChecked
                    ? [{ label: "Bars", mode: 0 }, { label: "Line", mode: 1 }, { label: "Fill", mode: 2 }]
                    : [{ label: "Bars", mode: 0 }, { label: "Line", mode: 1 }]

                delegate: Rectangle {
                    property bool selected: histogramRoot.histogramMode === modelData.mode
                    objectName: "btnStyle" + modelData.label
                    width: 38; height: 20; radius: 3
					color: selected ? "#0b84f3" : histogramRoot.offControlColor
                    border.width: 1
					border.color: selected ? "#0b84f3" : histogramRoot.offBorderColor
                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: selected ? "white" : histogramRoot.primaryTextColor
                        font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: histogramRoot.histogramMode = modelData.mode
                    }
                }
            }
        }
    }
}
