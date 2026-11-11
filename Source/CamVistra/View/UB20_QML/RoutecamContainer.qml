import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: routecamRect
    height: right_con_up.height
    color: "#0d1926"
	border.color: "#263949"
	border.width: 1

    property int expandedIndex: -1         // Track which device tab is expanded
	property int selectedIndex: -1
	property bool controlsLoading: false
	property int loadingCompleted: 0
	property int loadingTotal: 0

	Connections {
		target: routecamOnvifController
		onRoutecamLoadingChanged: {
			controlsLoading = loading;
			if (loading) {
				loadingCompleted = 0;
				loadingTotal = 0;
			}
		}
		onRoutecamLoadingProgress: {
			loadingCompleted = completed;
			loadingTotal = total;
		}
	}

	Connections{
		target : prevController
		onCameraClosed: {
			if(!isControlUpdated){
				expandedIndex = -1
				selectedIndex = -1
				routecamFlickable.contentWidth = 0
			}
		}

		onCameraOpened: {
			selectedDevices = selectedDevices
		}

	}
    // --- Header (Routecam Controls) ---
    Rectangle {
        id: routecamLabel
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
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Helvetica"
            font.pixelSize: menuFontSize + 1
            font.bold: true
			text: "RouteCam Controls"
            color: "#ffffff"
        }

        // --- Close Button ---
        Rectangle {
            id: routecamCloseImgBg
            width: expandedStateIconW + 5
            height: expandedStateIconH + 5
            color: mouseArea.containsMouse ? "#c90808" : "transparent"
            anchors.right: routecamLabel.right
			anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            visible: true

            Image {
                id: x_routecam
                source: "qrc:View/icons/closeSmall.svg"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                id: mouseArea
                objectName: "routecamCloseMouseArea"
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
					logController.displayMessage(verboseLogPriority, "UI: Closed Routecam Controls Container\n");	
                    handleCheckChangedUpRight(!closeRightUp)
                    closeRightUp = !closeRightUp
                }
            }

            ToolTip {
                visible: mouseArea.containsMouse
				background: Rectangle {
					color: window.titleBarColor
					border.color: window.titleBarColor
					border.width: 1
					radius: 4
				}
                contentItem: Text {
                    color: "white"
                    font.pixelSize: baseFontSize + 1
					text: "Close RouteCam Controls"
                }
            }
        }
    }

    // --- Vertical Tabs + Expandable RoutecamSettings ---

    Flickable {
        id: routecamFlickable
        anchors.top: routecamLabel.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        property int horizontalScrollPadding: routecamCustomHScrollBar.visible ? routecamCustomHScrollBar.height : 0
        contentHeight: Math.max(height, contentColumn.implicitHeight + horizontalScrollPadding)
        contentWidth: contentColumn.width
        clip: true

		 boundsBehavior: Flickable.StopAtBounds  //Prevents overscroll

        Column {
            id: contentColumn
            width: routecamFlickable.width - (routecamCustomVScrollBar.visible ? routecamCustomVScrollBar.width : 0)
            spacing: 0
            anchors.left: parent.left
            anchors.leftMargin: 5
            anchors.rightMargin: 5

            Repeater {
                model: selectedDeviceCount

                Column {
                    width: parent.width
                    spacing: 10

                    // --- Device Tab Button ---
                    Rectangle {
                        id: tabButton
                        objectName: "tabButton"
                        width:  visible ? Math.max(routecamSettingsComponent.implicitWidth ,  routecamFlickable.width, routecamFlickable.contentWidth, right_con_up.width ) : 0
                        height: 40
						color: (routecamRect.expandedIndex === index) ? "#0b5fae" : "#111f2d"
						radius: 7
						border.color: (routecamRect.expandedIndex === index) ? "#0b84f3" : "#263949"

                        Text {
                            text: selectedDevices.length > 0 ? selectedDevices[index].deviceIP : ""
							font.pixelSize: baseFontSize
                            color: "white"
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                        }

                        MouseArea {
                            objectName: "tabMouseArea"
                            anchors.fill: parent
							enabled: !routecamRect.controlsLoading
                            onClicked: {
                                // Toggle expansion (only one open at a time)
								if(routecamRect.expandedIndex === index){
                                    
									selectedIndex = index
								} else if (selectedIndex != index){		
                                    
									selectedIndex = index		
									const device = selectedDevices[index]							
									routecamOnvifController.readJsonArrayFile()
									if(device.deviceIP){	
										const baseUrl = "http://" + device.deviceIP + ":8000"
										routecamOnvifController.loadRoutecamControls(baseUrl);
									} else{
										const baseUrl = device.deviceName.split("/onvif")[0];
										routecamOnvifController.loadRoutecamControls(baseUrl);
									}
								}
                                routecamRect.expandedIndex = (routecamRect.expandedIndex === index) ? -1 : index
                            }
                        }
                    }

                    // --- Expandable Settings Panel ---
                    Rectangle {
                        id: settingsPanel
                        width:  visible ? Math.max(routecamSettingsComponent.implicitWidth ,  routecamFlickable.width, routecamFlickable.contentWidth, right_con_up.width ) : 0
						color: "#0d1926"
						radius: 8
						border.color: "#263949"
						border.width: 1
                        visible: routecamRect.expandedIndex === index
                        height: {
                            if (!visible) return 0
                            var h = routecamSettingsComponent.implicitHeight
                            if (h <= 0) h = 400  // fallback minimum height
                            return h + 20  // 20 for margins (10 top + 10 bottom)
                        }
                        clip: true

                        // Replace with your real component
                        RoutecamSettings {
                            objectName: "routecamSettingsComponent"
                            id: routecamSettingsComponent
                            width: parent.width - 20  // Account for margins
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 10
                        }
                    }
                }
            }
        }

        // Custom vertical scrollbar
        ScrollBar.vertical: ScrollBar {
            id: routecamCustomVScrollBar
            objectName: "routecamCustomVScrollBar"
            width: 12
            active: false
            visible: routecamFlickable.contentHeight > routecamFlickable.height && routecamRect.expandedIndex === selectedIndex
            contentItem: Rectangle {
                implicitWidth: 8
                implicitHeight: 15
                radius: 4
                color: (routecamCustomVScrollBar.active || routecamCustomVScrollBar.hovered) ? "#2087cc" : "#45a7ff"
            }
            background: Rectangle {
                color: "#07111d"
                border.color: "#263949"
                border.width: 1
                radius: 4
                width: 12
            }
        }

        // Custom horizontal scrollbar
        ScrollBar.horizontal: ScrollBar {
            id: routecamCustomHScrollBar
            objectName: "routecamCustomHScrollBar"
            height: 12
            active: false
            visible: routecamFlickable.contentWidth > routecamFlickable.width && routecamRect.expandedIndex === selectedIndex
            contentItem: Rectangle {
                implicitWidth: parent.width
                implicitHeight: 8
                radius: 4
                color: (routecamCustomHScrollBar.active || routecamCustomHScrollBar.hovered) ? "#2087cc" : "#45a7ff"
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

	Rectangle {
		anchors.fill: routecamFlickable
		z: 100
		visible: routecamRect.controlsLoading
		color: "#99000000"

		MouseArea {
			anchors.fill: parent
		}

		Column {
			anchors.centerIn: parent
			spacing: 12

			BusyIndicator {
				anchors.horizontalCenter: parent.horizontalCenter
				running: routecamRect.controlsLoading
			}

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				color: "white"
				font.pixelSize: menuFontSize
				text: loadingTotal > 0
					? "Loading camera controls "
						+ Math.round((loadingCompleted * 100) / loadingTotal) + "%"
					: "Loading camera controls 0%"
			}
		}
	}
}

