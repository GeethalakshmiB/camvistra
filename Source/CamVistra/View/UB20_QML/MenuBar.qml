import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Dialogs 1.3
	
// Custom Menu Bar
    Rectangle {
        id:menuBar
        anchors.fill: parent
        color: "#08131f"
		border.color: "#1f3040"
		border.width: 1
        readonly property int dropdownIconSize: Math.max(20, Math.min(28, Math.round(menuItemHeight * 0.7)))
		readonly property int topIconSize: Math.max(18, Math.min(26, Math.round(menuBarHeight * 0.58)))
        // Effective render scale used for rasterizing SVGs. Use a single
        // computed value to avoid double-counting DPI/scaling factors.
        readonly property real renderScale: Math.max(1, Math.round(Screen.devicePixelRatio * window.scaleFactor))

        Row {
            spacing: 20
			x: 10
           height: menuBarHeight

            Column {
                spacing: 0
				anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: file
                    text: "File"
					leftPadding: menuBar.topIconSize + 8
                    color: "white"
                    width: implicitWidth + 10
                    height: implicitHeight + 8
                    font.pixelSize : menuFontSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
					Image {
						source: "qrc:View/icons/menu/ExitMenu.svg"
						width: menuBar.topIconSize
						height: width
                        // Oversample top-row icons to improve raster clarity
                        sourceSize: Qt.size(Math.ceil(width * menuBar.renderScale * 2), Math.ceil(height * menuBar.renderScale * 2))
                        smooth: true
						anchors.left: parent.left
						anchors.leftMargin: 3
						anchors.verticalCenter: parent.verticalCenter
						fillMode: Image.PreserveAspectFit
					}
                    Rectangle {
                        anchors.fill: parent
						color: fileMouseArea.containsMouse ? "#12365a" : "transparent"
                        radius: 4
                        z: -1
                    }
                    MouseArea {
                        id: fileMouseArea
                        objectName: "fileMouseArea"
                        anchors.fill: parent
                        hoverEnabled : true
                        onClicked: {			
							logController.displayMessage(verboseLogPriority, "UI: Opened file menu to exit the application\n");
							fileMenu.y = file.mapToItem(menuBar, 0, file.height).y
                            fileMenu.open()
                        }
                    }
                }
                Menu {
					id: fileMenu
					y: file.mapToItem(menuBar, 0, file.height).y
					width: menuItemWidth
					height: menuItemHeight
					font.pixelSize : menuFontSize
					focus: true

					MenuItem {
						id: exitItem
						objectName: "exitItem"
						height: menuItemHeight

						contentItem: Row {
							spacing: 10
							anchors.centerIn: parent

							Image {
								source: "qrc:View/icons/menu/ExitMenu.svg"
								width: menuBar.dropdownIconSize
								height: menuBar.dropdownIconSize
								sourceSize: Qt.size(Math.ceil(width * menuBar.renderScale), Math.ceil(height * menuBar.renderScale))
								fillMode: Image.PreserveAspectFit
								anchors.verticalCenter: parent.verticalCenter
							}

							Text {
								text: "Exit"
								font.pixelSize: menuFontSize
								color: "white"
								anchors.verticalCenter: parent.verticalCenter
							}
						}

						background: Rectangle {
							color: exitItem.hovered ? "#0b5fae" : "#0e1b28"
							anchors.fill: parent
						}

						onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Exit action clicked.\n");
							Qt.exit(0);
						}
					}
				}
            }

            Column {
                spacing: 0
				anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: view
                    text: "View"
					leftPadding: menuBar.topIconSize + 8
                    color: "white"
                    width: implicitWidth + 10
                    height: implicitHeight + 8
                   font.pixelSize : menuFontSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
					Image {
						source: "qrc:View/icons/menu/ViewEyeMenu.svg"
						width: menuBar.topIconSize; height: width
                        // Oversample top-row icons to improve raster clarity
                        sourceSize: Qt.size(Math.ceil(width * menuBar.renderScale * 2), Math.ceil(height * menuBar.renderScale * 2))
                        smooth: true
						anchors.left: parent.left; anchors.leftMargin: 3
						anchors.verticalCenter: parent.verticalCenter
						fillMode: Image.PreserveAspectFit
					}

                    Rectangle {
                        anchors.fill: parent
						color: viewMouseArea.containsMouse ? "#12365a" : "transparent"
                        radius: 4
                        z: -1
                    }

                    MouseArea {
                        id: viewMouseArea
                        objectName: "viewMouseArea"
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            // Open intermediate menu
							logController.displayMessage(verboseLogPriority, "UI: Opened windows menu with menu items based on the chosen camera\n");
                            windowsMenu.y = view.mapToItem(menuBar, 0, view.height).y
                            windowsMenu.open()
                        }
                    }
                }

                // Intermediate "Windows" Menu
                Menu {
                    id: windowsMenu
                    y: view.mapToItem(menuBar, 0, view.height).y
                    width: menuItemWidth
                    height: menuItemHeight
                    title: "Windows"
                   font.pixelSize : menuFontSize
                    focus: false

                    MenuItem {
                        id: windowsItem
                        text: "Windows"
						enabled: !window.hideWindows
                        height: menuItemHeight
                        font.pixelSize: menuFontSize + 1

                        background: Rectangle {
							color: windowsItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                            /*border {
                                color :  "#161414"  
                                width: 2 
                            }*/
                        }

                        //indicator: Item {}  // Disable default indicator

                        contentItem: Row {
                            spacing: 10
                            anchors.fill: parent
                            anchors.leftMargin: 10

                            Text {
                                text: "Windows"
								color: windowsItem.enabled? "white" : "#66665f"
                                font.pixelSize: menuFontSize + 1
                                verticalAlignment: Text.AlignVCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }

                             // Optional arrow indicator aligned to the right
                            Item {
                                width: parent.width - 89 // Flexible spacer
                                height: 1
                            }

                            Text {
                                text: "▶"
								color: windowsItem.enabled? "white" : "#66665f"
								font.pixelSize : menuFontSize
                                verticalAlignment: Text.AlignVCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                // Open the actual viewMenu on hover
                                viewMenu.x = windowsMenu.x + windowsMenu.width - 1
                                viewMenu.y = view.mapToItem(menuBar, 0, view.height).y
                                viewMenu.open()
                            }

                            onClicked: {
                                // Also open viewMenu on click
								logController.displayMessage(verboseLogPriority, "UI: Opened View options submenu.\n");
                                viewMenu.x = windowsMenu.x + windowsMenu.width - 1
                                viewMenu.y = view.mapToItem(menuBar, 0, view.height).y
                                viewMenu.open()
                            }
                        }
                    }
                }

                // Actual View Submenu
                Menu {
                    id: viewMenu		
                    y: view.mapToItem(menuBar, 0, view.height).y
                    width: deviceType < 0 ? menuItemWidth + 20 : menuItemWidth*1.8
                    height: deviceType < 0 ? menuItemHeight * 2  : menuItemHeight* 3
                    title: "View Options"
                   font.pixelSize : menuFontSize
                    focus: false

                    MenuItem {
                        id: deviceItem
                        objectName: "deviceItem"
                        height: menuItemHeight
                        text: "Devices"
						enabled: !window.hideWindows
                        font.pixelSize: menuFontSize + 1
                        checkable: true
                        checked: !closeLeftUp

                        background: Rectangle {
							color: deviceItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }

                        indicator: Item {}

						contentItem: Row {
							spacing: 10
							anchors.fill: parent
							anchors.leftMargin: 10

							Rectangle {
								width: menuItemHeight - 7
								height: menuItemHeight - 7
								radius: 3
								border.width: 1.4
								border.color: "white"
								color: "transparent"
								anchors.verticalCenter: parent.verticalCenter

								Text {
									text: deviceItem.checked ? "\u2713" : ""
									font.pixelSize: 14
									color: deviceItem.enabled? "white" : "#66665f"
									anchors.centerIn: parent
								}
							}

							Text {
								text: deviceItem.text
								color: deviceItem.enabled? "white" : "#66665f"
								font.pixelSize: menuFontSize + 1
								anchors.verticalCenter: parent.verticalCenter
							}
						}


                        onTriggered: {
							logController.displayMessage(verboseLogPriority,
								closeLeftUp ? "UI: Devices window shown.\n" : "UI: Devices window hidden.\n");
                            windowsMenu.close()
                            handleCheckedChanged(closeLeftUp)
                            closeLeftUp = !closeLeftUp
                        }
                    }

                    MenuItem {
                        id: logItem
                        objectName: "logItem"
                        text: "Log"
						enabled: !window.hideWindows
                        height: menuItemHeight
                        font.pixelSize: menuFontSize + 1
                        checkable: true
                        checked: !closeMiddleDown

                        background: Rectangle {
							color: logItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }

                        indicator: Item {}

                        contentItem: Row {
                            spacing: 10
                            anchors.fill: parent
                            anchors.leftMargin: 10

							Rectangle {
								width: menuItemHeight - 7
								height: menuItemHeight - 7
								radius: 3
								border.width: 1.4
								border.color: "white"
								color: "transparent"
								anchors.verticalCenter: parent.verticalCenter

								Text {
									text: logItem.checked ? "\u2713" : "    "
									font.pixelSize: 14
									color: logItem.enabled? "white" : "#66665f"
									anchors.centerIn: parent
								}
							}
							
                            Text {
                                text: logItem.text
								color: logItem.enabled? "white" : "#66665f"
                                font.pixelSize: menuFontSize + 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        onTriggered: {
							logController.displayMessage(verboseLogPriority,
								closeMiddleDown ? "UI: Log window shown.\n" : "UI: Log window hidden.\n");
                            windowsMenu.close()
                            handleLogCheckedChanged(closeMiddleDown)
                            closeMiddleDown = !closeMiddleDown
                        }
                    }

                    MenuItem {
                        id: wifiCntlItem
                        objectName: "wifiCntlItem"
                        enabled : !videoRecord &&  !window.hideWindows
                        height: menuItemHeight
                        visible: deviceType === wifiDev || deviceType === ethernetDev || deviceType === usbDev
                        text: deviceType === wifiDev ? "Wifi Controls" :   (deviceType === ethernetDev) ? "Routecam Controls" : "USB Controls"
                        checkable: true
                        checked: !closeRightUp

                        background: Rectangle {
							color: wifiCntlItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }

                        indicator: Item {}

                        contentItem: Row {
                            spacing: 10
                            anchors.fill: parent
                            anchors.leftMargin: 10

							Rectangle {
								width: menuItemHeight - 7
								height: menuItemHeight - 7
								radius: 3
								border.width: 1.4
								border.color: "white"
								color: "transparent"
								anchors.verticalCenter: parent.verticalCenter

								Text {
									text: wifiCntlItem.checked ? "\u2713" : "    "
									font.pixelSize: 14
									color: wifiCntlItem.enabled? "white" : "#66665f"
									anchors.centerIn: parent
								}
							}
							
                            Text {
                                text: wifiCntlItem.text
                                color: !videoRecord && wifiCntlItem.enabled ? "white" : "#66665f"
                                font.pixelSize: menuFontSize + 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        onTriggered: {
							logController.displayMessage(verboseLogPriority,
								"UI: " + wifiCntlItem.text + (closeRightUp ? " shown.\n" : " hidden.\n"));
                            windowsMenu.close()
							handleCheckChangedUpRight(!closeRightUp)
							closeRightUp = !closeRightUp
                        }
                    }
                }
            }

            Column
            {
                spacing: 0
				anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: capture
                    text: "Capture"
					leftPadding: menuBar.topIconSize + 8
                    color: "white"
                    width: implicitWidth + 10
                    height: implicitHeight + 8
                    font.pixelSize : menuFontSize
                    //font.bold: captureMouseArea.containsMouse ? true : false
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
					Image {
						source: "qrc:View/icons/menu/CaptureMenu.svg"
						width: menuBar.topIconSize; height: width
                        // Capture top-row icon: oversample 3x for improved clarity
                        sourceSize: Qt.size(Math.ceil(width * menuBar.renderScale * 3), Math.ceil(height * menuBar.renderScale * 3))
                        smooth: true
						anchors.left: parent.left; anchors.leftMargin: 3
						anchors.verticalCenter: parent.verticalCenter
						fillMode: Image.PreserveAspectFit
					}
                    Rectangle {
                        anchors.fill: parent
						color: captureMouseArea.containsMouse ? "#12365a" : "transparent"
                        radius: 4
                        z: -1
                    }
                    MouseArea {
                        id: captureMouseArea
                        objectName: "captureMouseArea"
                        anchors.fill: parent
                        hoverEnabled : true
                        onClicked: {
							logController.displayMessage(verboseLogPriority, "UI: Opened Capture menu with options to set still capture path or capture a still image\n");
							captureMenu.y = capture.mapToItem(menuBar, 0, capture.height).y
                            captureMenu.open()
                        }
                    }
                }
 
                Menu {
                    id: captureMenu
                    y: capture.mapToItem(menuBar, 0, capture.height).y
                    // Increased height to account for the added header MenuItem
                    height: menuItemHeight * 2 
                    width: menuItemWidth + 40
                    title: "Capture"
                    font.pixelSize : menuFontSize
                    focus: true
 
                    MenuItem {
						id: stillPathItem
						objectName: "stillPathItem"
						height: menuItemHeight
                    
                        // Setting the text with white color
                        contentItem: Row {
                            spacing: 10
                            anchors.centerIn: parent
 
                            Image {
                                source: "qrc:View/icons/menu/FolderMenu.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.renderScale), Math.ceil(height * menuBar.renderScale))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter  // Vertically center in the row
                            }
 
                            Text {
                                text: "Still Capture Path"
                                font.pixelSize: menuFontSize 
                                color: "white"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
                         background: Rectangle {
							color: stillPathItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
                        onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Opened Still Capture dialog to set the save file path\n");
                            stillCaptureWindow.show()
							stillCaptureWindow.raise()
							//stillCaptureWindow.requestActivate()
                        }
                    }
					MenuItem
					{
						id: stillItem
						objectName: "stillItem"
						enabled : window.captureEnabled
						height: menuItemHeight
                    
                        // Setting the text with white color
                        contentItem: Row {
                            spacing: 10
                            anchors.centerIn: parent
 
                            Image {
                                source: stillItem.enabled ? "qrc:View/icons/menu/CaptureMenu.svg" : "qrc:View/icons/menu/CaptureMenuDisabled.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.renderScale), Math.ceil(height * menuBar.renderScale))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter  // Vertically center in the row
                            }
 
                            Text {
                                text: "Capture Image"
                                font.pixelSize: menuFontSize 
                                color: stillItem.enabled? "white" : "#66665f"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
                         background: Rectangle {
							color: stillItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
                        onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Still capture clicked.\n");
							window.captureStillImage()
                        }
                    }	  
                }
            }
            
            Column
            {
                spacing: 0
				anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: record
                    text: "Record"
					leftPadding: menuBar.topIconSize + 8
                    color: "white"
                    width: implicitWidth + 10
                    height: implicitHeight + 8
                   font.pixelSize : menuFontSize
                    //font.bold: recordMouseArea.containsMouse ? true : false
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
					Image {
						source: "qrc:View/icons/menu/RecordStartMenu.svg"
						width: menuBar.topIconSize; height: width
                        sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                        smooth: true
						anchors.left: parent.left; anchors.leftMargin: 3
						anchors.verticalCenter: parent.verticalCenter
						fillMode: Image.PreserveAspectFit
					}
                    Rectangle {
                        anchors.fill: parent
						color: recordMouseArea.containsMouse ? "#12365a" : "transparent"
                        radius: 4
                        z: -1
                    }
                    MouseArea {
                        id: recordMouseArea
                        objectName: "recordMouseArea"
                        anchors.fill: parent
                        hoverEnabled : true
                        onClicked: {
							logController.displayMessage(verboseLogPriority, "UI: Opened Record menu with options to set video record path or record a video\n");
							recordMenu.y = record.mapToItem(menuBar, 0, record.height).y
                            recordMenu.open()
                        }
                    }
                }
 
                Menu {
                    id: recordMenu
                    y: record.mapToItem(menuBar, 0, record.height).y
                    height: menuItemHeight*3
                    width: menuItemWidth + 43
                    title: "Record"
                   font.pixelSize : menuFontSize
                    focus: true
 
                    MenuItem {
                        id: vidRecPathItem
                        objectName: "vidRecPathItem"
						enabled : !videoRecord 
						height: menuItemHeight
                    
                        // Setting the text with white color
                        contentItem: Row {
                            spacing: 10
                            anchors.centerIn: parent
 
                            Image {
                                source: !videoRecord ? "qrc:View/icons/menu/FolderMenu.svg" : "qrc:View/icons/menu/FolderMenuDisabled.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter  // Vertically center in the row
                            }
 
                            Text {
                                text: "Video Record Path"
                                font.pixelSize: menuFontSize
                                color: !videoRecord ? "white" : "#66665f"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
                         background: Rectangle {
							color: vidRecPathItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
                        onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Opened Video Record dialog to set the save recorded file path\n");
                            vidRecWindow.show()
							vidRecWindow.raise()
                        }
                    }

					MenuItem {
                        id: audioSettings
                        objectName: "audioSettings"
						enabled: !videoRecord && window.audioDeviceAvailable && window.audioDeviceSelected
						height: menuItemHeight
                    
                        // Setting the text with white color
                        contentItem: Row {
                            spacing: 10
                            anchors.centerIn: parent
 
                           Image {
                                source: audioSettings.enabled ? "qrc:View/icons/menu/AudioMenu.svg" : "qrc:View/icons/menu/AudioMenuDisabled.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter  // Vertically center in the row
                            }
 
                            Text {
                                text: "Audio Settings"
                                font.pixelSize: menuFontSize
                                color: audioSettings.enabled ? "white" : "#66665f"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
                         background: Rectangle {
							color: audioSettings.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
                        onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Opened Audio Settings dialog to set audio properties\n");
                            audioRecWindow.show()
							audioRecWindow.raise()
                        }
                    }

					MenuItem
					{
						id: vidRecItem
						objectName: "vidRecItem"
						enabled : window.captureEnabled && !window.isOnvifRecording
						height: menuItemHeight
                    
                        // Setting the text with white color
                        contentItem: Row {
                            spacing: 10
                            anchors.centerIn: parent
 
                            Image {
                                source: (selectedDevCnt == 1 && !window.isOnvifRecording && !window.videoRecord) ? "qrc:View/icons/menu/RecordStartMenu.svg" : window.videoRecord ? "qrc:View/icons/menu/RecordStopMenu.svg" : "qrc:View/icons/menu/RecordStartMenuDisabled.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter  // Vertically center in the row
                            }
 
                            Text {
                                text: videoRecord ? "Stop Recording" : "Start Recording"
                                font.pixelSize: menuFontSize
                                color: vidRecItem.enabled ? "white" : "#66665f"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
                         background: Rectangle {
							color: vidRecItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
                        onTriggered: {
                            if(window.videoRecord){
								window.videoRecord = false	
								logController.displayMessage(verboseLogPriority, "UI: Stop Recording.\n");
								if(prevController.stopRecording() == 1){
								logController.displayMessage(verboseLogPriority, "UI: Stop Recording successful.\n");
									window.stopVideoRecording()
									restoreRightContainerAfterRecording()
								} else{
									logController.displayMessage(verboseLogPriority, "UI: Stop Recording failed.\n");
									window.videoRecord = true
								}
							}else{
								durationTimer.stop()
								window.videoRecord = true
								logController.displayMessage(verboseLogPriority, "UI: Start Recording.\n");
								if(prevController.startVideoRecording() == 1){	
									logController.displayMessage(verboseLogPriority, "UI: Start Recording successful.\n");
									window.startVideoRecording(true)
									hideRightContainerForRecording()
								} else{
									logController.displayMessage(verboseLogPriority, "UI: Start Recording failed.\n");
									window.startVideoRecording(false)
									window.videoRecord = false
								}
							}
                        }
                    }
                }
            }

           Column {
                spacing: 0
				anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: grid
                    text: "Grid"
					leftPadding: menuBar.topIconSize + 8
                    color: "white"
                    width: implicitWidth + 10
                    height: implicitHeight + 8
                    font.pixelSize : menuFontSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
					Image {
						source: "qrc:View/icons/menu/GridMenu.svg"
						width: menuBar.topIconSize; height: width
                        sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                        smooth: true
						anchors.left: parent.left; anchors.leftMargin: 3
						anchors.verticalCenter: parent.verticalCenter
						fillMode: Image.PreserveAspectFit
					}
                    Rectangle {
                        anchors.fill: parent
						color: gridMouseArea.containsMouse ? "#12365a" : "transparent"
                        radius: 4
                        z: -1
                    }
                    MouseArea {
                        id: gridMouseArea
                        objectName: "gridMouseArea"
                        anchors.fill: parent
                        hoverEnabled : true
                        onClicked: {			
							logController.displayMessage(verboseLogPriority, "UI: Opened grid menu to apply grid in the preview\n");
							gridMenu.y = grid.mapToItem(menuBar, 0, grid.height).y
                            gridMenu.open()
                        }
                    }
                }
                Menu {
                    id: gridMenu
					y: grid.mapToItem(menuBar, 0, grid.height).y
                    height: menuItemHeight 
                    width: menuItemWidth + 40
                    title: "Grid"
                    font.pixelSize : menuFontSize
                    focus: true
 
 
                    MenuItem {
						height: menuItemHeight
                        id: gridItem
                        objectName: "gridItem"
 
                        contentItem: Row {
                            spacing: 5
                            anchors.centerIn: parent
                            Image {
                                source: "qrc:View/icons/menu/GridMenu.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Grid Settings"
                                font.pixelSize: menuFontSize + 1
                                color: "white"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
 
                        background: Rectangle {
							color: gridItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
 
                        onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Opened Grid Settings dialog.\n");
							gridSettingsWindow.show()
                        }
                    }
 
                }
            }

            Column {
                spacing: 0
				anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: crossHair
                    text: "Cross Hair"
					leftPadding: menuBar.topIconSize + 8
                    color: "white"
                    width: implicitWidth + 10
                    height: implicitHeight + 8
                    font.pixelSize : menuFontSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
					Image {
						source: "qrc:View/icons/menu/CrossHairMenu.svg"
						width: menuBar.topIconSize; height: width
                        sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                        smooth: true
						anchors.left: parent.left; anchors.leftMargin: 3
						anchors.verticalCenter: parent.verticalCenter
						fillMode: Image.PreserveAspectFit
					}
                    Rectangle {
                        anchors.fill: parent
						color: crossHairMouseArea.containsMouse ? "#12365a" : "transparent"
                        radius: 4
                        z: -1
                    }
                    MouseArea {
                        id: crossHairMouseArea
                        objectName: "crossHairMouseArea"
                        anchors.fill: parent
                        hoverEnabled : true
                        onClicked: {			
							logController.displayMessage(verboseLogPriority, "UI: Opened Cross hair menu to apply cross-hair in the preview\n");
							crossHairMenu.y = crossHair.mapToItem(menuBar, 0, crossHair.height).y
                            crossHairMenu.open()
                        }
                    }
                }
                Menu {
                    id: crossHairMenu
					y: crossHair.mapToItem(menuBar, 0, crossHair.height).y
                    height: menuItemHeight 
					width: Math.max(menuItemWidth + 40,
								crossHairItemText.implicitWidth + menuBar.dropdownIconSize + 45)
                    title: "Cross Hair"
                    font.pixelSize : menuFontSize
                    focus: true
 
 
                    MenuItem {
						height: menuItemHeight
						width: crossHairMenu.width
                        id: crossHairItem
                        objectName: "crossHairItem"
 
                        contentItem: Row {
                            spacing: 5
                            anchors.centerIn: parent
                            Image {
                                source: "qrc:View/icons/menu/CrossHairMenu.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
								id: crossHairItemText
                                text: "Cross Hair Settings"
                                font.pixelSize: menuFontSize + 1
                                color: "white"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
 
                        background: Rectangle {
							color: crossHairItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
 
                        onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Opened Cross Hair Settings dialog.\n");
							crossHairSettingsWindow.show()
                        }
                    }
 
                }
            }

            Column {
                spacing: 0
				anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: zoom
                    text: "Zoom"
					leftPadding: menuBar.topIconSize + 8
                    color: "white"
                    width: implicitWidth + 10
                    height: implicitHeight + 8
                    font.pixelSize : menuFontSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
					Image {
						source: "qrc:View/icons/menu/ZoomMenu.svg"
						width: menuBar.topIconSize; height: width
                        sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                        smooth: true
						anchors.left: parent.left; anchors.leftMargin: 3
						anchors.verticalCenter: parent.verticalCenter
						fillMode: Image.PreserveAspectFit
					}
                    Rectangle {
                        anchors.fill: parent
						color: zoomMouseArea.containsMouse ? "#12365a" : "transparent"
                        radius: 4
                        z: -1
                    }
                    MouseArea {
                        id: zoomMouseArea
                        objectName: "zoomMouseArea"
                        anchors.fill: parent
                        hoverEnabled : true
                        onClicked: {			
							logController.displayMessage(verboseLogPriority, "UI: Opened Zoom menu to configure preview zoom\n");
							zoomMenu.y = zoom.mapToItem(menuBar, 0, zoom.height).y
                            zoomMenu.open()
                        }
                    }
                }
                Menu {
                    id: zoomMenu
					y: zoom.mapToItem(menuBar, 0, zoom.height).y
                    height: menuItemHeight 
                    width: menuItemWidth + 40
                    title: "Zoom"
                    font.pixelSize : menuFontSize
                    focus: true
 
 
                    MenuItem {
						height: menuItemHeight
                        id: zoomItem
                        objectName: "zoomItem"
                        enabled: window.zoomAllowed
 
                        contentItem: Row {
                            spacing: 5
                            anchors.centerIn: parent
                            Image {
                                source: zoomItem.enabled ? "qrc:View/icons/menu/ZoomMenu.svg" : "qrc:View/icons/menu/ZoomMenuDisabled.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Zoom Settings"
                                font.pixelSize: menuFontSize + 1
                                color: zoomItem.enabled ? "white" : "#66665f"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
 
                        background: Rectangle {
							color: zoomItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
 
                        onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Opened Zoom Settings dialog.\n");
							zoomWindow.show()
                        }
                    }
 
                }
            }
 
            Column {
                spacing: 0
				anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: help
                    text: "Help"
					leftPadding: menuBar.topIconSize + 8
                    color: "white"
                    width: implicitWidth + 10
                    height: implicitHeight + 8
                    //font.bold : helpMouseArea.containsMouse? true : false
                   font.pixelSize : menuFontSize
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
					Image {
						source: "qrc:View/icons/menu/aboutIconMenuBar.svg"
						width: menuBar.topIconSize; height: width
                        sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                        smooth: true
						anchors.left: parent.left; anchors.leftMargin: 3
						anchors.verticalCenter: parent.verticalCenter
						fillMode: Image.PreserveAspectFit
					}
                    Rectangle {
                        anchors.fill: parent
						color: helpMouseArea.containsMouse ? "#12365a" : "transparent"
                        radius: 4
                        z: -1
                    }
                    MouseArea {
                        id: helpMouseArea
                        objectName: "helpMouseArea"
                        anchors.fill: parent
                        hoverEnabled : true
                        onClicked: {
							logController.displayMessage(verboseLogPriority, "UI: Opened help menu with about dialog option\n");
							helpMenu.y = help.mapToItem(menuBar, 0, help.height).y
                            helpMenu.open()
                        }
                    }
                }
                Menu {
                    id: helpMenu
                    y: help.mapToItem(menuBar, 0, help.height).y
                    height: menuItemHeight
                    width: menuItemWidth
                    title: "Help"
                   font.pixelSize : menuFontSize
                    focus: true
 
 
                    MenuItem {
                        id: aboutItem
                        objectName: "aboutItem"
						height: menuItemHeight
 
                        contentItem: Row {
                            spacing: 10
                            anchors.centerIn: parent
 
                            Image {
                                source: "qrc:View/icons/menu/AboutMenu.svg"
                                width: menuBar.dropdownIconSize
                                height: menuBar.dropdownIconSize
                                sourceSize: Qt.size(Math.ceil(width * menuBar.dropdownIconRenderScale * window.scaleFactor), Math.ceil(height * menuBar.dropdownIconRenderScale * window.scaleFactor))
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter  // Vertically center in the row
                            }
 
                            Text {
                                text: "About"
                                font.pixelSize: menuFontSize + 1
                                color: "white"
								anchors.verticalCenter: parent.verticalCenter 
                            }
                        }
 
                        background: Rectangle {
							color: aboutItem.hovered ? "#0b5fae" : "#0e1b28"
                            anchors.fill: parent
                        }
 
                        onTriggered: {
							logController.displayMessage(verboseLogPriority, "UI: Opened about dialog\n");
                            aboutDialog.show()
                        }
                    }
 
                }
            }
        }
    }
