import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.12

Rectangle {
    id: statusBar
    width: parent ? parent.width : 800
    height: statusBarHeight
    color: "#091522"
	border.color: "#1f3040"
	border.width: 1
    anchors.bottom: parent ? parent.bottom : undefined
	property var firmwareVer: ""

    RowLayout {
	    id: statusBarRow
	    anchors.fill: parent
	    spacing: 0
	    anchors.leftMargin: 10
	    anchors.rightMargin: 10

	    // ── Segment 1: Copyright — fixed left ─────────────────────────
	    Text {
		id: cpyrightTxt
		Layout.preferredWidth: 220
		Layout.alignment: Qt.AlignVCenter
		font.family: "Helvetica"
		font.pixelSize: menuFontSize
		font.bold: true
		text: "e-con Systems India Pvt. Ltd"
		color: "#ffffff"
	    }

	    // ── Segment 2: Format — fixed position ────────────────────────
	    Text {
		id: formatTxt
		objectName: "formatTxt"
		Layout.preferredWidth: 160
		Layout.alignment: Qt.AlignVCenter
		visible: (selectedDevCnt === 1 && !fitToWindow) || (selectedDevCnt === 1 && zoom > 100)
		font.family: "Helvetica"
		font.pixelSize: menuFontSize
		font.bold: true
		text: ""
		color: "#ffffff"
	    }

	    // ── Segment 3: Resolution — fixed position ────────────────────
	    Text {
			id: resolutionTxt
			objectName: "resolutionTxt"
			Layout.preferredWidth: 180
			Layout.alignment: Qt.AlignVCenter
			visible: (selectedDevCnt === 1 && !fitToWindow) || (selectedDevCnt === 1 && zoom > 100)
			font.family: "Helvetica"
			font.pixelSize: menuFontSize
			font.bold: true
			text: ""
			color: "#ffffff"
	    }

	    // ── Segment 4: FPS — fixed position ───────────────────────────
	    Text {
			id: fpsTxt
			objectName: "fpsTxt"
			Layout.preferredWidth: 120
			Layout.alignment: Qt.AlignVCenter
			visible: (selectedDevCnt === 1 && !fitToWindow) || (selectedDevCnt === 1 && zoom > 100)
			font.family: "Helvetica"
			font.pixelSize: menuFontSize
			font.bold: true
			text: ""
			color: "#ffffff"
	    }

	    // ── Spacer — pushes zoom + status to right ────────────────────
	    Item {
			Layout.fillWidth: true
	    }

	    // ── Segment 5: Zoom controls — fixed width ────────────────────
	    Item {
			id: zoomGroup
			Layout.preferredWidth: 260
			Layout.alignment: Qt.AlignVCenter
			height: parent.height
			visible: zoomIndex >= 0
			enabled: zoomAllowed
			opacity: enabled ? 1.0 : 0.4

			RowLayout {
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				height: Math.min(18, parent.height)
				anchors.leftMargin: 4
				anchors.rightMargin: 4
				spacing: 3

				// Minus button
				Rectangle {
					Layout.preferredWidth: 14
					Layout.preferredHeight: 14
					radius: 2
					Layout.alignment: Qt.AlignVCenter
					color: zoomOutMa.containsMouse ? Qt.rgba(1,1,1,0.25) : Qt.rgba(1,1,1,0.12)
					border.color: Qt.rgba(1,1,1,0.5)
					border.width: 1
					opacity: zoom <= 50 ? 0.35 : 1.0

					Text {
						anchors.centerIn: parent
						text: "−"
						color: "white"
						font.pixelSize: 11
						font.bold: true
					}
					MouseArea {
						id: zoomOutMa
						anchors.fill: parent
						hoverEnabled: true
						enabled: zoom > 50
						onClicked: {
							zoom = Math.max(50, zoom - 25)
							applyZoomToPreview()
						}
					}
				}

				QQC2.Slider {
					id: zoomSlider
					Layout.fillWidth: true
					Layout.minimumWidth: 120
					Layout.preferredHeight: 18
					Layout.alignment: Qt.AlignVCenter
					topPadding: 0
					bottomPadding: 0

					from: 50
					to: 500
					stepSize: 25
					value: zoom

					onMoved: {
						if (selectedDevCnt === 1) {
							zoom = value
							applyZoomToPreview()
						}
					}

					background: Rectangle {
						x: zoomSlider.leftPadding
						y: zoomSlider.topPadding + zoomSlider.availableHeight / 2 - height / 2
						width: zoomSlider.availableWidth
						height: 3
						radius: 2
						color: Qt.rgba(1, 1, 1, 0.3)

						Rectangle {
							width: zoomSlider.visualPosition * parent.width
							height: parent.height
							radius: 2
							color: "white"
						}
					}

					handle: Rectangle {
						x: zoomSlider.leftPadding + zoomSlider.visualPosition * (zoomSlider.availableWidth - width)
						y: zoomSlider.topPadding + zoomSlider.availableHeight / 2 - height / 2
						width: 13
						height: 13
						radius: 7
						color: "white"
						border.color: "#2087cc"
						border.width: 2
					}
				}

				// Plus button
				Rectangle {
					Layout.preferredWidth: 14
					Layout.preferredHeight: 14
					radius: 2
					Layout.alignment: Qt.AlignVCenter
					color: zoomInMa.containsMouse ? Qt.rgba(1,1,1,0.25) : Qt.rgba(1,1,1,0.12)
					border.color: Qt.rgba(1,1,1,0.5)
					border.width: 1
					opacity: zoom >= 500 ? 0.35 : 1.0

					Text {
						anchors.centerIn: parent
						text: "+"
						color: "white"
						font.pixelSize: 11
						font.bold: true
					}
					MouseArea {
						id: zoomInMa
						anchors.fill: parent
						hoverEnabled: true
						enabled: zoom < 500
						onClicked: {
							zoom = Math.min(500, zoom + 25)
							applyZoomToPreview()
						}
					}
				}

				// Percentage label
				Text {
					Layout.preferredWidth: 32
					Layout.alignment: Qt.AlignVCenter
					text: zoom + "%"
					color: "white"
					font.pixelSize: menuFontSize
					font.bold: true
					font.family: "Helvetica"
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
				}

				// Reset button
				Rectangle {
					Layout.preferredWidth: 32
					Layout.preferredHeight: 16
					Layout.alignment: Qt.AlignVCenter
					radius: 3
					color: "transparent"
					border.color: Qt.rgba(1, 1, 1, zoom === 100 ? 0.35 : 0.7)
					opacity: zoom === 100 ? 0.45 : 1.0

					Text {
						anchors.centerIn: parent
						text: "Reset"
						color: "white"
						font.pixelSize: 9
						font.bold: true
					}
					MouseArea {
						anchors.fill: parent
						enabled: zoom !== 100
						onClicked: {
							zoom = 100
							applyZoomToPreview()
						}
					}
				}
			}
	    }

	    // ── Segment 6: Firmware — fixed position ──────────────────────
	   /* Text {
		id: firmwareVerTxt
		objectName: "firmwareVerTxt"
		Layout.preferredWidth: 150
		Layout.alignment: Qt.AlignVCenter
		font.family: "Helvetica"
		font.pixelSize: menuFontSize
		font.bold: true
		text: ""
		color: "#ffffff"
	    }*/

	    // ── Segment 7: Status — fixed right ───────────────────────────
	    Item {
			Layout.preferredWidth: 350
			Layout.alignment: Qt.AlignVCenter
			height: parent.height

			Text {
				id: statusText
				anchors.fill: parent
				horizontalAlignment: Text.AlignRight
				verticalAlignment: Text.AlignVCenter
				font.family: "Helvetica"
				font.pixelSize: menuFontSize
				font.bold: true
				color: "#ffffff"
				visible: loadingIndicator.visible || streamStatusText !== ""
				text: loadingIndicator.visible ? streamLoadingText : streamStatusText
			}

			Text {
				id: statusTxt
				objectName: "statusTxt"
				anchors.fill: parent
				horizontalAlignment: Text.AlignRight
				verticalAlignment: Text.AlignVCenter
				font.family: "Helvetica"
				font.pixelSize: menuFontSize
				font.bold: true
				color: "#ffffff"
				visible: !loadingIndicator.visible && streamStatusText === ""
				text: ""
				Behavior on text {
					SequentialAnimation {
						NumberAnimation {
							target: statusTxt
							property: "opacity"
							to: 0
							duration: 150
						}
						NumberAnimation {
							target: statusTxt
							property: "opacity"
							to: 1
							duration: 150
						}
					}
				}
			}
	    }
	}

	Timer {
		id: resetTimer
		interval: 1500
		running: false  
		repeat: false  
		onTriggered: {
			statusTxt.text = ""; 
			streamStatusText = ""   
		}
	}
	
	Timer {
		id: frameRateTimer
		interval: 1000
		running: false
		repeat: true  
		onTriggered: {
			prevController.getFps(0);
		}
	}

	Connections{
		target: prevController
		function onFormatChanged(index, format){
		 		formatTxt.text = "Format: " + format 
		}
		function onResolutionChanged(index, resolution){
				resolutionTxt.text = "Resolution: " + resolution
		}
		function onFpsChanged(index, fpsVal){
		 	 fpsTxt.text = "FPS: " + fpsVal 
		}
		// Handles prevController.cameraClosed signal: clears the FPS and status text; if a video
		// recording was active, stops it and its duration timer and reports it as saved.
		function onCameraClosed(){
			fpsTxt.text = ""
			statusTxt.text = ""
			if(window.videoRecord){
				videoRecord = false
				durationTimer.stop()
				statusTxt.text = "Video successfully saved."
				resetTimer.start()
			}
		}
		// Handles prevController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);				
			resetTimer.start()
		}
		// Handles prevController.centerStatusChanged signal: shows the stream status text, logs
		// it at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onCenterStatusChanged(status){
			streamStatusText = status 
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);				
			resetTimer.start()
		}
		// Handles prevController.devicesUpdated signal: when devStat is 1,
		// stops FPS polling and clears the FPS text.
		function onDevicesUpdated(index, devStat)
		{
			if (devStat === 1) {
				frameRateTimer.stop()
				fpsTxt.text = ""
			}
		}
	}

	Connections{
		target : wifiOnvifController
		// Handles wifiOnvifController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}

		// Handles wifiOnvifController.firmwareVersion signal: stores the firmware version and
		// shows it in firmwareVerTxt if that item exists.
		function onFirmwareVersion(firmwareVersion){
			firmwareVer = firmwareVersion
			if (typeof firmwareVerTxt !== 'undefined') {
				firmwareVerTxt.text = firmwareVer
			}
			//statusTxt.text = firmwareVer
		}
	}
	Connections {
		target: routecamOnvifController
		// Handles routecamOnvifController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : ecam212usbUvcextController
		// Handles ecam212usbUvcextController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3cam130eController
		// Handles see3cam130eController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3cam1318tcController
		// Handles see3cam1318tcController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu200Controller
		// Handles see3camcu200Controller.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu130Controller
		// Handles see3camcu130Controller.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu135mh01r1Controller
		// Handles see3camcu135mh01r1Controller.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3cam24cugController
		// Handles see3cam24cugController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu81Controller
		// Handles see3camcu81Controller.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3cam160Controller
		// Handles see3cam160Controller.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu27Controller
		// Handles see3camcu27Controller.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu512mController
		// Handles see3camcu512mController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3cam37cugController
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu135Controller
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu200mController
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu22Controller
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu31Controller
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu55Controller
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu55mhController
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu83Controller
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : ecam16usbController
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : ecam82usbController
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "
"
			logController.displayMessage(verboseLogPriority, message);
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu84Controller
		// Handles see3camcu84Controller.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : see3camcu58Controller
		// Handles see3camcu58Controller.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : densicamController
		// Handles densicamController.statusChanged signal: shows the status in the status bar, logs it
		// at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections {
		target : devController
		// Handles devController.deviceStatus signal: shows the status in the status bar, logs
		// it at verbose priority and starts resetTimer to clear it after 1.5 s.
		function onDeviceStatus(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}
	}
	Connections{
		target : window

		// Handles window.startVideoRecording signal: starts the recording duration timer on
		// success, otherwise shows "Video recording failed" and schedules it to clear.
		function onStartVideoRecording(status) {
			if (status) {
				durationTimer.start()
			} else {
				durationTimer.stop()
				statusTxt.text = "Video recording failed"
				resetTimer.start()
			}
		}

		// Handles window.stopVideoRecording signal: stops the duration timer and shows
		// "Video successfully saved." until resetTimer clears it.
		function onStopVideoRecording() {
			durationTimer.stop()
			statusTxt.text = "Video successfully saved."
			resetTimer.start()
		}

		// Handles window.statusChanged signal: shows the status in the status bar, logs it at
		// verbose priority and starts resetTimer to clear it after 1.5 s.
		function onStatusChanged(status){
			statusTxt. text = status;
			var message = status + "\n"
			logController.displayMessage(verboseLogPriority, message);	
			resetTimer.start()
		}		
	}
}
