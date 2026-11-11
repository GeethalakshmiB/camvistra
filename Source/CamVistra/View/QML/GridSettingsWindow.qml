// GridSettingsWindow.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Window {
    id: gridSettingsWindow
    width: 450 //0.329 * Screen.width
    height: 215 // 0.28 * Screen.height
    flags: Qt.Window | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "#0d1926"

    // Tracks the last committed selection (0=Off, 1=RuleOfThirds, 2=Center, 3=Square, 4=GoldenRatio)
    property int   lastCommittedIndex: 0
    property color gridColor:          "black"
    property color lastCommittedColor: "black"

    // Center window on screen
    x: (Screen.width  - width)  / 2
    y: (Screen.height - height) / 2

    onLastCommittedIndexChanged: {
        gridComboBox.currentIndex = lastCommittedIndex
    }

    // Commits the grid style flags (rule of thirds / center / square / golden ratio) for the
    // given combo box index; index 0 clears all flags (no grid).
    function applyFlags(index) {
        isRuleOfThirdsGrid = (index === 1)
        isCenterGrid       = (index === 2)
        isSquareGrid       = (index === 3)
        isGoldenRatioGrid  = (index === 4)
    }

    // Live-previews the grid style while the combo box selection changes, using the same
    // index mapping as applyFlags() (1 thirds, 2 center, 3 square, 4 golden ratio).
    function previewFlags(index) {
        isRuleOfThirdsGrid = (index === 1)
        isCenterGrid       = (index === 2)
        isSquareGrid       = (index === 3)
        isGoldenRatioGrid  = (index === 4)
    }

    // Discards uncommitted changes: restores the last committed combo index and colour and
    // re-applies the committed grid flags (used on Cancel / close).
    function revertComboBox() {
        gridComboBox.currentIndex = lastCommittedIndex
        gridColor                 = lastCommittedColor
        applyFlags(lastCommittedIndex) 
    }

    // ── Inline Color Picker Popup ─────────────────────────────────────────
    Popup {
        id: colorPickerPopup
        objectName: "colorPickerPopup"

        // Position below the swatch button; re-anchored at open time
        x: colorPreviewSwatch.x + 80
        y: colorPreviewSwatch.y + colorPreviewSwatch.height + 4

        width:  260
        height: 140
        padding: 0
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property color selectedColor: Qt.hsva(hueValue, satValue, valValue, 1.0)
        property real  hueValue: 0.0
        property real  satValue: 1.0
        property real  valValue: 0.0

        // Initialises the picker's hue/saturation/value from colour c (hue clamped to 0 for
        // achromatic colours whose hsvHue is -1).
        function loadColor(c) {
            hueValue = c.hsvHue < 0 ? 0 : c.hsvHue
            satValue = c.hsvSaturation
            valValue = c.hsvValue
        }

        onSelectedColorChanged: {
            gridSettingsWindow.gridColor = selectedColor
        }

        background: Rectangle {
            color: titleBar.color
            border.color: "#555555"
            border.width: 1
            radius: 6
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // ── SV Box ───────────────────────────────────────────────────
            Item {
                id: svBox
                Layout.fillWidth: true
                height: 100

                Rectangle {
                    anchors.fill: parent
                    color: Qt.hsva(colorPickerPopup.hueValue, 1.0, 1.0, 1.0)
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

                // Crosshair cursor
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                    x: colorPickerPopup.satValue * svBox.width  - width  / 2
                    y: (1.0 - colorPickerPopup.valValue) * svBox.height - height / 2

                    Rectangle {
                        width: 6; height: 6; radius: 3
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: "black"
                        border.width: 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    onPressed:         updateSV(mouseX, mouseY)
                    onPositionChanged: if (pressed) updateSV(mouseX, mouseY)
                    function updateSV(mx, my) {
                        colorPickerPopup.satValue = Math.max(0, Math.min(1, mx / svBox.width))
                        colorPickerPopup.valValue = Math.max(0, Math.min(1, 1.0 - my / svBox.height))
                    }
                }
            }

            // ── Hue Slider ───────────────────────────────────────────────
            Item {
                id: hueSlider
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

                // Hue thumb
                Rectangle {
                    width: 6
                    height: parent.height + 4
                    radius: 3
                    color: "white"
                    border.color: "#333333"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    x: colorPickerPopup.hueValue * hueSlider.width - width / 2
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    onPressed:         colorPickerPopup.hueValue = Math.max(0, Math.min(0.9999, mouseX / hueSlider.width))
                    onPositionChanged: if (pressed) colorPickerPopup.hueValue = Math.max(0, Math.min(0.9999, mouseX / hueSlider.width))
                }
            }
        }
    }
    // ─────────────────────────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: "#0d1926"
		border.color: "#263949"
		border.width: 1
        radius: 10

        // Custom title bar
        Rectangle {
            id: titleBar
            width: parent.width
            height: 25
            color: "#08131f"
            radius: 10

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
            }

            Text {
                text: "Grid Settings"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 15
                color: "white"
                font.family: "Helvetica"
                font.pixelSize: menuFontSize
                font.bold: true
            }

            Rectangle {
                id: closeIconCont
                width: 15; height: 15
                color: gridCloseMouseArea.containsMouse ? "#c90808" : "transparent"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 5
                anchors.rightMargin: 5

                Image {
                    anchors.fill: parent
                    source: "qrc:View/icons/closeSmall.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: gridCloseMouseArea
                    objectName: "gridCloseMouseArea"
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        revertComboBox()
                        gridSettingsWindow.close()
                    }
                }

                ToolTip {
                    visible: gridCloseMouseArea.containsMouse
                    background: Rectangle { color: window.titleBarColor }
                    contentItem: Text {
                        color: "white"
                        font.pixelSize: baseFontSize + 1
                        text: "Close Grid Settings"
                    }
                }
            }

            // Draggable title bar
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 25
                property point lastMousePos: Qt.point(0, 0)
                onPressed:         lastMousePos = Qt.point(mouseX, mouseY)
                onPositionChanged: {
                    if (pressed) {
                        var delta = Qt.point(mouseX - lastMousePos.x, mouseY - lastMousePos.y)
                        gridSettingsWindow.x += delta.x
                        gridSettingsWindow.y += delta.y
                    }
                }
            }
        }

        // Main content layout
        ColumnLayout {
            anchors.top: titleBar.bottom
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 20
            spacing: 15

            // ── Row: Label + ComboBox ─────────────────────────────────────
            RowLayout {
                spacing: 10
                Layout.fillWidth: true

                Label {
                    text: "Grid :"
                    color: "white"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }

                ComboBox {
                    id: gridComboBox
                    objectName: "gridComboBox"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: menuItemHeight
                    currentIndex: 0

                    onCurrentIndexChanged: {
                        gridSettingsWindow.previewFlags(currentIndex)  
                        var idMap = ["gridOff", "ruleOfThirdsGrid", "centerGrid", 
                                    "goldenRatioGrid", "squareGrid"]
                        logController.expandedGridItem(idMap[currentIndex])
                    }

                    model: [
                        "Off",
                        "Rule of Thirds Grid",
                        "Center Grid",
                        "Square Grid",
                        "Golden Ratio Grid"
                    ]

                    indicator: Item {
                        width: 14; height: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter

                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.beginPath()
                                ctx.moveTo(2, 4)
                                ctx.lineTo(width - 2, 4)
                                ctx.lineTo(width / 2, height - 2)
                                ctx.closePath()
                                ctx.fillStyle = "#000000"
                                ctx.fill()
                            }
                        }
                    }

                    delegate: ItemDelegate {
                        width: gridComboBox.width
                        height: gridComboBox.height

                        contentItem: Text {
                            text: modelData
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 12
                            color: "black"
                            leftPadding: 8
                        }

                        background: Rectangle {
                            color: hovered ? "#2087cc" : "white"
                            radius: hovered ? 4 : 0
                        }
                    }

                    popup: Popup {
                        y: gridComboBox.height
                        width: gridComboBox.width
                        padding: 0
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: gridComboBox.delegateModel
                        }
                        background: Rectangle {
                            color: "white"
                            border.color: "#000000"
                            border.width: 1
                            radius: 0
                        }
                    }

                    background: Rectangle {
                        implicitWidth: 120
                        implicitHeight: menuItemHeight
                        radius: 6
                        color: "white"
                        border.width: 1
                        border.color: "#000000"
                    }

                    contentItem: Text {
                        text: gridComboBox.displayText
                        font.family: "Arial"
                        font.pixelSize: baseFontSize
                        font.bold: false
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        color: "black"
                        leftPadding: 8
                        rightPadding: 8
                    }
                }
            }

            // ── Row: Grid Color ───────────────────────────────────────────
            RowLayout {
                spacing: 10
                Layout.fillWidth: true

                Label {
                    text: "Grid Color :"
                    color: "white"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }

                // Swatch — click to open picker
                Rectangle {
                    id: colorPreviewSwatch
                    objectName: "colorPreviewSwatch"
                    width: 32
                    height: 24
                    radius: 4
                    color: gridSettingsWindow.gridColor
                    border.color: colorPickerPopup.visible ? "#2087cc" : "#888888"
                    border.width: colorPickerPopup.visible ? 2 : 1
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (colorPickerPopup.visible) {
                                colorPickerPopup.close()
                            } else {
                                colorPickerPopup.loadColor(gridSettingsWindow.gridColor)
                                colorPickerPopup.open()
                            }
                        }
                    }
                }

                // Hex label
                Text {
                    text: gridSettingsWindow.gridColor.toString().substring(0, 7).toUpperCase()
                    color: "white"
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignVCenter
                }

                // "Pick Color" hint text
                Text {
                    text: "▲ Pick Color"
                    color: "#2087cc"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (colorPickerPopup.visible) {
                                colorPickerPopup.close()
                            } else {
                                colorPickerPopup.loadColor(gridSettingsWindow.gridColor)
                                colorPickerPopup.open()
                            }
                        }
                    }
                }
            }

            // Spacer
            Item { Layout.fillHeight: true }

            // ── Row: OK / Cancel ──────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    id: okButton
                    objectName: "okButton"
                    text: "OK"
                    font.pixelSize: 13
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30

                    background: Rectangle {
                        id: okButtonBg
                        implicitWidth: 100; implicitHeight: 30
                        color: "#2087cc"
                        border.color: "#2087cc"
                        border.width: 1
                        radius: 4
                    }

                    contentItem: Text {
                        text: "OK"
                        font: okButton.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                        elide: Text.ElideRight
                    }

                    onPressed:  okButtonBg.color = "#1272b3"
                    onReleased: okButtonBg.color = "#2087cc"

                    onClicked: {
                        colorPickerPopup.close()
                        lastCommittedIndex = gridComboBox.currentIndex
                        lastCommittedColor = gridSettingsWindow.gridColor
                        applyFlags(lastCommittedIndex)
                        gridSettingsWindow.close()
                    }
                }

                Button {
                    id: cancelButton
                    objectName: "cancelButton"
                    text: "Cancel"
                    font.pixelSize: 13
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30

                    background: Rectangle {
                        id: cancelButtonBg
                        implicitWidth: 100; implicitHeight: 30
                        color: "#2087cc"
                        border.color: "#2087cc"
                        border.width: 1
                        radius: 4
                    }

                    contentItem: Text {
                        text: "Cancel"
                        font: cancelButton.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                        elide: Text.ElideRight
                    }

                    onPressed:  cancelButtonBg.color = "#1272b3"
                    onReleased: cancelButtonBg.color = "#2087cc"

                    onClicked: {
                        colorPickerPopup.close()
                        revertComboBox()
                        gridSettingsWindow.close()
                    }
                }
            }
        }
    }
}
