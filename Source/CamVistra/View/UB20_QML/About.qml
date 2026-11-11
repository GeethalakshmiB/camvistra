// AboutWindow.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Window {
    id: aboutDialog
    width: 400 // 0.292 * screenWidth
    height: 200 //0.26 * screenHeight
    flags: Qt.Window | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "#0d1926"

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
                text: "About"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 15
                color: "white"
                font.family: "Helvetica"
                font.pixelSize: menuFontSize
                font.bold: true
            }

            // Close icon in the top-right corner
            Rectangle  {
                id: closeIconContainer
                width: expandedStateIconW
                height: expandedStateIconH
                color : abtMouseArea.containsMouse ? "#c90808" : "transparent"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 5
                anchors.rightMargin: 5

                Image {
                    id: x_about
                    anchors.fill: parent
                    source: "qrc:View/icons/closeSmall.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: abtMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        logController.displayMessage(verboseLogPriority, "Close About window\n")
                        aboutDialog.close()
                    }
                }

                ToolTip {
                    visible: abtMouseArea.containsMouse
                    background: Rectangle {
                        color: window.titleBarColor
                    }
                    contentItem: Text {
                        color: "white"
                        font.pixelSize: baseFontSize + 1
                        text: "Close About Window"
                    }
                }
            }

            // Make title bar draggable (but exclude close button area)
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: expandedStateIconW + 5
                property point lastMousePos: Qt.point(0, 0)
                onPressed: {
                    lastMousePos = Qt.point(mouseX, mouseY)
                }
                onPositionChanged: {
                    if (pressed) {
                        var delta = Qt.point(mouseX - lastMousePos.x, mouseY - lastMousePos.y)
                        aboutDialog.x += delta.x
                        aboutDialog.y += delta.y
                    }
                }
            }
        }

        RowLayout{
            id: aboutRow
            anchors.top: titleBar.bottom
            spacing : 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: titleBar.verticalCenter  // Vertically center in the row
            Column{
                id: appLoggo
                Layout.alignment: Qt.AlignLeft // Align to the left of the row

                Image{
                id: camVistraLogo
                    source: "qrc:View/icons/camVistraLogo.svg"
                    width: 80
                    height: 80
                    fillMode: Image.PreserveAspectFit
                }
            }

            Column {
                id: infoLayout

                Text {
                    id: product_name
                    font.pixelSize: abtFontSize
                    font.family: "Arial"
                    color: "#ffffff"
                    font.bold : true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    id: version
                    font.pixelSize: abtFontSize
                    font.family: "Arial"
                    color: "#ffffff"
                    font.bold : true
                    anchors.left : parent.left
                    anchors.leftMargin: 20
                }
            }
            Column {
                Layout.alignment: Qt.AlignLeft // Align to the left of the row
                Image {
                    id: econLogo
                    source: "qrc:View/icons/econLogo.svg"
                    width: 120
                    height: 120
                    fillMode: Image.PreserveAspectFit
                }
            }
        }
        RowLayout{

            id: copyrightRow
            anchors.top: aboutRow.bottom
            anchors.topMargin : 150
            anchors.horizontalCenter: parent.horizontalCenter
            Text {
                id: copyrights
                text: "Copyright © 2026  e-con Systems India Pvt. Limited"
                font.pixelSize: menuFontSize
                font.family: "Arial"
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    Component.onCompleted: {
        product_name.text = abtController.getApplicationName().toString()
        version.text = abtController.getApplicationVersionNumber().toString()
        // Center the window on the screen
        aboutDialog.x = (Screen.width - aboutDialog.width) / 2
        aboutDialog.y = (Screen.height - aboutDialog.height) / 2
    }
}
