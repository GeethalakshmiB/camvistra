import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

Rectangle{
		id:sideMenuBar
		width: window.navigationRailWidth
		height: Math.max(0, window.height - window.topChromeHeight - statusBarHeight)
		y: window.topChromeHeight
		anchors.left: parent.left
		clip: true
		color: "#091522"
		border.color: "#1e3041"
		border.width: 1
		// SVGs are otherwise rasterized at their 35 px intrinsic size and then
		// enlarged, which looks soft/pixelated on high-DPI and wide displays.
		readonly property real iconRenderScale: Math.max(1, Screen.devicePixelRatio)
		readonly property real iconVisualScale: 0.48

		Column{
			y: 4
			spacing : 4
			transformOrigin: Item.Top
			scale: Math.min(1, (sideMenuBar.height - y - 8) / Math.max(1, implicitHeight))

			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				color: mouseArea.containsMouse ? "#12365a" : "transparent"

				// Left hover bar
				Rectangle {
					width: 3
					height: parent.height
					color: mouseArea.containsMouse ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: cameraIcon
					scale: sideMenuBar.iconVisualScale
					enabled : window.captureEnabled
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
					source: cameraIcon.enabled ? "qrc:View/icons/stillCaptureOnHover.svg" : "qrc:View/icons/StillCapture.svg"
				}

				MouseArea {
					id: mouseArea
					objectName: "stillCaptureMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: cameraIcon.enabled  // Disable interaction if image is disabled
					onClicked: {
						window.captureStillImage()
						logController.displayMessage(verboseLogPriority, "UI: Still capture button clicked.\n");
					}
				}

				ToolTip {
					 visible : mouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Capture Image"
					}
				}
			}

			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				enabled : window.captureEnabled
				color: vidRecMouseArea.containsMouse ? "#12365a" : "transparent"

				Rectangle {
					 width: 3
					height: parent.height
					color: window.videoRecord || vidRecMouseArea.containsMouse ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: videoRecIcon
					scale: sideMenuBar.iconVisualScale
					enabled : window.captureEnabled && !window.isOnvifRecording
					source: (videoRecIcon.enabled && !window.videoRecord)?  "qrc:View/icons/recordStartRed.svg" : window.videoRecord ? "qrc:View/icons/recordStopRed1.svg" : "qrc:View/icons/recordStart.svg"
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
				}

				MouseArea {
					id: vidRecMouseArea
					objectName: "videoRecMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: videoRecIcon.enabled
					onClicked: {
						if(window.videoRecord){
							window.videoRecord = false	
							logController.displayMessage(verboseLogPriority, "UI: Stop Recording button clicked. \n");
							if(prevController.stopRecording() == 1){		
								window.stopVideoRecording()
								restoreRightContainerAfterRecording()
							} else{
								logController.displayMessage(verboseLogPriority, "UI: Stop Recording action failed. \n");
								window.videoRecord = true
							}
						}else{
							durationTimer.stop()
							window.videoRecord = true
							logController.displayMessage(verboseLogPriority, "UI: Start Recording button clicked. \n");
							if(prevController.startVideoRecording() == 1){			
								//window.startVideoRecording(true)
								hideRightContainerForRecording()
							} else{
								logController.displayMessage(verboseLogPriority, "UI: Start Recording action failed. \n");
								window.startVideoRecording(false)
								window.videoRecord = false
							}
						}
					}
				}

				ToolTip {
					 visible : vidRecMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: window.videoRecord ? "Stop Recording" : "Start recording"
					}
				}
			}

			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				enabled : selectedDevCnt == 1 ? true : false
				color: audSetMouseArea.containsMouse ? "#12365a" : "transparent"

				Rectangle {
					 width: 3
					height: parent.height
					color: audSetIcon.enabled && audSetMouseArea.containsMouse ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: audSetIcon
					scale: sideMenuBar.iconVisualScale
					enabled: selectedDevCnt == 1 && selectedDevType == "Usb" && window.audioDeviceAvailable && window.audioDeviceSelected && !window.videoRecord
					source: audSetIcon.enabled ? "qrc:View/icons/AudioOnHover.svg" : "qrc:View/icons/Audio.svg"
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
				}

				MouseArea {
					id: audSetMouseArea
					objectName: "audSetMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: audSetIcon.enabled
					onClicked: {
						logController.displayMessage(verboseLogPriority, "UI: Opened Audio Settings dialog to set audio properties\n");
                            audioRecWindow.show()
						audioRecWindow.raise()
					}
				}

				ToolTip {
					 visible : audSetMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Audio Settings"
					}
				}
			}

			Rectangle {
				width: sideMenuBar.width
				height: sideMenuBar.width - 5
				x: 0
				color: imgLocMouseArea.containsMouse ? "#12365a" : "transparent"

				// Left hover bar
				Rectangle {
					 width: 3
					height: parent.height
					color: imgLocMouseArea.containsMouse ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: folderPathIcon
					scale: sideMenuBar.iconVisualScale
					source: "qrc:View/icons/FolderOnHover.svg" //: "qrc:View/icons/Folder.svg"
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
				}

				MouseArea {
					id: imgLocMouseArea
					objectName: "folderPathMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					onClicked: {
						logController.displayMessage(verboseLogPriority, "UI: Dialog opened for configuring still capture and video recording output paths\n");
						filePathWindow.show()
					}
				}

				ToolTip {
					visible: imgLocMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor  // Background color for tooltip
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Storage location for images"
					}
				}
			}
			
			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				color: toggleMouseArea.containsMouse ? "#12365a" : "transparent"

				Rectangle {
					 width: 3
					height: parent.height
					color: selectedDevCnt == 1 ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: fitToWindowIcon
					scale: sideMenuBar.iconVisualScale
					enabled : selectedDevCnt == 1 ? true : false
					source: (window.fitToWindow && enabled) ? "qrc:View/icons/unfitToWindowOnHover.svg" : enabled ? "qrc:View/icons/fitToWindowIconOnHover.svg" : "qrc:View/icons/fitToWindow.svg"
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
				}

				MouseArea {
					id: toggleMouseArea
					objectName: "fitToWindowMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: fitToWindowIcon.enabled
					onClicked: {
						if(zoom != 100){
							zoom = 100
						}
						if(window.fitToWindow){
						logController.displayMessage(verboseLogPriority, "UI: Fit-to-window OFF\n");
							window.fitToWindow = false
						}else{
							logController.displayMessage(verboseLogPriority, "UI: Fit-to-window ON\n");
							window.fitToWindow = true
						}
						window.fitToWinStatusChanged(window.fitToWindow)
						
					}
				}

				ToolTip {
					 visible : toggleMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: window.fitToWindow ? "Disable Fit to window" : "Enable Fit to window"
					}
				}
			}

			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				color: hideWinMouseArea.containsMouse ? "#12365a" : "transparent"

				// Left hover bar
				Rectangle {
					 width: 3
					height: parent.height
					color: hideWinMouseArea.containsMouse ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: hideIcon
					scale: sideMenuBar.iconVisualScale
					enabled : selectedDevCnt > 0 ? true : false
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
					source: (!window.hideWindows && hideIcon.enabled) ? "qrc:View/icons/HideWindowOnHover.svg" : hideIcon.enabled  ?  "qrc:View/icons/UnhideWindowOnHover.svg" : "qrc:View/icons/HideWindows.svg"
				}

				MouseArea {
					id: hideWinMouseArea
					objectName: "hideWindowsMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: hideIcon.enabled  // Disable interaction if image is disabled
					onClicked: {
						if(window.hideWindows){
							logController.displayMessage(verboseLogPriority, "UI: UnHide Window button clicked.\n");
							handleCheckedChanged(closeLeftUp)
							closeLeftUp = !closeLeftUp
							handleCheckChangedUpRight(!closeRightUp)
							closeRightUp = !closeRightUp
							handleLogCheckedChanged(closeMiddleDown)
							closeMiddleDown = !closeMiddleDown
							window.hideWindows = false
						}else{
							logController.displayMessage(verboseLogPriority, "UI: Hide Window button clicked.\n");
							handleCheckedChanged(closeLeftUp)
							closeLeftUp = !closeLeftUp
							handleCheckChangedUpRight(!closeRightUp)
							closeRightUp = !closeRightUp
							handleLogCheckedChanged(closeMiddleDown)
							closeMiddleDown = !closeMiddleDown
							window.hideWindows = true
						}
						if (zoom !== 100) {
							Qt.callLater(function() {
								applyZoomToPreview()
							})
						}
					}
				}

				ToolTip {
					 visible : hideWinMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: window.hideWindows ? "Unhide windows" : "Hide windows"
					}
				}			 
			}

			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				color: crosshairMouseArea.containsMouse ? "#12365a" : "transparent"

				// Left hover bar
				Rectangle {
					 width: 3
					height: parent.height
					color: crosshairMouseArea.containsMouse || window.isDotCrossHair || window.isCircleCrossHair || window.isPerpendicularCrossHair ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: crossHairIcon
					scale: sideMenuBar.iconVisualScale
					enabled : selectedDevCnt > 0 ? true : false
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
					source: crossHairIcon.enabled ? "qrc:View/icons/CrossHairOnHover.svg" : "qrc:View/icons/CrossHair.svg"
				}

				MouseArea {
					id: crosshairMouseArea
					objectName: "crosshairMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: crossHairIcon.enabled  // Disable interaction if image is disabled
					onClicked: {
						logController.displayMessage(verboseLogPriority, "UI: Cross Hair button clicked.\n");
						if (window.isDotCrossHair || window.isCircleCrossHair || window.isPerpendicularCrossHair) {
							// Turn off all crosshairs
							window.isDotCrossHair = false
							window.isCircleCrossHair = false
							window.isPerpendicularCrossHair = false

							// Sync the ComboBox and committed index back to "Off"
							crossHairSettingsWindow.lastCommittedIndex = 0
							crossHairSettingsWindow.applyFlags(0)
						} else {
							// Open the settings window to choose a crosshair
							crossHairSettingsWindow.lastCommittedIndex = 1
        					crossHairSettingsWindow.applyFlags(1)
						}
					}
				}

				ToolTip {
					 visible : crosshairMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Cross Hair"
					}
				}			 
			}

			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				color: gridMouseArea.containsMouse ? "#12365a" : "transparent"

				// Left hover bar
				Rectangle {
					 width: 3
					height: parent.height
					color: (gridMouseArea.containsMouse || window.isRuleOfThirdsGrid || window.isCenterGrid || window.isGoldenRatioGrid || window.isSquareGrid) ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: gridIcon
					scale: sideMenuBar.iconVisualScale
					enabled : selectedDevCnt > 0 ? true : false
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
					source: gridIcon.enabled ? "qrc:View/icons/GridOnHover.svg" : "qrc:View/icons/Grid.svg"
				}

				MouseArea {
					id: gridMouseArea
					objectName: "gridMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: gridIcon.enabled  // Disable interaction if image is disabled
					onClicked: {
						logController.displayMessage(verboseLogPriority, "UI: Grid button clicked.\n");
						if (window.isRuleOfThirdsGrid || window.isCenterGrid || window.isGoldenRatioGrid || window.isSquareGrid) {
							// Turn off all grids
							window.isRuleOfThirdsGrid = false
							window.isCenterGrid = false
							window.isGoldenRatioGrid = false
							window.isSquareGrid = false

							// Sync the ComboBox and committed index back to "Off"
							gridSettingsWindow.lastCommittedIndex = 0
							gridSettingsWindow.applyFlags(0)
						} else {
							// Open the settings window to choose a crosshair
							gridSettingsWindow.lastCommittedIndex = 1
        					     gridSettingsWindow.applyFlags(1)
						}
					}
				}

				ToolTip {
					 visible : gridMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Grid"
					}
				}			 
			}

			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				color: zoomOutMouseArea.containsMouse ? "#12365a" : "transparent"

				Rectangle {
					 width: 3
					height: parent.height
					color: zoomOutMouseArea.containsMouse || (selectedDevCnt == 1  && zoom != 100) ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: zoomOut
					scale: sideMenuBar.iconVisualScale
					enabled : window.zoomAllowed
					source: enabled ? "qrc:View/icons/ZoomOutOnHover.svg" : "qrc:View/icons/ZoomOut.svg"
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
				}

				MouseArea {
					id: zoomOutMouseArea
					objectName: "zoomOutMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: zoomOut.enabled
					onClicked: {
						logController.displayMessage(verboseLogPriority, "UI: Zoom button clicked.\n");
						zoomWindow.show()
						zoomWindow.raise()
					}
				}

				ToolTip {
					 visible : zoomOutMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Zoom In/ Out"
					}
				}
			}

			Rectangle {
				width: sideMenuBar.width 
				height: sideMenuBar.width - 5
				x: 0
				color: histogramMouseArea.containsMouse ? "#12365a" : "transparent"

				Rectangle {
					 width: 3
					height: parent.height
					color: histogramMouseArea.containsMouse || (selectedDevCnt > 0 && prevController && prevController.histogramWindowsVisible) ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: histogramIcon
					scale: sideMenuBar.iconVisualScale
					enabled : selectedDevCnt > 0 ? true : false
					source: enabled ? "qrc:View/icons/HistogramOnHover.svg" : "qrc:View/icons/Histogram.svg"
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
				}

				MouseArea {
					id: histogramMouseArea
					objectName: "histogramMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					enabled: histogramIcon.enabled
					onClicked: {
						prevController.toggleSelectedHistogramWindows()
						logController.displayMessage(verboseLogPriority, "UI: Histogram button clicked.\n");
					}
				}

				ToolTip {
					 visible : histogramMouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Histogram"
					}
				}
			}

			Rectangle {
				width: sideMenuBar.width
				height: sideMenuBar.width - 5
				x: 0
				color: abtMouseArea.containsMouse ? "#12365a" : "transparent"
				// Left hover bar
				Rectangle {
					 width: 3
					height: parent.height
					color: abtMouseArea.containsMouse ? "#2087cc" : "transparent"
					anchors.left: parent.left
				}

				Image {
					id: aboutIcon
					scale: sideMenuBar.iconVisualScale
					source: "qrc:View/icons/aboutOnHover.svg"// : "qrc:View/icons/about.svg"
					width: parent.width
					height: parent.height
					sourceSize: Qt.size(Math.ceil(width * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale), Math.ceil(height * sideMenuBar.iconVisualScale * sideMenuBar.iconRenderScale))
					fillMode: Image.PreserveAspectFit
					anchors.centerIn: parent
				}
				MouseArea {
					id: abtMouseArea
					objectName: "aboutMouseArea"
					anchors.fill: parent
					hoverEnabled: true
					onClicked: {
						logController.displayMessage(verboseLogPriority, "UI: About dialog\n");
						aboutDialog.show()
					}
				}
			
					ToolTip {
						 visible : abtMouseArea.containsMouse
						background: Rectangle {
						color: window.titleBarColor    // Background color
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "About"
					}
				}
				
			}			

			
		}

		// Captions occupy their own row beneath each icon. This overlay has no
		// MouseAreas, so the original sidebar actions retain the full hit targets.
		Column {
			id: navigationCaptions
			y: 4
			width: parent.width
			spacing: 4
			z: 20
			transformOrigin: Item.Top
			scale: Math.min(1, (sideMenuBar.height - y - 8) / Math.max(1, implicitHeight))

			Repeater {
				model: ["Capture", "Record", "Audio", "Storage", "Fit", "Windows",
						"Cross Hair", "Grid", "Zoom", "Histogram", "About"]
				delegate: Item {
					width: navigationCaptions.width
					height: sideMenuBar.width - 5

					Text {
						anchors.left: parent.left
						anchors.right: parent.right
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 3
						text: modelData
						color: "#dce6ef"
						font.pixelSize: 9
						horizontalAlignment: Text.AlignHCenter
						elide: Text.ElideRight
					}
				}
			}
		}

	}
