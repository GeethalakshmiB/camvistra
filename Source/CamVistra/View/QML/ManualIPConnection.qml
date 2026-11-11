// ManualIPConnection.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Window {
    id: manualIPConnWin
    width: 450 //0.329 * Screen.width
    height: 150 // 0.195 * Screen.height
    flags: Qt.Window | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "#0d1926"

    property string path: ""
    property string deviceType: "Ethernet" 

    // Center window on screen
    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2

	onVisibleChanged: {
        if (visible) {
            ipAddress.text = ""
        }
    }

	// Returns true if ip is a valid dotted-decimal IPv4 address (each octet 0-255).
	function isValidIP(ip) {
		const regex = /^(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)){3}$/;
		return regex.test(ip);
	}

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
                text: "Manual IP Connection"
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
                id: closeIconWin
                width: 15
                height: 15
                color: closeWinMouseArea.containsMouse ? "#c90808" : "transparent"
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
                    id: closeWinMouseArea
                    objectName: "closeWinMouseArea"
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        manualIPConnWin.close()
                    }
                }

                ToolTip {
                    visible: closeWinMouseArea.containsMouse
                    background: Rectangle { color: window.titleBarColor }
                    contentItem: Text {
                        color: "white"
                        font.pixelSize: baseFontSize + 1
                        text: "Close Connection Window"
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
							manualIPConnWin.x += delta.x
							manualIPConnWin.y += delta.y
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
                height: ipPathLabel.implicitHeight + 12

                Label {
                    id: ipPathLabel
                    text: "Enter IP:"
                    color: "white"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    id: ipAddress
                    objectName: "ipAddress"
                    text: "" 
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: 120
                    height: Math.max(ipPathLabel.implicitHeight, 28)
                    color: "black"		

                    background: Rectangle {
                        color: "white"
                        radius: 4
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Row: Configure
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    id: confButton
                    objectName: "confButton"
                    text: "Configure"
                    font.pixelSize: 13
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 30

                    background: Rectangle {
                        id: confButtonBg
                        implicitWidth: 100
                        implicitHeight: 30
                        color: confButton.enabled ? "#2087cc" : "#505050"
                        border.color: confButton.enabled ? "#2087cc" : "#505050"
                        border.width: 1
                        radius: 4
                    }
					

                    contentItem: Text {
                        text: "Configure"
                        font: confButton.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                        elide: Text.ElideRight
                    }

                    onPressed: confButtonBg.color = "#1272b3"
                    onReleased: confButtonBg.color = "#2087cc"

                    /*onClicked: {
						if (!isValidIP(ipAddress.text)) {
							window.statusChanged("Failed::Please enter valid IP Address for manual IP connection")
							return
						}
						if(routecamOnvifController.checkIPConnection(ipAddress.text)){
							if(devController.addDeviceToTheList(ipAddress.text)){
								window.statusChanged("Success:: " + ipAddress.text + " is up and running")
							}
						} else {
							window.statusChanged("Failed:: Can't establish connection with " + ipAddress.text)
						}
                        manualIPConnWin.close()
                    }*/

                     onClicked: {
                        if (!isValidIP(ipAddress.text)) {
                            window.statusChanged("Failed::Please enter valid IP Address for manual IP connection")
                            return
                        }

                        if (deviceType === "Wi-Fi") {
                            // WiFi path
                            if (routecamOnvifController.checkIPConnection(ipAddress.text)) {
                                if (devController.addWifiDeviceToTheList(ipAddress.text)) {
                                    window.statusChanged("Success:: " + ipAddress.text + " is up and running")
                                }
                            } else {
                                window.statusChanged("Failed:: Can't establish connection with " + ipAddress.text)
                            }
                        } else {
                            // Ethernet path (existing)
                            if (routecamOnvifController.checkIPConnection(ipAddress.text)) {
                                if (devController.addDeviceToTheList(ipAddress.text)) {
                                    window.statusChanged("Success:: " + ipAddress.text + " is up and running")
                                }
                            } else {
                                window.statusChanged("Failed:: Can't establish connection with " + ipAddress.text)
                            }
                        }
                        manualIPConnWin.close()
                    }
                }
            }
        }
    }
}
