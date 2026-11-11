import QtQuick 2.12
import QtQuick.Controls 2.12
Rectangle {
	   id:devRect
	   color:"#0d1926"
	   height: left_con_up.height
	    Rectangle {
		       
                id: deviceLabel
                height: menuItemHeight
				color: "#08131f"
				border.color: "#263949"
				border.width: 1
				radius: 0
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.leftMargin: 5
				anchors.rightMargin: 5
                anchors.top: parent.top
                anchors.topMargin: 5
				 Text {
					anchors.left: parent.left
					anchors.leftMargin: 10
					anchors.verticalCenter : parent.verticalCenter
                    font.family: "Helvetica"
                    font.pixelSize: menuFontSize + 1
                    font.bold: true
                    text: "Devices"
                    color: "#ffffff"
                }  
				Rectangle {
					id: imageBackground
					width: expandedStateIconW + 5
					height: expandedStateIconH + 5
					color: mouseArea.containsMouse ? "#c90808" : "transparent"
					anchors.right: deviceLabel.right
					anchors.rightMargin: 4
					anchors.verticalCenter : parent.verticalCenter
					visible: true

					Image {
						id: x_device
						source: "qrc:View/icons/closeSmall.svg"
						anchors.fill: parent
						fillMode: Image.PreserveAspectFit
					}

					MouseArea {
						id: mouseArea
						objectName: "closeDevicesMouseArea"
						anchors.fill: parent
						hoverEnabled: true
						onClicked: {
							logController.displayMessage(verboseLogPriority, "UI: Closed Devices Container\n");	
							handleCheckedChanged(closeLeftUp)
							closeLeftUp = !closeLeftUp
						}
				  }
				  ToolTip {
						visible : mouseArea.containsMouse
						background: Rectangle {
							color: window.titleBarColor
							border.color: window.titleBarColor
							border.width: 1
							radius: 4
						}
						contentItem: Text {
							color: "white"
							font.pixelSize: baseFontSize + 1
							text: "Close Device Window"
						}
				  }
			 }
           
		}
		Rectangle {
			id: deviceInnerRect
			width: parent.width -10
			x: devRect.x

			anchors.top: deviceLabel.bottom
			anchors.bottom: parent.bottom
			anchors.horizontalCenter: parent.horizontalCenter
			color: "#0d1926"

			clip: true   

			DeviceFlickable {
				anchors.fill: parent

				Devices {
					objectName: "devicesList"
					width: parent.width
				}
			}
		}	
 }
