// ZoomWindow.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Window {
    id: zoomWindow
    width: 341 // 0.25 * Screen.width
    height: 155
    flags: Qt.Window | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "#0d1926"

    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2

    Rectangle {
        anchors.fill: parent
        color: "#0d1926"
		border.color: "#263949"
		border.width: 1
        radius: 10

        // ── Title Bar ────────────────────────────────────────────────────────
        Rectangle {
            id: titleBar
            width: parent.width
            height: 25
            color: "#08131f"
            radius: 10

            // Square off the bottom corners
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
            }

            Text {
                text: "Zoom"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 15
                color: "white"
                font.family: "Helvetica"
                font.pixelSize: 13
                font.bold: true
            }

            Rectangle {
                id: closeIconCont
                width: 15
                height: 15
                color: zoomCloseMouseArea.containsMouse ? "#c90808" : "transparent"
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
                    id: zoomCloseMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: zoomWindow.close()
                }

                ToolTip {
                    visible: zoomCloseMouseArea.containsMouse
                    background: Rectangle { color: window.titleBarColor }
                    contentItem: Text {
                        color: "white"
                        font.pixelSize: 12
                        text: "Close Zoom Window"
                    }
                }
            }

            // ── Draggable title bar ───────────────────────────────────────────
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 25
                property point lastMousePos: Qt.point(0, 0)
                onPressed:  { lastMousePos = Qt.point(mouseX, mouseY) }
                onPositionChanged: {
                    if (pressed) {
                        var delta = Qt.point(mouseX - lastMousePos.x, mouseY - lastMousePos.y)
                        zoomWindow.x += delta.x
                        zoomWindow.y += delta.y
                    }
                }
            }
        }

        // ── Main Content ─────────────────────────────────────────────────────
        ColumnLayout {
            anchors.top: titleBar.bottom
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 20
            spacing: 0

            // ── Zoom Slider Row ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Zoom:"
                    color: "white"
                    font.family: "Helvetica"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 40
                }

                Slider {
                    id: zoomSlider
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    enabled: window.activeHistogramMode === 0 && window.zoomAllowed
                    from: 50
                    to: 500
                    stepSize: 25
                    value: window.zoom

                    background: Rectangle {
                        x: zoomSlider.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 200
                        implicitHeight: 4
                        width: zoomSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#bdbebf"

                        Rectangle {
                            width: zoomSlider.visualPosition * parent.width
                            height: parent.height
                            color: "#2087cc"
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: zoomSlider.leftPadding + zoomSlider.visualPosition * (zoomSlider.availableWidth - width)
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        color: "#f0f0f0"
                        border.color: "#bdbebf"
                    }

                    onValueChanged: {                  
                        window.zoom = value
                        applyZoomToPreview()
                    }
                }

                // ── Percentage label ──────────────────────────────────────────
                Text {
                    text: Math.round(zoomSlider.value) + "%"
                    color: "white"
                    font.family: "Helvetica"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                }

                // ── Reset button (100%) ───────────────────────────────────────
                Rectangle {
                    width: 30
                    height: 22
                    color: resetMouseArea.containsMouse ? "#2087cc" : "#171717"
                    border.color: "#555"
                    radius: 3
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "↺"
                        color: "white"
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: resetMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: window.zoomAllowed
                        onClicked: {
                            zoomSlider.value = 100
                            zoom = 100
                        }
                    }

                    ToolTip {
                        visible: resetMouseArea.containsMouse
                        background: Rectangle { color: window.titleBarColor }
                        contentItem: Text {
                            color: "white"
                            font.pixelSize: 12
                            text: "Reset to 100%"
                        }
                    }
                }

            }

			CheckBox {
				id: scrollbarCheckBox
				text: "Show scrollbars"
				checked: window.zoomScrollbarsEnabled
				spacing: 8
				Layout.topMargin: 10
				Layout.alignment: Qt.AlignLeft
				font.pixelSize: 13
				indicator: Rectangle {
					implicitWidth: checkBoxW
					implicitHeight: checkBoxH
					x: 0
					anchors.verticalCenter: parent.verticalCenter
					radius: 3
					color: scrollbarCheckBox.checked ? "#1e90d4" : "#161414"
					border.color: scrollbarCheckBox.checked ? "#1e90d4" : "#3a5a7a"
					border.width: 2
					Behavior on color { ColorAnimation { duration: 150 } }
					Behavior on border.color { ColorAnimation { duration: 150 } }
					Rectangle {
						anchors.fill: parent
						anchors.margins: 1
						radius: 2
						color: "transparent"
						border.color: scrollbarCheckBox.checked ? "#5ab4f0" : "transparent"
						border.width: 1
						opacity: 0.4
					}
					Text {
						anchors.centerIn: parent
						text: scrollbarCheckBox.checked ? "\u2713" : ""
						font.pixelSize: 13
						font.bold: true
						color: "#ffffff"
					}
				}
				contentItem: Text {
					text: scrollbarCheckBox.text
					color: "white"
					font.pixelSize: 13
					verticalAlignment: Text.AlignVCenter
					leftPadding: scrollbarCheckBox.indicator.width + scrollbarCheckBox.spacing
				}
				onToggled: {
					window.zoomScrollbarsEnabled = checked
					if (!checked) {
						// Cursor-wheel mode always starts from the neutral scale.
						window.zoom = 100
						applyZoomToPreview()
					}
				}
			}

            Item { Layout.fillHeight: true }
        }
    }
}
