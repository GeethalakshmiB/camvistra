import QtQuick 2.12
import QtQuick.Controls 2.12
Rectangle {
     id:wifiRect
	 height: right_con_up.height 
	  color:"#0d1926"
	  border.color: "#263949"
	  border.width: 1
	  property bool isResolutionChanged : false
       Rectangle {
                id: wifiLabel
                height: menuItemHeight
				color: "#08131f"
				border.color: "#263949"
				border.width: 1
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.leftMargin: 5
				anchors.rightMargin: 5
				anchors.top: parent.top
                anchors.topMargin: 5
               clip: true
				Text {
					anchors.left: parent.left
					anchors.leftMargin: 10
					anchors.verticalCenter : parent.verticalCenter
                    font.family: "Helvetica"
                    font.pixelSize: menuFontSize + 1
                    font.bold: true
					text: "Wi-Fi Camera Controls"
                    color: "#ffffff"
                }
				Rectangle {
					id: wifiCloseImgBg
					width: expandedStateIconW + 5
					height: expandedStateIconH + 5
					color: mouseArea.containsMouse ? "#c90808" : "transparent"
					anchors.right: wifiLabel.right
					anchors.rightMargin: 4
					visible: true
					anchors.verticalCenter : parent.verticalCenter

					Image {
						id: x_wifi
						source: "qrc:View/icons/closeSmall.svg"
						anchors.fill: parent
						fillMode: Image.PreserveAspectFit
					}

					MouseArea {
						id: mouseArea
						objectName: "wifiCloseMouseArea"
						anchors.fill: parent
						hoverEnabled: true
						onClicked: {
							logController.displayMessage(verboseLogPriority, "UI: Closed Wifi cam Controls Container\n");	
							  handleCheckChangedUpRight(!closeRightUp)
							  closeRightUp = !closeRightUp
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
						text: "Close Wi-Fi Camera Controls"
					}
			  }
		 }
				
	 }
				
			Rectangle {
				id: wifiInnerRectangle
				width: parent.width 
				height: parent.height 
				anchors.top: wifiLabel.bottom
				anchors.bottom: parent.bottom
				anchors.horizontalCenter: parent.horizontalCenter
				color: "#0d1926"

				Flickable {
					id: wifiFlickable
					anchors.fill: parent
					property int horizontalScrollBottomMargin: ( modifiedScreenWidth > 0 ) ? 15 : 0
					property int horizontalScrollPadding: wifiCustomHScrollBar.visible ? wifiCustomHScrollBar.height + horizontalScrollBottomMargin : 0
					contentWidth:  ( modifiedScreenWidth > 0 ) ? (MonitorHandler) ? 0.2 * MonitorHandler.screenResolution.width : 0 : 0
					contentHeight: Math.max(height, wifiSettingsComponent.implicitHeight + 20 + horizontalScrollPadding)
					clip: true
					interactive: contentHeight > height || contentWidth > width

				    boundsBehavior: Flickable.StopAtBounds  //Prevents overscroll

					WifiSettings {
						id: wifiSettingsComponent
						objectName: "wifiSettings"
					}

					// Custom vertical scrollbar
					ScrollBar.vertical: ScrollBar {
						id: wifiCustomVScrollBar
						objectName: "wifiCustomVScrollBar"
						width: 12
						active: false
						visible : wifiFlickable.contentHeight > wifiFlickable.height

						contentItem: Rectangle {
							implicitWidth: 8
							implicitHeight: 15
							radius: 4
							color: (wifiCustomVScrollBar.active || wifiCustomVScrollBar.hovered) ? "#2087cc" : "#45a7ff"
						}

						background: Rectangle {
							color: "#07111d"
							border.color: "#263949"
							border.width: 1
							radius: 4
							width: 12
						}
					}

					//  Custom horizontal scrollbar
					ScrollBar.horizontal: ScrollBar {
						id: wifiCustomHScrollBar
						objectName: "wifiCustomHScrollBar"
						height: 12
						active: false
						visible : wifiFlickable.contentWidth > wifiFlickable.width

						contentItem: Rectangle {
							implicitWidth: parent.width
							implicitHeight: 8
							radius: 4
							color: (wifiCustomHScrollBar.active || wifiCustomHScrollBar.hovered) ? "#2087cc" : "#45a7ff"
						}

						background: Rectangle {
							color: "#07111d"
							border.color: "#263949"
							border.width: 1
							height: 12
							radius: 4
						}
					}
				}
			}
}
