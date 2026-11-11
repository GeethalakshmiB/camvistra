// VideoRecordDialog.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Window {
    id: vidRecWindow
    width: 450 // 0.329 * Screen.width
    height: 150 // 0.195 * Screen.height
    flags: Qt.Window | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "#0d1926"

    property string path: ""

    // Center window on screen
    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2

    Rectangle {
        anchors.fill: parent
        color: "#0d1926"
		border.color: "#263949"
		border.width: 1
        radius: 10

        /* ===== Title Bar ===== */
        Rectangle {
            id: titleBar
            width: parent.width
            height: 25
            color: "#08131f"
            radius: 10

            // Only round top corners
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
            }

            Text {
                text: "Video Record File Settings"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 15
                color: "white"
                font.family: "Helvetica"
                font.pixelSize: menuFontSize
                font.bold: true
            }

            // Close button
            Rectangle {
                id: closeIconVid
                width: 15
                height: 15
                color: closeVidMouseArea.containsMouse ? "#c90808" : "transparent"
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
                    id: closeVidMouseArea
                    objectName: "closeVidMouseArea"
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        path = tempVidRecPath
                        var message = "Video record path have been changed to : " + path + "\n";
                        logController.displayMessage(verboseLogPriority, message)
                        filePathWindow.videoPath = path
                        prevController.setVideoFolderPath(path)
                        vidRecWindow.close()
                    }
                }

                ToolTip {
                    visible: closeVidMouseArea.containsMouse
                    background: Rectangle { color: window.titleBarColor }
                    contentItem: Text {
                        color: "white"
                        font.pixelSize: baseFontSize + 1
                        text: "Close Video Record Window"
                    }
                }
            }

            // Drag window
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 25 // free close area
                property point lastMousePos: Qt.point(0,0)
                onPressed: lastMousePos = Qt.point(mouseX, mouseY)
                onPositionChanged:
				{
					if (pressed) {
							var delta = Qt.point(mouseX - lastMousePos.x, mouseY - lastMousePos.y)
							vidRecWindow.x += delta.x
							vidRecWindow.y += delta.y
					}
				}
            }
        }

        /* ===== Content Layout ===== */
        ColumnLayout {
            anchors.top: titleBar.bottom
            anchors.topMargin: 20
            anchors.margins: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 15

            // Row: label + path + browse
            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                height: filePathLbl.implicitHeight + 12

                Label {
                    id: filePathLbl
                    text: "File Path:"
                    color: "white"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    id: pathField
                    objectName: "pathField"
                    text: path
                    enabled: false
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: 120
                    height: Math.max(filePathLbl.implicitHeight, 28)
                    color: "black"		

                    background: Rectangle {
                        color: "white"
                        radius: 4
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: path
                }

                Button {
                    id: browseBtn
                    objectName: "browseBtn"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 28
                    Layout.minimumWidth: 28
                    Layout.preferredHeight: 28
                    Layout.minimumHeight: 28
                    padding: 2

                    background: Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: browseBtn.down ? "#1869a3"
                              : browseBtn.hovered ? "#2f97e6"
                              : "#2087cc"
                    }

                    contentItem: Image {
                        anchors.centerIn: parent
                        source: "qrc:View/icons/browseFolder.svg"
                        width: 16
                        height: 16
                        fillMode: Image.PreserveAspectFit
                    }

                    onClicked: { 
						window.vidRecFolderPath()
					}

                    ToolTip.visible: hovered
                    ToolTip.text: "Browse for folder"
                }
            }

            Item { Layout.fillHeight: true }

            // Row: OK + Cancel
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
                        implicitWidth: 100
                        implicitHeight: 30
                        color: okButton.enabled ? "#2087cc" : "#505050"
                        border.color: okButton.enabled ? "#2087cc" : "#505050"
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

                    onPressed: okButtonBg.color = "#1272b3"
                    onReleased: okButtonBg.color = "#2087cc"

                    onClicked: {
                        tempVidRecPath = path
                        var message = "Video record path have been changed to : " + path + "\n";
                        logController.displayMessage(verboseLogPriority, message)
                        vidRecWindow.close()
                    }

                    enabled: pathField.text !== ""
                }

                Button {
                    id: cancelButton
                    objectName: "cancelButton"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30
                    text: "Cancel"
                    font.pixelSize: 13

                   background: Rectangle {
                        id: cancelButtonBg
                        implicitWidth: 100
                        implicitHeight: 30
                        color: okButton.enabled ? "#2087cc" : "#505050"
                        border.color: okButton.enabled ? "#2087cc" : "#505050"
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

                    onPressed: cancelButtonBg.color = "#1272b3"
                    onReleased: cancelButtonBg.color = "#2087cc"

                    onClicked: {
                        path = tempVidRecPath
                        var message = "Video record path have been changed to : " + path + "\n";
                        logController.displayMessage(verboseLogPriority, message)
                        filePathWindow.videoPath = path
                        prevController.setVideoFolderPath(path)
                        vidRecWindow.close()
                    }
                }
            }
        }
    }
}
