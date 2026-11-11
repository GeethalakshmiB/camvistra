// FilePathWindow.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Window {
    id: filePathWindow
    width: 450 // 0.329 * Screen.width
    height: 215 //  0.28 * Screen.height
    flags: Qt.Window | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "#0d1926"

    property string stillPath: ""
    property string videoPath: ""

    // Center window on screen
    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2

    // When this window is shown, raise it
    onVisibleChanged: {
        if (visible) {
            filePathWindow.raise()
            filePathWindow.requestActivate()
        }
    }

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
                text: "File Path Settings"
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
                color: filePathMouseArea.containsMouse ? "#c90808" : "transparent"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 5
                anchors.rightMargin: 5

                Image {
                    id: x_FilePath
                    anchors.fill: parent
                    source: "qrc:View/icons/closeSmall.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: filePathMouseArea
                    objectName: "filePathMouseArea"
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // Revert to temp values on close
                        stillPath = tempStillPath
                        videoPath = tempVidRecPath

                        stillCaptureWindow.path = tempStillPath
                        vidRecWindow.path = tempVidRecPath
                        filePathWindow.close()
                    }
                }

                ToolTip {
                    visible: filePathMouseArea.containsMouse
                    background: Rectangle {
                        color: window.titleBarColor
                    }
                    contentItem: Text {
                        color: "white"
                        font.pixelSize: baseFontSize + 1
                        text: "Close File Path Window"
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
                        filePathWindow.x += delta.x
                        filePathWindow.y += delta.y
                    }
                }
            }
        }

        // Main content layout
        ColumnLayout {
            anchors.top: titleBar.bottom
            anchors.topMargin: 15
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 20
            spacing: 15

            // Still File Path Row
            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                height: stillPathLbl.implicitHeight + 12

                Label {
                    id: stillPathLbl
                    text: "Still File Path:"
                    color: "white"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    id: stillPathField
                    objectName: "stillPathField"
                    text: stillPath
                    enabled: false
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: 120
                    height: Math.max(stillPathLbl.implicitHeight, 28)
                    color: "black"

                    background: Rectangle {
                        color: "white"
                        radius: 4
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: stillPath
                }

                Button {
                    id: stillBrowseBtn
                    objectName: "stillBrowseBtn"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 28
                    Layout.minimumWidth: 28
                    Layout.preferredHeight: 28
                    Layout.minimumHeight: 28
                    padding: 2

                    background: Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: stillBrowseBtn.down ? "#1869a3"
                              : stillBrowseBtn.hovered ? "#2f97e6"
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
                        logController.displayMessage(verboseLogPriority, "UI: Browse folder dialog opened for still capture\n")
                        window.folderPath()
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Browse for still capture folder"
                }
            }

            // Video File Path Row
            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                height: videoPathLbl.implicitHeight + 12

                Label {
                    id: videoPathLbl
                    text: "Video File Path:"
                    color: "white"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    id: videoPathField
                    objectName: "videoPathField"
                    text: videoPath
                    enabled: false
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: 120
                    height: Math.max(videoPathLbl.implicitHeight, 28)
                    color: "black"

                    background: Rectangle {
                        color: "white"
                        radius: 4
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: videoPath
                }

                Button {
                    id: videoBrowseBtn
                    objectName: "videoBrowseBtn"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 28
                    Layout.minimumWidth: 28
                    Layout.preferredHeight: 28
                    Layout.minimumHeight: 28
                    padding: 2

                    background: Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: videoBrowseBtn.down ? "#1869a3"
                              : videoBrowseBtn.hovered ? "#2f97e6"
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
                        logController.displayMessage(verboseLogPriority, "UI: Browse folder dialog opened for video record\n")
                        window.vidRecFolderPath()
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Browse for video recording folder"
                }
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
                        // Save the temp values
                        tempStillPath = stillPath
                        tempVidRecPath = videoPath

                        stillCaptureWindow.path = tempStillPath
                        vidRecWindow.path = tempVidRecPath
                        
                        var message = "File paths updated - Still: " + stillPath + ", Video: " + videoPath + "\n";
                        logController.displayMessage(verboseLogPriority, message)
                        filePathWindow.close()
                    }
                    
                    // Enable only if both paths are not empty
                    enabled: stillPathField.text !== "" && videoPathField.text !== ""
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
                        // Revert to temp values
                        stillPath = tempStillPath
                        videoPath = tempVidRecPath

                        stillCaptureWindow.path = tempStillPath
                        vidRecWindow.path = tempVidRecPath
                        
                        var message = "File path changes cancelled\n";
                        logController.displayMessage(verboseLogPriority, message)
                        filePathWindow.close()
                    }
                }
            }
        }
    }
}
