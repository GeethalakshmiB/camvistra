// AudioRecWindow.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Window {
    id: audioRecWindow
	property bool updatingVolumeFromDevice: false
    width: 450 // 0.329 * Screen.width
    height: 125 // 0.16 * Screen.height      // shorter — no OK/Cancel
    flags: Qt.Window | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "#0d1926"

    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2

	Connections {
		target : prevController
		// Handles prevController.audioVolumeChanged signal: moves the volume slider to the
		// device volume, flagging the update so the slider does not write it back.
		function onAudioVolumeChanged(volume){
			audioRecWindow.updatingVolumeFromDevice = true
			volumeSlider.value = volume
			audioRecWindow.updatingVolumeFromDevice = false
		}

		// Handles prevController.muteChanged signal: checks the Mute or Unmute radio button
		// to match the device mute state.
		function onMuteChanged(muteFlag){
			if(muteFlag){
				muteRadio.checked = true
				unmuteRadio.checked = false
			} else {
				muteRadio.checked = false
				unmuteRadio.checked = true
			}
		}
	}

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
                text: "Audio Recording Settings"
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
                color: audioRecCloseMouseArea.containsMouse ? "#c90808" : "transparent"
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
                    id: audioRecCloseMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: audioRecWindow.close()
                }

                ToolTip {
                    visible: audioRecCloseMouseArea.containsMouse
                    background: Rectangle { color: window.titleBarColor }
                    contentItem: Text {
                        color: "white"
                        font.pixelSize: 12
                        text: "Close Audio Recording Window"
                    }
                }
            }

            // Draggable title bar
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 25
                property point lastMousePos: Qt.point(0, 0)
                onPressed:  { lastMousePos = Qt.point(mouseX, mouseY) }
                onPositionChanged: {
                    if (pressed) {
                        var delta = Qt.point(mouseX - lastMousePos.x, mouseY - lastMousePos.y)
                        audioRecWindow.x += delta.x
                        audioRecWindow.y += delta.y
                    }
                }
            }
        }

        // ── Mutual exclusion for mute radio buttons ──────────────────────────
        ButtonGroup { id: muteButtonGroup }

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
            spacing: 18

            // ── Volume Row ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                height: 36

                Text {
                    text: "Volume:"
                    color: "white"
                    font.family: "Helvetica"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 60
                }

                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    from: 0
                    to: 100
                    stepSize: 1
                    value: 50
                    enabled: !muteRadio.checked

                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 200
                        implicitHeight: 4              // fixed visible track height
                        width: volumeSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: volumeSlider.enabled ? "#bdbebf" : "#606060"

                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            color: volumeSlider.enabled ? "#2087cc" : "#808080"
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        color: volumeSlider.enabled ? "#f0f0f0" : "#808080"
                        border.color: "#bdbebf"
                    }

                    onValueChanged: {
                        if (!audioRecWindow.updatingVolumeFromDevice && !muteRadio.checked)
                            prevController.setAudioRange(value)
                    }
                }

                Text {
                    text: Math.round(volumeSlider.value)
                    color: "white"
                    font.family: "Helvetica"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignRight
                }
            }

            // ── Mute Row ─────────────────────────────────────────────────────
			RowLayout {
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignHCenter
				spacing: 32

				// ── Unmute radio ─────────────────────────────────────────────
				Row {
					spacing: 8

					RadioButton {
						id: unmuteRadio
						checked: true
						ButtonGroup.group: muteButtonGroup

						indicator: Rectangle {
							implicitWidth: 16
							implicitHeight: 16
							radius: 8
							x: unmuteRadio.leftPadding
							y: parent.height / 2 - height / 2
							border.color: unmuteRadio.checked ? "#2087cc" : "#888888"
							border.width: 2
							color: unmuteRadio.checked ? "#2087cc" : "#ffffff"

							Rectangle {
								anchors.centerIn: parent
								width: 6
								height: 6
								radius: 3
								color: "#ffffff"
								visible: unmuteRadio.checked
							}
						}

						contentItem: Text {
							leftPadding: unmuteRadio.indicator.width + unmuteRadio.spacing
							text: "Unmute"
							color: "white"
							font.family: "Helvetica"
							font.pixelSize: 13
							verticalAlignment: Text.AlignVCenter
						}

						onClicked: prevController.setMute(false)
					}
				}

				// ── Mute radio ───────────────────────────────────────────────
				Row {
					spacing: 8

					RadioButton {
						id: muteRadio
						checked: false
						ButtonGroup.group: muteButtonGroup

						indicator: Rectangle {
							implicitWidth: 16
							implicitHeight: 16
							radius: 8
							x: muteRadio.leftPadding
							y: parent.height / 2 - height / 2
							border.color: muteRadio.checked ? "#2087cc" : "#888888"
							border.width: 2
							color: muteRadio.checked ? "#2087cc" : "#ffffff"

							Rectangle {
								anchors.centerIn: parent
								width: 6
								height: 6
								radius: 3
								color: "#ffffff"
								visible: muteRadio.checked
							}
						}

						contentItem: Text {
							leftPadding: muteRadio.indicator.width + muteRadio.spacing
							text: "Mute"
							color: "white"
							font.family: "Helvetica"
							font.pixelSize: 13
							verticalAlignment: Text.AlignVCenter
						}

						onClicked: prevController.setMute(true)
					}
				}
			}

            Item { Layout.fillHeight: true }
        }
    }

    // ── Init on open ─────────────────────────────────────────────────────────
    onVisibleChanged: {
        if (visible) {
            prevController.getAudioRange()
			prevController.getMute()

        }
    }
}
