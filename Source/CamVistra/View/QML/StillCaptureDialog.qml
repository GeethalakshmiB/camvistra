// StillCaptureWindow.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Window {
    id: stillCaptureWindow
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

        // Custom title bar
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
                text: "Still Capture File Settings"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 15
                color: "white"
                font.family: "Helvetica"
                font.pixelSize: menuFontSize
                font.bold: true
            }
            
            // Close icon in the top-right corner
            Rectangle {
                id: closeIconCont
                width: 15
                height: 15
                color: stillCaptureMouseArea.containsMouse ? "#c90808" : "transparent"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 5
                anchors.rightMargin: 5

                Image {
                    id: x_stillCap
                    anchors.fill: parent
                    source: "qrc:View/icons/closeSmall.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: stillCaptureMouseArea
                    objectName: "stillCaptureMouseArea"
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        path = tempStillPath
                        var message = "Still capture path have been changed to : " + path + "\n";
                        logController.displayMessage(verboseLogPriority, message)
                        filePathWindow.stillPath = path
                        prevController.setStillFolderPath(path)
                        stillCaptureWindow.close()
                    }
                }

                ToolTip {
                    visible: stillCaptureMouseArea.containsMouse
                    background: Rectangle {
                        color: window.titleBarColor
                    }
                    contentItem: Text {
                        color: "white"
                        font.pixelSize: baseFontSize + 1
                        text: "Close Still Capture Window"
                    }
                }
            }
            
            // Make title bar draggable (but exclude close button area)
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 25  // Exclude close button area
                property point lastMousePos: Qt.point(0, 0)
                onPressed: {
                    lastMousePos = Qt.point(mouseX, mouseY)
                }
                onPositionChanged: {
                    if (pressed) {
                        var delta = Qt.point(mouseX - lastMousePos.x, mouseY - lastMousePos.y)
                        stillCaptureWindow.x += delta.x
                        stillCaptureWindow.y += delta.y
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

            // Row: Label + TextField + Browse Button
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
                        window.folderPath()
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Browse for folder"
                }
            }

            // Spacer to push buttons to bottom
            Item {
                Layout.fillHeight: true
            }

            // Row: OK and Cancel buttons at the bottom
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
                        tempStillPath = path
                        var message = "Still capture path have been changed to : " + path + "\n";
                        logController.displayMessage(verboseLogPriority, message)
                        stillCaptureWindow.close()
                    }
                    
                    // Enable only if path is not empty
                    enabled: pathField.text !== ""
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
                        path = tempStillPath
                        var message = "Still capture path have been changed to : " + path + "\n";
                        logController.displayMessage(verboseLogPriority, message)
                        filePathWindow.stillPath = path
                        prevController.setStillFolderPath(path)
                        stillCaptureWindow.close()
                    }
                }
            }
        }
    }
}
