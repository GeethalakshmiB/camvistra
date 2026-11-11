import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Dialog {
    id: validationDialog
    width: Math.max(300, error_msg.contentWidth + 40)   // dynamic width
    height: titleBar.height + error_msg.contentHeight + 40  // dynamic height
    modal: true
    // Keep dialog centered relative to its parent (if present) or the screen.
    x: (validationDialog.parent ? (validationDialog.parent.x + validationDialog.parent.width / 2) : (Screen.width / 2)) - width / 2
    y: (validationDialog.parent ? (validationDialog.parent.y + validationDialog.parent.height / 2) : (Screen.height / 2)) - height / 2

    background: Rectangle {
        color: "#0d1926"
		border.color: "#263949"
		border.width: 1
        radius: 10
    }

    contentItem: Item {
        anchors.fill: parent

        Rectangle {
            id: titleBar
            width: parent.width
            height: 25
			color: "#08131f"

            Text {
                text: "Warning"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 15
                color: "white"
                font.family: "Helvetica"
                font.pixelSize: menuFontSize
                font.bold: true
            }

            Item {
                width: parent.width
                height: parent.height

                Rectangle {
                    id: closeContainer
                    width: 15
                    height: 15
                    color: validationMouseArea.containsMouse ? "#c90808" : "transparent"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 5
                    anchors.rightMargin: 5

                    Image {
                        id: x_dialog
                        anchors.fill: parent
                        source: "qrc:View/icons/closeSmall.svg"
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: validationMouseArea
                        objectName: "validationMouseArea"
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: validationDialog.close()
                    }
                }
            }
        }

        Text {
            id: error_msg
            objectName: "error_msg"
            anchors.top: titleBar.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400 
            wrapMode: Text.WordWrap              // wrap if text exceeds width
            font.pixelSize: 14
            font.family: "Arial"
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    function sendTextMessage(msg) {
        error_msg.text = msg
    }

    
}
