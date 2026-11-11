// WifiContextDialog.qml
import QtQuick 2.12
import QtQuick.Controls 2.12

Dialog {
    id: wifiContextDialog

    property real clickX: 0
    property real clickY: 0

    parent: Overlay.overlay
    x: clickX
    y: clickY

    width: 160
    height: menuItemHeight + 10

    padding: 4
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: "#0d1926"
        border.color: "#263949"
        border.width: 1
        radius: 4
    }

    contentItem: Column {
        spacing: 0

        Rectangle {
            id: addWifiDeviceRow
            width: wifiContextDialog.width - 8
            height: menuItemHeight
            color: addWifiMouseArea.containsMouse ? "#12365a" : "#0d1926"
            radius: 3

            Behavior on color { ColorAnimation { duration: 100 } }

            Row {
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10

                Text {
                    text: "Add Device"
                    font.pixelSize: menuFontSize + 1
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: addWifiMouseArea
                objectName: "addWifiMouseArea"
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    wifiContextDialog.close()
                    manualIPConnWin.deviceType = "Wi-Fi"   // set mode
                    manualIPConnWin.show()
                    manualIPConnWin.raise()
                }
            }
        }
    }
}
