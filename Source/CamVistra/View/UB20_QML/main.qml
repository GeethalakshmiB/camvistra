import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls 2.12 as QQC
import QtQuick.Controls.Material 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Qt.labs.platform 1.1
import DurationTimer 1.0
import qml.components.frameBufferObject 1.0

ApplicationWindow
{
    id: window
	visible: false
	flags: Qt.Window | Qt.FramelessWindowHint
	Material.theme: Material.Dark
	Material.accent: accentColor
	Material.background: panelBackground
	Material.foreground: "#dce6ef"
	color: appBackground

	// Give Qt a valid restore geometry before entering the maximized state.
	// Starting maximized with a desktop-sized width/height binding leaves the
	// frameless Windows backend with INT_MIN sentinel coordinates on restore.
	minimumHeight: Screen.desktopAvailableHeight * 0.60
    minimumWidth: Screen.desktopAvailableWidth * 0.60

	onClosing: {
		prevController.closeHistogramWindows()
	}
	
	property bool folderDialogOpened: false
	property bool windowsCustomMaximized: false

	property int infoLogPriority: 0
	property int verboseLogPriority: 1
	property int criticalLogPriority: 2
	property int menuBarHeight: 50
	property int titleBarHeight: Math.max(30, Math.min(38, Math.round(height * 0.035)))
	readonly property int topChromeHeight: titleBarHeight + menuBarHeight
	// Visual-only shell dimensions. Keep controller behavior independent of layout styling.
	property int navigationRailWidth: Math.max(72, Math.min(82, Math.round(width * 0.052)))
	property int devicesPanelWidth: Math.round(width * 0.18)
	readonly property color appBackground: "#07111d"
	readonly property color panelBackground: "#0d1926"
	readonly property color panelBackgroundRaised: "#111f2d"
	readonly property color panelBorder: "#263747"
	readonly property color accentColor: "#0b84f3"
	readonly property color titleBarColor: "#10283b"
	property int menuItemHeight : 0
	property int txtFieldW : 0
	property int txtFieldH : 0
	property int menuItemWidth : 0
	property int menuBtnWidth: 0
	property int logComboHeight : 0
	property int tabBarWidth : 0
	property int screenWidth :  0
	property int screenHeight : 0
	property int expandedStateIconW : 0
	property int expandedStateIconH : 0
	property int statusBarHeight : 18
	property int previewStatusBarHeight: 24
	readonly property int activePreviewStatusBarHeight: fitToWindow ? previewStatusBarHeight : 0
	property int fontSize : 13
	property int contentW: 0
	property int contentH: 0
	property int checkBoxH : 20
	property int checkBoxW : 20
	property int checkBoxFontSize : 0
	property int textFieldFontSize : 0
	property int clearLogH : 25
	property int clearLogW : 30
	property int selectedDeviceCount: 0
    property bool fboInstantiated: false
	property bool fitToWindow : false
	property bool hideWindows: false
    property int width_container : window.width * 0.185
	property int deviceh:leftContainer.height 
	property int wifiCntlh:rightContainer.height
	property string leftUpFile:"DevicesContainer.qml"
	property string rightUpFile
	property string middleDownFile:"LogContainer.qml"
	property string tempStillPath : ""
	property string tempVidRecPath : ""
	property var selectedDevCnt : 0
	property int deviceType : -1
	property int wifiDev : 1
	property int ethernetDev: 2
	property int usbDev: 3
	property bool isFboLoaded: false
	property bool closeLeftUp:false
	property bool closeRightUp:false
	property bool closeMiddleDown : false
	property bool isWindows : false
	property bool isDeviceChecked : false
	property bool videoRecord : false
	property bool isOnvifRecording: false
	property bool isFboDoubleClicked : false
	property int focusedFboIndex: -1  // tile shown alone after a double-click (multi-camera)
	property var visibleBeforeFocus: []  // per-tile visibility saved before a double-click expand
	property bool isControlUpdated : false
	property int baseFontSize : 10
	property int menuFontSize : 0
	property int abtFontSize : 20
	property int deviceScrollBarWidth : 0
	property bool isCameraOpened : false
	property var scaleFactor : 1
	property var controlSelectedDevName : ""
	
	// ADD after existing properties:
	property var controlSelectedVid
	property var controlSelectedPid
	property bool isPerpendicularCrossHair : false
	property bool isCircleCrossHair : false
	property bool isDotCrossHair : false
	property bool isRuleOfThirdsGrid : false
	property bool isCenterGrid : false
	property bool isGoldenRatioGrid : false
	property bool isSquareGrid : false
	property string streamLoadingText: "Stream Initializing"
	property string streamStatusText: "" 
	property int dotCount: 0
	property int zoom : 100
	// Controllers that expose multiCameraCapture (the Python app) capture and
	// record every open camera; otherwise (the C++ app) only single-camera.
	readonly property bool multiCameraCapture: !!prevController && prevController.multiCameraCapture === true
	readonly property bool captureEnabled: selectedDevCnt == 1 || (multiCameraCapture && selectedDevCnt > 1)
	// Single rule for every zoom control (sidebar, menu bar, status bar, zoom
	// window, mouse wheel): one camera, and fit-to-window on. With "Disable Fit
	// to window" (actual size) zoom is disabled.
	// Tile that zoom applies to: the only camera, or the tile double-clicked to
	// show alone in multi-camera; -1 while the multi-camera grid is shown.
	readonly property int zoomIndex: selectedDevCnt === 1 ? 0
		: (isFboDoubleClicked && focusedFboIndex >= 0 && focusedFboIndex < selectedDevCnt) ? focusedFboIndex : -1
	readonly property bool zoomAllowed: fitToWindow && zoomIndex >= 0
	// Leaving the zoomable view (back to the grid, camera added/removed) drops the zoom
	onZoomIndexChanged: {
		if (zoomIndex < 0 && zoom !== 100) {
			zoom = 100
			fboFlickable.contentWidth = 0
			fboFlickable.contentHeight = 0
			fboFlickable.contentX = 0
			fboFlickable.contentY = 0
		}
	}
	// Adding or removing a camera ends the single-tile (double-clicked) view.
	// Otherwise the stale focus would lay a re-added camera over the whole
	// preview area on top of the other tiles.
	onSelectedDevCntChanged: {
		if (!isFboDoubleClicked)
			return
		isFboDoubleClicked = false
		focusedFboIndex = -1
		// Un-hide the tiles the double-click hid; a tile still opening
		// (format "--") is shown by onCameraOpened as usual.
		for (var i = 0; i < fboModel.count; i++) {
			if (fboModel.get(i).format !== "--")
				setFboRow(i, { visible: true })
		}
	}
	property bool zoomScrollbarsEnabled: true
	property int activeHistogramMode: 0
	onZoomChanged: {
		if (zoom !== 100 && !fitToWindow)
			fitToWindow = true
	}

	property var selectedDevType: ""
	property bool audioDeviceAvailable: false
	property bool audioDeviceSelected: false

	property int hours
    property int minutes
    property int seconds
	property int modifiedScreenWidth : 0

	property var selectedDevices : []

	signal folderPath();
	signal vidRecFolderPath();
	signal selectedStillFolderPath(string path);
	signal selectedVideoFolderPath(string path);
	signal statusChanged(string status);
	signal fboLoaded()
    signal viewLoaded();
	signal fitToWinStatusChanged(bool fitToWindowFlag);
	signal updateProperty(int index)
	signal startVideoRecording(bool status)
	signal stopVideoRecording()

	function showMainWindow() {
		window.visible = true
		if (Qt.platform.os === "windows")
			customTitleBar.maximizeWindow()
		else
			window.showMaximized()
	}

	// Testing property
	property bool videoRecordingStarted: false
	property bool reopenRightContainerAfterRecording: false

	signal wifiResolutionChanged()
	signal mouseRightClicked(var x, var y, var width, var height)
	
	// Key handler for the whole window
    Item {
        anchors.fill: parent
        focus: true                  // Request focus on startup
        
        Connections {
            target: window
            onActiveFocusItemChanged: {
                if (window.activeFocusItem === null)
                    keyHandler.forceActiveFocus()
            }
        }
    }

    FocusScope {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
				if(captureEnabled){
					captureStillImage()
					event.accepted = true
				}
            }
        }

		Keys.onEscapePressed: {
			if ( hideWindows ){
				logController.displayMessage(verboseLogPriority, "UI: UnHide Window button clicked.\n");
				handleCheckedChanged(closeLeftUp)
				closeLeftUp = !closeLeftUp
				handleCheckChangedUpRight(!closeRightUp)
				closeRightUp = !closeRightUp
				handleLogCheckedChanged(closeMiddleDown)
				closeMiddleDown = !closeMiddleDown
				window.hideWindows = false
			}
		}
    }

	Timer {
		id: focusRestoreTimer
		interval: 1000
		repeat: false
		onTriggered: {
			keyHandler.forceActiveFocus()
		}
	}

	Timer {
		id: loadingTextTimer
		interval: 150
		repeat: true
		running: false

		onTriggered: {
			dotCount = (dotCount + 1) % 4
			streamLoadingText = "Stream Initializing" + ".".repeat(dotCount)
		}
	}

	Timer {
		id: fpsTimer
		interval: 1000
		running: false
		repeat: true  
		onTriggered: {
			for ( var i = 0 ; i < selectedDevCnt ; i++){
				prevController.getFps(i);
			}
		}
	} 

    onHeightChanged: {
        
		if(aboutDialog.visible){
			aboutDialog.close()
		}else{		
			aboutDialog.x = (aboutDialog.parent ? aboutDialog.parent.width : Screen.width) / 2 - aboutDialog.width / 2
			aboutDialog.y = (aboutDialog.parent ? aboutDialog.parent.height : Screen.height) / 2 - aboutDialog.height / 2
		}
		if(stillCaptureWindow.visible){
			stillCaptureWindow.close()
		}else{	
			stillCaptureWindow.x = (stillCaptureWindow.parent ? stillCaptureWindow.parent.width : Screen.width) / 2 - stillCaptureWindow.width / 2
			stillCaptureWindow.y = (stillCaptureWindow.parent ? stillCaptureWindow.parent.height : Screen.height) / 2 - stillCaptureWindow.height / 2
		}

		if(vidRecWindow.visible){
			vidRecWindow.close()
		} else{	
			vidRecWindow.x = (vidRecWindow.parent ? vidRecWindow.parent.width : Screen.width) / 2 - vidRecWindow.width / 2
			vidRecWindow.y = (vidRecWindow.parent ? vidRecWindow.parent.height : Screen.height) / 2 - vidRecWindow.height / 2
		}

		if(filePathWindow.visible){
			filePathWindow.close()
		}else{
			filePathWindow.x = (filePathWindow.parent ? filePathWindow.parent.width : Screen.width) / 2 - filePathWindow.width / 2
			filePathWindow.y = (filePathWindow.parent ? filePathWindow.parent.height : Screen.height) / 2 - filePathWindow.height / 2
		}

		if(closeMiddleDown){
			descriptionOuterRect.height =0
			middle_con_down.height =0
			leftContainer.height = height - topChromeHeight
			left_con_up.height = height - topChromeHeight
			rightContainer.height = height - topChromeHeight
			right_con_up.height = height - topChromeHeight
			setFitToWindow();
		} else{
			leftContainer.height = height - topChromeHeight
			left_con_up.height = height - topChromeHeight
			descriptionOuterRect.height = container.height * 0.30
			middle_con_down.height = container.height * 0.30
			rightContainer.height = height - topChromeHeight
			right_con_up.height = height - topChromeHeight
			setFitToWindow();
		}
    }

	onWidthChanged: {
		if(Screen.desktopAvailableWidth > width){
			modifiedScreenWidth = width
		} else{
			modifiedScreenWidth = 0
		}
		if(aboutDialog.visible){
			aboutDialog.close()
		}else{		
			aboutDialog.x = (aboutDialog.parent ? aboutDialog.parent.width : Screen.width) / 2 - aboutDialog.width / 2
			aboutDialog.y = (aboutDialog.parent ? aboutDialog.parent.height : Screen.height) / 2 - aboutDialog.height / 2
		}
		if(stillCaptureWindow.visible){
			stillCaptureWindow.close()
		}else{	
			stillCaptureWindow.x = (stillCaptureWindow.parent ? stillCaptureWindow.parent.width : Screen.width) / 2 - stillCaptureWindow.width / 2
			stillCaptureWindow.y = (stillCaptureWindow.parent ? stillCaptureWindow.parent.height : Screen.height) / 2 - stillCaptureWindow.height / 2
		}

		if(vidRecWindow.visible){
			vidRecWindow.close()
		}else{	
			vidRecWindow.x = (vidRecWindow.parent ? vidRecWindow.parent.width : Screen.width) / 2 - vidRecWindow.width / 2
			vidRecWindow.y = (vidRecWindow.parent ? vidRecWindow.parent.height : Screen.height) / 2 - vidRecWindow.height / 2
		}
		if(filePathWindow.visible){
			filePathWindow.close()
		}else{	
			filePathWindow.x = (filePathWindow.parent ? filePathWindow.parent.width : Screen.width) / 2 - filePathWindow.width / 2
			filePathWindow.y = (filePathWindow.parent ? filePathWindow.parent.height : Screen.height) / 2 - filePathWindow.height / 2
		}
		if(closeRightUp){
			rightContainer.width = 0
			container.width = width * 0.785
			renderingRect.width = container.width
			previewInnerRect.width = renderingRect.width 
			middleIntersection.width = container.width
			descriptionOuterRect.width = width - leftContainer.width - rightContainer.width - sideBar.width
			middle_con_down.width = descriptionOuterRect.width
			setFitToWindow();
		} else if (closeLeftUp){
			leftContainer.width = 0
			container.width = width - leftContainer.width - rightContainer.width - sideBar.width
			renderingRect.width = width - leftContainer.width - rightContainer.width - sideBar.width
			previewInnerRect.width = renderingRect.width 
			middleIntersection.width = container.width	
			descriptionOuterRect.width = width - leftContainer.width - rightContainer.width - sideBar.width
			middle_con_down.width = descriptionOuterRect.width
			setFitToWindow();
		}
		else{
			leftContainer.width = devicesPanelWidth
			left_con_up.width = leftContainer.width
			rightContainer.width = deviceType > 0 ?  width * 0.22 : 0
			descriptionOuterRect.width = width - leftContainer.width - rightContainer.width - sideBar.width
			container.width = width - leftContainer.width - rightContainer.width - sideBar.width
			renderingRect.width = width - leftContainer.width - rightContainer.width- sideBar.width
			previewInnerRect.width = renderingRect.width 
			middleIntersection.width = container.width
			middle_con_down.width = descriptionOuterRect.width 
			setFitToWindow();
		}
	}

    // Timer component to delay the signal emission
     Timer {
		id: uiDelayTimer
        interval: 1000
        repeat: false
        onTriggered: {
            viewLoaded();
        }
    }

	Component.onCompleted: {
		// These are deliberately one-time assignments. Geometry bindings would
		// continue to fight the native maximize/restore transition on Windows.
		window.width = Math.round(Screen.desktopAvailableWidth * 0.85);
		window.height = Math.round(Screen.desktopAvailableHeight * 0.85);
		window.x = Screen.virtualX + Math.round((Screen.desktopAvailableWidth - window.width) / 2);
		window.y = Screen.virtualY + Math.round((Screen.desktopAvailableHeight - window.height) / 2);
		devController.readJsonArrayFile();
        uiDelayTimer.start();
		if (Qt.platform.os === "windows") {
			isWindows = true
			window.selectedVideoFolderPath(StandardPaths.writableLocation(StandardPaths.DesktopLocation))
        	window.selectedStillFolderPath(StandardPaths.writableLocation(StandardPaths.DesktopLocation))
		} else{
			isWindows = false
			window.selectedVideoFolderPath(SystemVideoFolder)
			window.selectedStillFolderPath(SystemPictureFolder)
		}
     }

	 

	 Connections {
        target: MonitorHandler


	onResolutionChanged: {
			screenWidth =  MonitorHandler.screenResolution.width
			screenHeight =  MonitorHandler.screenResolution.height

		
			menuBarHeight = 0.03 * MonitorHandler.screenResolution.height;
			menuBtnWidth = 0.05856 * MonitorHandler.screenResolution.width;
			menuItemHeight = 0.036 * MonitorHandler.screenResolution.height;
			statusBarHeight = 0.0234 * MonitorHandler.screenResolution.height;
			logComboHeight = 0.0651 * MonitorHandler.screenResolution.height;
			tabBarWidth = 0.1464 * MonitorHandler.screenResolution.width;
			menuItemWidth = 0.0732 * MonitorHandler.screenResolution.width;
			txtFieldW = 0.03075 * MonitorHandler.screenResolution.width;
			txtFieldH = 0.03255 * MonitorHandler.screenResolution.height;
			expandedStateIconH = 15//0.0195 * MonitorHandler.screenResolution.height;
			expandedStateIconW = 15//0.01098 * MonitorHandler.screenResolution.width;
			checkBoxW = 20 //0.0168 * MonitorHandler.screenResolution.width;
			checkBoxH = 20//0.0299 * MonitorHandler.screenResolution.height;
			clearLogW = 0.02196 * MonitorHandler.screenResolution.width;
			
			baseFontSize = 10//MonitorHandler.logicalDpi / 9.6;
			textFieldFontSize = 11// MonitorHandler.logicalDpi / 8;
			menuFontSize = 12//MonitorHandler.logicalDpi / 7;
			checkBoxFontSize =  13//MonitorHandler.logicalDpi / 6;
			abtFontSize = 14//MonitorHandler.logicalDpi / 5
       
        }

        onDpiChanged: {
			scaleFactor = (MonitorHandler.logicalDpi / 96)
			baseFontSize = 10 //(MonitorHandler.logicalDpi / 9.6) / scaleFactor ;
			textFieldFontSize =  11// ( MonitorHandler.logicalDpi / 8 ) / scaleFactor ;
			menuFontSize = 12 //( MonitorHandler.logicalDpi / 7 ) / scaleFactor ;
			checkBoxFontSize = 13// ( MonitorHandler.logicalDpi / 6 ) / scaleFactor 
			abtFontSize = 14//( MonitorHandler.logicalDpi / 5 ) / scaleFactor 
        }
    }


	 Connections{
		target: window
		onFolderPath: {
			folderDialogOpened = true
			folderDialog.open()
		}
		onVidRecFolderPath: {
			vidRecFolderDialog.open()
		}
		onSelectedStillFolderPath: {
            path = path.toString()
			// Platform detection
			 if (Qt.platform.os === "windows") {
				// Windows uses 'file:///'
				path = path.replace("file:///", "");
			} else {
				// Linux and macOS typically use 'file://'
				path = path.replace("file://", "");
			}
			if( stillCaptureWindow.path != ""){
				tempStillPath = stillCaptureWindow.path
			} else{
				tempStillPath = path
			}
			stillCaptureWindow.path = path
			filePathWindow.stillPath = path
			prevController.setStillFolderPath(path)
		}
		onSelectedVideoFolderPath: {

			path = path.toString()
			// Platform detection
			 if (Qt.platform.os === "windows") {
				// Windows uses 'file:///'
				path = path.replace("file:///", "");
			} else {
				// Linux and macOS typically use 'file://'
				path = path.replace("file://", "");
			}
			if( vidRecWindow.path != ""){
				tempVidRecPath = vidRecWindow.path
			} else{				
				tempVidRecPath = path
			}
			vidRecWindow.path = path
			filePathWindow.videoPath = path
			prevController.setVideoFolderPath(path)
		}
		onFitToWinStatusChanged: {
			setFitToWindow();
		}
	}

	// Left Container
	Rectangle {
		id: leftContainer
		width: devicesPanelWidth
		anchors.left: sideBar.right
		anchors.top: menuBar.bottom
		anchors.bottom: importStatusBar.top
		color: panelBackground
		border.color: panelBorder
		border.width: 1

		 MouseArea {
			anchors.fill: parent  // This will make the MouseArea fill the entire ApplicationWindow
			onClicked: {
				// Close the AboutDialog when the ApplicationWindow is clicked
				if (aboutDialog.visible) {
					aboutDialog.close()
				}
			}
		}
	}
  
    // Main Container
    Rectangle {
        id: container
        width: deviceType > 0 ? window.width * 0.60 : window.width * 0.785
        height: window.height - topChromeHeight - importStatusBar.height
        anchors.left: leftContainer.right
        anchors.right:rightContainer.left
        y: topChromeHeight
        color: appBackground   

        // Main Box (Camera Stream Camera)
        Rectangle {
            id: renderingRect
            width: container.width
			// Keep the preview clipped exactly at the top edge of the separator.
			// middleIntersection is not a sibling, so it cannot be used as an
			// anchor target from here; derive the height in window coordinates.
			height: Math.max(0, middleIntersection.y - container.y)
			anchors.top : container.top
            color: appBackground
			border.color: panelBorder
			border.width: 1
            clip: true

			Rectangle {
				id: previewInnerRect
				width: parent.width
				height: parent.height 
				anchors.top : renderingRect.top
				color: appBackground
		
				// Busy indicator
				BusyIndicator {
					id: loadingIndicator
					anchors.centerIn: previewInnerRect
					running: selectedDeviceCount > 0 && !isCameraOpened
					visible: selectedDeviceCount > 0 && !isCameraOpened
					property bool componentReady: false

					Component.onCompleted: {
						componentReady = true
						// Handle case where visible is already true at startup
						if (visible) {
							dotCount = 0
							streamStatusText = ""
							streamLoadingText = "Stream Initializing"
							loadingTextTimer.restart()
						}
					}

					onVisibleChanged: {
						if (!componentReady) return    // ← guard against early firing

						if (visible) {
							dotCount = 0
							streamStatusText = ""
							streamLoadingText = "Stream Initializing"
							loadingTextTimer.restart()
						} else {
							loadingTextTimer.stop()
							streamLoadingText = ""
						}
					}

					contentItem: Canvas {
						id: spinnerCanvas
						implicitWidth: 48
						implicitHeight: 48

						property real angle: 0

						onPaint: {
							var ctx = getContext("2d")
							ctx.clearRect(0, 0, width, height)

							var cx = width / 2
							var cy = height / 2
							var r = Math.min(width, height) / 2 - 4

							// Track (background ring)
							ctx.beginPath()
							ctx.arc(cx, cy, r, 0, Math.PI * 2)
							ctx.strokeStyle = "#1a3a4a"   // dim track
							ctx.lineWidth = 4
							ctx.lineCap = "round"
							ctx.stroke()

							// Active arc in #2087cc
							ctx.beginPath()
							ctx.arc(cx, cy, r, angle, angle + Math.PI * 1.2)
							ctx.strokeStyle = "#2087cc"
							ctx.lineWidth = 4
							ctx.lineCap = "round"
							ctx.stroke()
						}

						RotationAnimator {
							target: spinnerCanvas
							running: loadingIndicator.running
							from: 0
							to: 360
							loops: Animation.Infinite
							duration: 1000
						}

						// Redraw every frame while running
						Timer {
							interval: 16
							repeat: true
							running: loadingIndicator.running
							onTriggered: spinnerCanvas.requestPaint()
						}
					}
				}
				
				Flickable {
					id: fboFlickable
					anchors.fill: parent
					// Reserve a separate row for the horizontal scrollbar so it
					// never overlays the preview content.
					anchors.bottomMargin: customHScrollBar.visible ? customHScrollBar.height : 0
					contentWidth: 0
					contentHeight:  0
					y : previewInnerRect.y
					clip: true
					interactive: true
					boundsBehavior: Flickable.StopAtBounds

					
                    ListModel {
                        id: fboModel
                    }

                    Loader {
                        id: fboLoader
                        sourceComponent: fboInstantiated ? fboComponent : null
                        onStatusChanged: {
                            if (status === Loader.Ready) {
                                fboLoaded();  // Emit the signal when the loader is ready
                            }
                            if (status === Loader.Null) {
                            }
                        }
                    }

                    Component {
						id: fboComponent
						Rectangle {
							objectName: "fboCompModel"
							Component.onDestruction: {
								fboFlickable.contentWidth = 0
								fboFlickable.contentHeight = 0
							}
							Repeater {
								objectName : "fboRepeater"
								model: fboModel

								 Rectangle {
									id: fboContainer
									objectName: model.objectName + "_container"
									width: model.rectWidth
									height: model.rectHeight
									// The tile (and its status bar) stays visible for every
									// checked camera, so a camera that delivers no frames
									// still shows "-- | -- | 0fps". The FBO itself follows
									// model.visible. While a tile is expanded by double-click
									// only that tile is shown — even when it has no frames, so
									// its double-click area stays reachable to collapse again.
									visible : (model.visible ? true : false)
										|| (index < selectedDevCnt && !isFboDoubleClicked)
										|| (isFboDoubleClicked && index === focusedFboIndex)
									x: model.rectX
									y : model.rectY
									color: "transparent"   // or some background if you want

									FrameBufferObject {
										id: fbo
										objectName: model.objectName ? model.objectName : ""
										x:  model.fboX ? model.fboX : 0
										y: model.fboY ? model.fboY : 0
										width: model.fboWidth ? model.fboWidth : parent.width
										height :  model.fboHeight ? model.fboHeight : parent.height
										visible : model.visible ? model.visible : false
									}

									// Camera name in the top-left corner of the tile
									Rectangle {
										id: cameraNameBadge
										x: fbo.x + 6
										y: fbo.y + 6
										z: 5
										width: Math.min(cameraNameText.implicitWidth + 12, Math.max(0, fbo.width - 12))
										height: cameraNameText.implicitHeight + 6
										radius: 3
										color: "#99000000"
										visible: fbo.visible && fbo.width > 40 && !!model.cameraName
										Text {
											id: cameraNameText
											anchors.fill: parent
											anchors.leftMargin: 6
											anchors.rightMargin: 6
											verticalAlignment: Text.AlignVCenter
											text: model.cameraName ? model.cameraName : ""
											color: "white"
											font.pixelSize: 12
											elide: Text.ElideRight
										}
									}

									Item {
										id: histogramSelectionOverlay
										anchors.fill: fbo
										visible: (model.histogramMode ? model.histogramMode : 0) > 0
										z: 4

										property int selectionMode: model.histogramMode ? model.histogramMode : 0
										property int minRoiSize: 24
										property int activeStartX: 0
										property int activeStartY: 0
										property int startX: 0
										property int startY: 0
										property int startWidth: 0
										property int startHeight: 0
										property bool selectionCommitPending: false

										function clamp(value, minValue, maxValue) {
											return Math.max(minValue, Math.min(maxValue, value))
										}

										// Sends the current histogram selection (mode and rounded ROI/line geometry,
										// plus the overlay size) for this camera to prevController.setHistogramSelection().
										function sendSelection() {
											prevController.setHistogramSelection(
												index,
												selectionMode,
												Math.round(selectionRect.x),
												Math.round(selectionRect.y),
												Math.round(selectionRect.width),
												Math.round(selectionRect.height),
												Math.round(width),
												Math.round(height))
										}

										// Commits the histogram selection immediately: cancels any pending timer
										// commit, stores the geometry in fboModel and sends it to the controller.
										function commitSelection() {
											selectionCommitPending = false
											selectionCommitTimer.stop()
											persistSelectionModel()
											sendSelection()
										}

										// Throttles selection updates: starts the 50 ms selectionCommitTimer (which
										// calls sendSelection) unless a commit is already pending.
										function scheduleSelectionCommit() {
											if (selectionCommitPending)
												return

											selectionCommitPending = true
											selectionCommitTimer.restart()
										}

										Timer {
											id: selectionCommitTimer
											interval: 50
											repeat: false
											onTriggered: {
												histogramSelectionOverlay.selectionCommitPending = false
												histogramSelectionOverlay.sendSelection()
											}
										}

										// Stores the current selection rectangle (rounded) as histX/histY/histWidth/
										// histHeight in this camera's fboModel entry.
										function persistSelectionModel() {
											setFboRow(index, {
												histX: Math.round(selectionRect.x),
												histY: Math.round(selectionRect.y),
												histWidth: Math.round(selectionRect.width),
												histHeight: Math.round(selectionRect.height)
											})
										}

										// Resets the selection shape for a histogram mode: 1 = centred ROI box (35% of
										// the overlay, min 40px), 2 = 1px vertical line, 3 = 1px horizontal line,
										// otherwise the full frame. Schedules sending it to the controller.
										function applySelectionGeometry(mode) {
											var lineThickness = 1
											var x = 0
											var y = 0
											var w = width
											var h = height

											if (mode === 1) {
												w = Math.max(40, Math.round(width * 0.35))
												h = Math.max(40, Math.round(height * 0.35))
												x = Math.round((width - w) / 2)
												y = Math.round((height - h) / 2)
											} else if (mode === 2) {
												w = lineThickness
												h = height
												x = Math.round((width - w) / 2)
											} else if (mode === 3) {
												w = width
												h = lineThickness
												y = Math.round((height - h) / 2)
											}

											selectionRect.x = x
											selectionRect.y = y
											selectionRect.width = w
											selectionRect.height = h
											persistSelection()
										}

										onSelectionModeChanged: applySelectionGeometry(selectionMode)
										onWidthChanged: syncToOverlaySize()
										onHeightChanged: syncToOverlaySize()

										// Called after every selection change; defers the controller update through
										// scheduleSelectionCommit() so drags do not flood it.
										function persistSelection() {
											scheduleSelectionCommit()
										}

										// Re-fits the selection to a resized overlay: keeps line modes full-length and
										// clamps the ROI box inside the overlay, then schedules a commit.
										function syncToOverlaySize() {
											if (!visible || width <= 0 || height <= 0)
												return

											if (selectionMode === 2) {
												selectionRect.width = 1
												selectionRect.height = height
												selectionRect.x = clamp(selectionRect.x, 0, width - selectionRect.width)
												selectionRect.y = 0
												persistSelection()
											} else if (selectionMode === 3) {
												selectionRect.width = width
												selectionRect.height = 1
												selectionRect.x = 0
												selectionRect.y = clamp(selectionRect.y, 0, height - selectionRect.height)
												persistSelection()
											} else if (selectionMode === 1) {
												selectionRect.width = clamp(selectionRect.width, 1, width)
												selectionRect.height = clamp(selectionRect.height, 1, height)
												selectionRect.x = clamp(selectionRect.x, 0, width - selectionRect.width)
												selectionRect.y = clamp(selectionRect.y, 0, height - selectionRect.height)
												persistSelection()
											}
										}

										// Records the mouse start point and the selection geometry at the start of an
										// ROI resize drag.
										function beginResize(mousePoint) {
											activeStartX = mousePoint.x
											activeStartY = mousePoint.y
											startX = selectionRect.x
											startY = selectionRect.y
											startWidth = selectionRect.width
											startHeight = selectionRect.height
										}

										// Resizes the ROI box from a drag on handle (any combination of "l", "r", "t",
										// "b" edges), clamped to the overlay and to minRoiSize, then schedules a commit.
										function resizeFromHandle(handle, mousePoint) {
											var dx = mousePoint.x - activeStartX
											var dy = mousePoint.y - activeStartY
											var newX = startX
											var newY = startY
											var newW = startWidth
											var newH = startHeight

											if (handle.indexOf("l") >= 0) {
												newX = clamp(startX + dx, 0, startX + startWidth - minRoiSize)
												newW = startWidth + startX - newX
											}
											if (handle.indexOf("r") >= 0)
												newW = clamp(startWidth + dx, minRoiSize, width - startX)
											if (handle.indexOf("t") >= 0) {
												newY = clamp(startY + dy, 0, startY + startHeight - minRoiSize)
												newH = startHeight + startY - newY
											}
											if (handle.indexOf("b") >= 0)
												newH = clamp(startHeight + dy, minRoiSize, height - startY)

											selectionRect.x = newX
											selectionRect.y = newY
											selectionRect.width = newW
											selectionRect.height = newH
											persistSelection()
										}

										// Records the mouse start point and the line position at the start of a
										// vertical/horizontal line drag.
										function beginLineDrag(mousePoint) {
											activeStartX = mousePoint.x
											activeStartY = mousePoint.y
											startX = selectionRect.x
											startY = selectionRect.y
										}

										// Moves the vertical histogram line horizontally by the drag delta, clamped to
										// the overlay width, then schedules a commit.
										function moveVerticalLine(mousePoint) {
											var dx = mousePoint.x - activeStartX
											selectionRect.x = clamp(startX + dx, 0, width - selectionRect.width)
											persistSelection()
										}

										// Moves the horizontal histogram line vertically by the drag delta, clamped to
										// the overlay height, then schedules a commit.
										function moveHorizontalLine(mousePoint) {
											var dy = mousePoint.y - activeStartY
											selectionRect.y = clamp(startY + dy, 0, height - selectionRect.height)
											persistSelection()
										}

										Rectangle {
											id: selectionRect
											x: model.histX ? model.histX : 0
											y: model.histY ? model.histY : 0
											width: histogramSelectionOverlay.selectionMode === 2
												? 1
												: (model.histWidth ? model.histWidth : parent.width)
											height: histogramSelectionOverlay.selectionMode === 3
												? 1
												: (model.histHeight ? model.histHeight : parent.height)
											color: histogramSelectionOverlay.selectionMode === 2
												|| histogramSelectionOverlay.selectionMode === 3
												? (model.histColor ? model.histColor : "#20b7ff")
												: "transparent"
											border.color: model.histColor ? model.histColor : "#20b7ff"
											border.width: histogramSelectionOverlay.selectionMode === 1 ? 2 : 0
											visible: histogramSelectionOverlay.visible

											MouseArea {
												id: roiMoveArea
												anchors.fill: parent
												enabled: histogramSelectionOverlay.selectionMode === 1
												cursorShape: Qt.SizeAllCursor
												preventStealing: true
												drag.target: parent
												drag.minimumX: 0
												drag.maximumX: histogramSelectionOverlay.width - parent.width
												drag.minimumY: 0
												drag.maximumY: histogramSelectionOverlay.height - parent.height
												onPositionChanged: if (drag.active) histogramSelectionOverlay.persistSelection()
												onReleased: {
													histogramSelectionOverlay.persistSelection()
													histogramSelectionOverlay.commitSelection()
												}
												onCanceled: {
													histogramSelectionOverlay.persistSelection()
													histogramSelectionOverlay.commitSelection()
												}
											}

											Repeater {
												model: [
													{ handle: "lt", x: 0, y: 0, cursor: Qt.SizeFDiagCursor },
													{ handle: "rt", x: 1, y: 0, cursor: Qt.SizeBDiagCursor },
													{ handle: "rb", x: 1, y: 1, cursor: Qt.SizeFDiagCursor },
													{ handle: "lb", x: 0, y: 1, cursor: Qt.SizeBDiagCursor }
												]

												delegate: Rectangle {
													width: 14
													height: 14
													x: selectionRect.width * modelData.x - width / 2
													y: selectionRect.height * modelData.y - height / 2
													color: model.histColor ? model.histColor : "#20b7ff"
													visible: histogramSelectionOverlay.selectionMode === 1
													z: 10

													MouseArea {
														id: handleMouseArea
														anchors.centerIn: parent
														width: 24
														height: 24
														cursorShape: modelData.cursor
														preventStealing: true
														onPressed: histogramSelectionOverlay.beginResize(mapToItem(histogramSelectionOverlay, mouse.x, mouse.y))
														onPositionChanged: {
															if (pressed)
																histogramSelectionOverlay.resizeFromHandle(modelData.handle, mapToItem(histogramSelectionOverlay, mouse.x, mouse.y))
														}
														onReleased: histogramSelectionOverlay.commitSelection()
														onCanceled: histogramSelectionOverlay.commitSelection()
													}
												}
											}
										}

										Rectangle {
											id: verticalLineHit
											x: selectionRect.x - 6
											y: 0
											width: selectionRect.width + 12
											height: parent.height
											color: "transparent"
											visible: histogramSelectionOverlay.selectionMode === 2
											z: 20

											MouseArea {
												id: verticalLineMouseArea
												anchors.fill: parent
												cursorShape: Qt.SizeHorCursor
												preventStealing: true
												onPressed: histogramSelectionOverlay.beginLineDrag(mapToItem(histogramSelectionOverlay, mouse.x, mouse.y))
												onPositionChanged: {
													if (pressed)
														histogramSelectionOverlay.moveVerticalLine(mapToItem(histogramSelectionOverlay, mouse.x, mouse.y))
												}
												onReleased: {
													histogramSelectionOverlay.persistSelection()
													histogramSelectionOverlay.commitSelection()
												}
												onCanceled: {
													histogramSelectionOverlay.persistSelection()
													histogramSelectionOverlay.commitSelection()
												}
											}
										}

										Rectangle {
											id: horizontalLineHit
											x: 0
											y: selectionRect.y - 6
											width: parent.width
											height: selectionRect.height + 12
											color: "transparent"
											visible: histogramSelectionOverlay.selectionMode === 3
											z: 20

											MouseArea {
												id: horizontalLineMouseArea
												anchors.fill: parent
												cursorShape: Qt.SizeVerCursor
												preventStealing: true
												onPressed: histogramSelectionOverlay.beginLineDrag(mapToItem(histogramSelectionOverlay, mouse.x, mouse.y))
												onPositionChanged: {
													if (pressed)
														histogramSelectionOverlay.moveHorizontalLine(mapToItem(histogramSelectionOverlay, mouse.x, mouse.y))
												}
												onReleased: {
													histogramSelectionOverlay.persistSelection()
													histogramSelectionOverlay.commitSelection()
												}
												onCanceled: {
													histogramSelectionOverlay.persistSelection()
													histogramSelectionOverlay.commitSelection()
												}
											}
										}
									}

									// Recording Overlay - top right of fbo
									Item {
										id: recordingOverlay
										visible: videoRecord || isOnvifRecording
										z: 3
										opacity: 0.9
										width: recRow.width
										height: recRow.height

										anchors.right: fbo ? fbo.right : fboContainer.right
										anchors.top: fbo ? fbo.top : fboContainer.top
										anchors.rightMargin: 10
										anchors.topMargin: 8

										Row {
											id: recRow
											spacing: 6

											Rectangle {
												id: recDot
												width: 12
												height: 12
												radius: 6
												color: "red"
												anchors.verticalCenter: parent.verticalCenter

												SequentialAnimation on opacity {
													loops: Animation.Infinite
													running: videoRecord || isOnvifRecording
													NumberAnimation { to: 0.1; duration: 600 }
													NumberAnimation { to: 1.0; duration: 600 }
												}
											}

											Text {
												id: overlayText
												text: durationTimer ? durationTimer.duration : ""
												color: "white"
												font.pixelSize: 20
												font.bold: true
												anchors.verticalCenter: parent.verticalCenter
											}
										}
									}

									// ─── Crosshair Overlay ───────────────────────────────────────────
									Item {
										id: crosshairOverlay
										anchors.fill: fbo
										visible: isPerpendicularCrossHair || isCircleCrossHair || isDotCrossHair
										z: 2

										// ── Type 1: Perpendicular crosshair (isPerpendicularCrossHair == true) ──────────────────
										Item {
											anchors.fill: parent
											visible: isPerpendicularCrossHair && !isCircleCrossHair && !isDotCrossHair

											// Horizontal line
											Rectangle {
												width: parent.width
												height: 2
												color: crossHairSettingsWindow.crossHairColor
												opacity: 0.85
												anchors.verticalCenter: parent.verticalCenter
											}

											// Vertical line
											Rectangle {
												width: 2
												height: parent.height
												color: crossHairSettingsWindow.crossHairColor
												opacity: 0.85
												anchors.horizontalCenter: parent.horizontalCenter
											}

											// Center dot
											Rectangle {
												width: 6
												height: 6
												radius: 3
												color: crossHairSettingsWindow.crossHairColor
												opacity: 0.9
												anchors.centerIn: parent
											}
										}

										// ── Type 2: Dotted Circle crosshair (isCircleCrossHair) ────────
										Item {
											anchors.fill: parent
											visible: isCircleCrossHair

											Canvas {
												id: circleCanvas
												anchors.fill: parent

												property color currentColor: crossHairSettingsWindow.crossHairColor
												onCurrentColorChanged: requestPaint()

												// Redraw if the item is resized
												onWidthChanged: requestPaint()
												onHeightChanged: requestPaint()

												onPaint: {
													var ctx = getContext("2d");
													ctx.clearRect(0, 0, width, height);

													var cx = width / 2;
													var cy = height / 2;
													var radius = Math.min(width, height) * 0.05; // adjust size as needed

													ctx.beginPath();
													ctx.setLineDash([4, 5]);         // dotted: 4px dash, 5px gap
													ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
													ctx.strokeStyle = crossHairSettingsWindow.crossHairColor;
													ctx.lineWidth = 2.5;
													ctx.globalAlpha = 0.85;
													ctx.stroke();
												}
											}

											// Center "+" for circle crosshair
											Text {
												anchors.centerIn: parent
												text: "+"
												color: crossHairSettingsWindow.crossHairColor
												font.pixelSize: 16
												font.bold: true
												opacity: 0.9
												z: 1
											}
										}

										// ── Type 3: Dot crosshair → "+" symbol (isDotCrossHair) ────────
										Item {
											anchors.fill: parent
											visible: isDotCrossHair && !isCircleCrossHair

											Text {
												anchors.centerIn: parent
												text: "+"
												color: crossHairSettingsWindow.crossHairColor
												font.pixelSize: 24
												font.bold: true
												opacity: 0.9
											}
										}
									}
									// ─────────────────────────────────────────────────────────────────


									// ─── Grid Overlay ─────────────────────────────────────────────────
									Item {
										id: gridOverlay
										anchors.fill: fbo
										visible: isRuleOfThirdsGrid || isCenterGrid || isGoldenRatioGrid || isSquareGrid
										z: 2

										// ── Type 1: Rule of Thirds Grid ───────────────────────────────
										Item {
											anchors.fill: parent
											visible: isRuleOfThirdsGrid && !isCenterGrid && !isGoldenRatioGrid && !isSquareGrid

											// Vertical line 1 (at 1/3)
											Rectangle {
												width: 2
												height: parent.height
												color: gridSettingsWindow.gridColor
												opacity: 0.6
												x: parent.width / 3
											}

											// Vertical line 2 (at 2/3)
											Rectangle {
												width: 2
												height: parent.height
												color: gridSettingsWindow.gridColor
												opacity: 0.6
												x: (parent.width / 3) * 2
											}

											// Horizontal line 1 (at 1/3)
											Rectangle {
												width: parent.width
												height: 2
												color: gridSettingsWindow.gridColor
												opacity: 0.6
												y: parent.height / 3
											}

											// Horizontal line 2 (at 2/3)
											Rectangle {
												width: parent.width
												height: 2
												color: gridSettingsWindow.gridColor
												opacity: 0.6
												y: (parent.height / 3) * 2
											}

											// Optional: highlight the 4 intersection points
											Repeater {
												model: [
													{ ix: 1/3, iy: 1/3 },
													{ ix: 2/3, iy: 1/3 },
													{ ix: 1/3, iy: 2/3 },
													{ ix: 2/3, iy: 2/3 }
												]

												Rectangle {
													width: 6
													height: 6
													radius: 3
													color: gridSettingsWindow.gridColor
													opacity: 0.9
													x: parent.width * modelData.ix - 3 + 1
													y: parent.height * modelData.iy - 3 + 1
												}
											}
										}

										// ── Type 2: Center Grid ────────────────────────────────────────
										Item {
											anchors.fill: parent
											visible: isCenterGrid

											// Vertical center line
											Rectangle {
												width: 2
												height: parent.height
												color: gridSettingsWindow.gridColor
												opacity: 0.6
												anchors.horizontalCenter: parent.horizontalCenter
											}

											// Horizontal center line
											Rectangle {
												width: parent.width
												height: 2
												color: gridSettingsWindow.gridColor
												opacity: 0.6
												anchors.verticalCenter: parent.verticalCenter
											}

											// Center intersection dot
											Rectangle {
												width: 8
												height: 8
												radius: 4
												color: gridSettingsWindow.gridColor
												opacity: 0.9
												anchors.centerIn: parent
											}

											// Diagonal line top-left to bottom-right
											Canvas {
												anchors.fill: parent

												property color currentColor: gridSettingsWindow.gridColor
												onCurrentColorChanged: requestPaint()
												onPaint: {
													var ctx = getContext("2d");
													ctx.clearRect(0, 0, width, height);
													ctx.beginPath();
													ctx.moveTo(0, 0);
													ctx.lineTo(width, height);
													ctx.strokeStyle = gridSettingsWindow.gridColor;
													ctx.lineWidth = 2;
													ctx.globalAlpha = 0.4;
													ctx.setLineDash([6, 4]);
													ctx.stroke();

													// Diagonal line top-right to bottom-left
													ctx.beginPath();
													ctx.moveTo(width, 0);
													ctx.lineTo(0, height);
													ctx.stroke();
												}
											}
										}

										// ── Type 3: Golden Ratio Grid ──────────────────────────────────
										Item {
											anchors.fill: parent
											visible: isGoldenRatioGrid && !isCenterGrid

											Canvas {
												id: goldenRatioCanvas
												anchors.fill: parent

												property color currentColor: gridSettingsWindow.gridColor
												onCurrentColorChanged: requestPaint()

												onWidthChanged:  requestPaint()
												onHeightChanged: requestPaint()

												onPaint: {
													var ctx = getContext("2d");
													ctx.clearRect(0, 0, width, height);

													ctx.strokeStyle = gridSettingsWindow.gridColor;
													ctx.lineWidth = 2;
													ctx.globalAlpha = 0.6;
													ctx.setLineDash([]);

													var phi = 1.6180339887;

													// Vertical golden ratio lines
													var vOffset = width / (1 + phi);       // ~38.2% from left
													var vOffset2 = width - vOffset;        // ~61.8% from left

													// Horizontal golden ratio lines
													var hOffset = height / (1 + phi);      // ~38.2% from top
													var hOffset2 = height - hOffset;       // ~61.8% from top

													// Draw vertical lines
													ctx.beginPath();
													ctx.moveTo(vOffset, 0);
													ctx.lineTo(vOffset, height);
													ctx.stroke();

													ctx.beginPath();
													ctx.moveTo(vOffset2, 0);
													ctx.lineTo(vOffset2, height);
													ctx.stroke();

													// Draw horizontal lines
													ctx.beginPath();
													ctx.moveTo(0, hOffset);
													ctx.lineTo(width, hOffset);
													ctx.stroke();

													ctx.beginPath();
													ctx.moveTo(0, hOffset2);
													ctx.lineTo(width, hOffset2);
													ctx.stroke();

													// Draw golden spiral guide arcs (one in each quadrant corner)
													ctx.globalAlpha = 0.35;
													ctx.setLineDash([3, 4]);
													ctx.lineWidth = 2;

													// Top-left quadrant arc
													ctx.beginPath();
													ctx.arc(vOffset, hOffset, Math.min(vOffset, hOffset), Math.PI, 1.5 * Math.PI);
													ctx.stroke();

													// Top-right quadrant arc
													ctx.beginPath();
													ctx.arc(vOffset2, hOffset, Math.min(width - vOffset2, hOffset), 1.5 * Math.PI, 2 * Math.PI);
													ctx.stroke();

													// Bottom-right quadrant arc
													ctx.beginPath();
													ctx.arc(vOffset2, hOffset2, Math.min(width - vOffset2, height - hOffset2), 0, 0.5 * Math.PI);
													ctx.stroke();

													// Bottom-left quadrant arc
													ctx.beginPath();
													ctx.arc(vOffset, hOffset2, Math.min(vOffset, height - hOffset2), 0.5 * Math.PI, Math.PI);
													ctx.stroke();

													// Intersection dots
													ctx.globalAlpha = 0.9;
													ctx.setLineDash([]);
													ctx.fillStyle =  gridSettingsWindow.gridColor;

													var dots = [
														[vOffset, hOffset],
														[vOffset2, hOffset],
														[vOffset, hOffset2],
														[vOffset2, hOffset2]
													];

													for (var i = 0; i < dots.length; i++) {
														ctx.beginPath();
														ctx.arc(dots[i][0], dots[i][1], 3, 0, 2 * Math.PI);
														ctx.fill();
													}
												}
											}
										}

										// ── Type 4: Square Grid ────────────────────────────────────────
										Item {
											anchors.fill: parent
											visible: isSquareGrid && !isCenterGrid && !isGoldenRatioGrid

											Canvas {
												id: squareGridCanvas
												anchors.fill: parent

												property color currentColor: gridSettingsWindow.gridColor
    											onCurrentColorChanged: requestPaint()

												onWidthChanged: requestPaint()
												onHeightChanged: requestPaint()

												onPaint: {
													var ctx = getContext("2d");
													ctx.clearRect(0, 0, width, height);

													ctx.strokeStyle = gridSettingsWindow.gridColor;
													ctx.lineWidth = 2;
													ctx.globalAlpha = 0.4;
													ctx.setLineDash([]);

													// Use a fixed cell size — adjust to taste
													var cellSize = Math.min(width, height) / 6;

													// Vertical lines
													for (var x = cellSize; x < width; x += cellSize) {
														ctx.beginPath();
														ctx.moveTo(x, 0);
														ctx.lineTo(x, height);
														ctx.stroke();
													}

													// Horizontal lines
													for (var y = cellSize; y < height; y += cellSize) {
														ctx.beginPath();
														ctx.moveTo(0, y);
														ctx.lineTo(width, y);
														ctx.stroke();
													}
												}
											}
										}
									}
									// ──────────────────────────────────────────────────────────────────

									// Add MouseArea for double click
									MouseArea {
										anchors.fill: fbo
										acceptedButtons: Qt.LeftButton | Qt.RightButton
										onDoubleClicked: {
											if ( selectedDevCnt > 1){
												if(!isFboDoubleClicked){
													// Remember which tiles were shown so collapsing restores
													// them as they were. A camera that never delivered a
													// frame has a hidden tile and must stay hidden.
													var shown = []
													for ( var i = 0 ; i< selectedDevCnt ; i++){
														var row = (i < fboModel.count) ? fboModel.get(i) : null
														shown.push(!!(row && row.visible))
														if( i != index){
															setFboRow(i, {
																visible : false
															});
														}
														if ( i == index){
															showFocusedPreview(i)
														}
													}
													visibleBeforeFocus = shown
													focusedFboIndex = index
													isFboDoubleClicked = true
												} else{
													for ( var i = 0 ; i< selectedDevCnt ; i++){
														var cur = (i < fboModel.count) ? fboModel.get(i) : null
														// Shown before the expand, or started streaming meanwhile.
														// Don't force the expanded tile's FBO on: a camera with no
														// frames keeps an empty preview with only its status bar.
														var wasShown = (i < visibleBeforeFocus.length) ? visibleBeforeFocus[i] : true
														setFboRow(i, {
															visible : wasShown || !!(cur && cur.visible)
														});
														if ( i == index){
															setFboRow(i, {
																rectWidth: prevController.getFrameWidth(i, previewInnerRect.width) - 10,
																rectHeight: (selectedDevCnt > 2) ?  prevController.getFrameHeight(i, previewInnerRect.height - 70) - 10 :  prevController.getFrameHeight(i, previewInnerRect.height - 40) - 10,
																rectX: prevController.getFrameX(i, previewInnerRect.width) + 5,
															rectY: previewFrameY(i, previewInnerRect.height)
															});
															let item = fboModel.get(i);
															prevController.setViewPort( i, item.rectWidth, item.rectHeight)
														}
													}
													isFboDoubleClicked = false
													focusedFboIndex = -1
												}
											}
										}
										onReleased : {
											if(mouse.button == Qt.RightButton){
												// passing mouse x,y co-ordinates, preview width and height
												mouseRightClicked(mouse.x, mouse.y, fbo.width, fbo.height)
												fboContextMenu.x = mouse.x
												fboContextMenu.y = mouse.y
												fboContextMenu.open()
											}
										}

										QQC.Menu {
											id: fboContextMenu
											width: 160
											padding: 4

											background: Rectangle {
											color: "#0e1b28"
											border.color: "#263949"
												border.width: 1
												radius: 4
											}

											QQC.MenuItem {
												id: showHistogramMenuItem
												width: fboContextMenu.width - 8
												height: menuItemHeight
												text: "Show histogram"
												onTriggered: prevController.showHistogramWindow(index)

												background: Rectangle {
												color: showHistogramMenuItem.hovered ? "#0b5fae" : "#0e1b28"
													radius: 3

													Behavior on color { ColorAnimation { duration: 100 } }
												}

												contentItem: Text {
													text: showHistogramMenuItem.text
													font.pixelSize: menuFontSize + 1
													color: "white"
													verticalAlignment: Text.AlignVCenter
													leftPadding: 10
												}
											}
										}
									}
									 Rectangle {
										id: statusBar
										width : fbo ? fbo.width : 0
										x: fbo ? fbo.x : 0
						height: activePreviewStatusBarHeight
						visible: window.fitToWindow
						color: "#0e1b28"
						border.color: "#263949"
						border.width: 1
										anchors.top: fbo ? fbo.bottom : undefined

										Text {
											anchors.centerIn: parent
											// Single camera, or one tile expanded by double-click:
											// labelled form. Several tiles side by side: compact form.
											text: (selectedDevCnt <= 1 || isFboDoubleClicked)
												? "Format: " + (model.format || "--") + " | Resolution: " + (model.resolution || "--") + " | FPS: " + (model.fps || "--")
												: (model.format || "--") + " | " + (model.resolution || "--") + " | " + (model.fps || "--")

											color: "white"
											font.pixelSize: 12
										}
									}
								}
							}
						}
					}

					MouseArea {
						id: cursorZoomWheelArea
						// This remains a Flickable content child so it participates in
						// the existing input path. Do not anchor it to contentItem:
						// contentItem is 0x0 at 100% and below.
						x: fboFlickable.contentX
						y: fboFlickable.contentY
						width: fboFlickable.width
						height: fboFlickable.height
						z: 90
						acceptedButtons: Qt.NoButton
						hoverEnabled: true
						visible: activeHistogramMode === 0
						enabled: activeHistogramMode === 0 && zoomIndex >= 0 && isCameraOpened
						cursorShape: zoom > 100
								? ((fboFlickable.moving || fboFlickable.movingHorizontally || fboFlickable.movingVertically)
									? Qt.ClosedHandCursor : Qt.OpenHandCursor)
								: Qt.ArrowCursor
						onWheel: {
							if (activeHistogramMode !== 0 || zoomIndex < 0 || !isCameraOpened || !zoomAllowed) {
								wheel.accepted = false
								return
							}
							var wheelDelta = wheel.angleDelta.y !== 0
									? wheel.angleDelta.y : wheel.pixelDelta.y
							if (wheelDelta !== 0) {
								zoomPreviewAt(wheel.x, wheel.y, wheelDelta)
								wheel.accepted = true
							}
						}
					}

					//  Vertical scrollbar
					ScrollBar.vertical: ScrollBar {
						id: customVScrollBar
						width: 12
						z: 100
						active: false
						visible: zoomScrollbarsEnabled && fboFlickable.contentHeight > fboFlickable.height
						anchors.top: parent.top
						anchors.bottom: parent.bottom
						anchors.right: parent.right

						contentItem: Rectangle {
							implicitWidth: 8
							implicitHeight: 15
							radius: 4
							color: (customVScrollBar.active || customVScrollBar.hovered)
								   ? "#0b5fae" : "#45a7ff"
						}

						background: Rectangle {
							color: "#07111d"
							border.color: "#263949"
							border.width: 1
							radius: 4
							width: 12
						}
					}

					//  Horizontal scrollbar
					ScrollBar.horizontal: ScrollBar {
						id: customHScrollBar
						parent: previewInnerRect
						height: 12
						z: 100
						policy: ScrollBar.AlwaysOn
						active: visible
						visible: zoomScrollbarsEnabled && fboFlickable.contentWidth > fboFlickable.width
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 0
						anchors.left: parent.left
						anchors.right: parent.right

						contentItem: Rectangle {
							implicitWidth: 15
							implicitHeight: 8
							radius: 4
							color: (customHScrollBar.active || customHScrollBar.hovered)
								   ? "#0b5fae" : "#45a7ff"
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
					 
			Connections {
                target: prevController
                onFboCreated: {	
					 var value = prevController.getFrameCount();

                            // Dynamically add new items to the model based on new frames
                            for (let i = 0; i < value; ++i) {
                                // Example values, replace with actual frame data
                                let newItem = {
                                    objectName: "framebufobj_" + i ,
                                    rectWidth: prevController.getFrameWidth(i, previewInnerRect.width) - 10,
                                    rectHeight: (selectedDevCnt > 2) ?  prevController.getFrameHeight(i, previewInnerRect.height - 70) - 10 :  prevController.getFrameHeight(i, previewInnerRect.height - 40) - 10,
                                    rectX: prevController.getFrameX(i, previewInnerRect.width) + 5,
									rectY: previewFrameY(i, previewInnerRect.height),
									visible : false,
									fboX: 0,
									fboY: 0,
									fboWidth: 0,
									fboHeight: 0,
									format : "--",
									resolution : "--",
									zoomFactor: 1.0,
									histogramMode: 0,
									histX: 0,
									histY: 0,
									histWidth: 0,
									histHeight: 0,
									histColor: "#20b7ff",
									cameraName: "",
									fps : "--"
                                };
                                // Append new item to the model
                                fboModel.append(newItem);
                            }

                            fboLoader.sourceComponent = fboComponent;
                            fboInstantiated = true;
							isFboLoaded = true
                }

				onHistogramSelectionModeChanged: {
					if (cameraIndex < 0 || cameraIndex >= fboModel.count)
						return

					var item = fboModel.get(cameraIndex)
					var previewW = item.fboWidth > 0 ? item.fboWidth : item.rectWidth
					var previewH = item.fboHeight > 0 ? item.fboHeight : item.rectHeight
					var lineThickness = 1
					var x = 0
					var y = 0
					var w = previewW
					var h = previewH

					if (mode === 1) {
						w = Math.max(40, Math.round(previewW * 0.35))
						h = Math.max(40, Math.round(previewH * 0.35))
						x = Math.round((previewW - w) / 2)
						y = Math.round((previewH - h) / 2)
					} else if (mode === 2) {
						w = lineThickness
						h = previewH
						x = Math.round((previewW - w) / 2)
					} else if (mode === 3) {
						w = previewW
						h = lineThickness
						y = Math.round((previewH - h) / 2)
					}

					fboModel.setProperty(cameraIndex, "histogramMode", mode)
					fboModel.setProperty(cameraIndex, "histX", x)
					fboModel.setProperty(cameraIndex, "histY", y)
					fboModel.setProperty(cameraIndex, "histWidth", w)
					fboModel.setProperty(cameraIndex, "histHeight", h)
					window.activeHistogramMode = mode

					prevController.setHistogramSelection(cameraIndex, mode, x, y, w, h, previewW, previewH)
				}

				onHistogramSelectionColorChanged: {
					if (cameraIndex < 0 || cameraIndex >= fboModel.count)
						return

					fboModel.setProperty(cameraIndex, "histColor", color)
				}

				// Rescales a camera's stored histogram selection from its old FBO/rect size to
				// the new preview size (clamped per mode: ROI, vertical or horizontal line),
				// saves it in fboModel and sends it to prevController.setHistogramSelection().
				function syncHistogramSelectionToPreview(cameraIndex, previewW, previewH) {
					if (cameraIndex < 0 || cameraIndex >= fboModel.count || previewW <= 0 || previewH <= 0)
						return

					var item = fboModel.get(cameraIndex)
					var mode = item.histogramMode ? item.histogramMode : 0
					if (mode <= 0)
						return

					var oldW = item.fboWidth > 0 ? item.fboWidth : item.rectWidth
					var oldH = item.fboHeight > 0 ? item.fboHeight : item.rectHeight
					if (oldW <= 0) oldW = previewW
					if (oldH <= 0) oldH = previewH

					var x = Math.round((item.histX ? item.histX : 0) * previewW / oldW)
					var y = Math.round((item.histY ? item.histY : 0) * previewH / oldH)
					var w = item.histWidth ? Math.round(item.histWidth * previewW / oldW) : previewW
					var h = item.histHeight ? Math.round(item.histHeight * previewH / oldH) : previewH

					if (mode === 1) {
						w = Math.max(1, Math.min(w, previewW))
						h = Math.max(1, Math.min(h, previewH))
						x = Math.max(0, Math.min(x, previewW - w))
						y = Math.max(0, Math.min(y, previewH - h))
					} else if (mode === 2) {
						w = 1
						h = previewH
						x = Math.max(0, Math.min(x, previewW - w))
						y = 0
					} else if (mode === 3) {
						w = previewW
						h = 1
						x = 0
						y = Math.max(0, Math.min(y, previewH - h))
					}

					fboModel.setProperty(cameraIndex, "histX", x)
					fboModel.setProperty(cameraIndex, "histY", y)
					fboModel.setProperty(cameraIndex, "histWidth", w)
					fboModel.setProperty(cameraIndex, "histHeight", h)
					prevController.setHistogramSelection(cameraIndex, mode, x, y, w, h, previewW, previewH)
				}
							
				onCameraClosed: {	
					zoom = 100  	
					fboModel.clear();
                    fboInstantiated = false;
                    fboLoader.sourceComponent = null;
					fitToWindow = true
					closeRightUp = false
					isCameraOpened = false
					window.activeHistogramMode = 0
				}

				onViewPortChanged: {
					syncHistogramSelectionToPreview(index, viewW, viewH)
					if(isCameraOpened){
						setFboRow(index, {
							fboWidth: viewW,
							fboHeight: viewH,
							fboX: x,
							fboY: y,
							visible : true
						});
					} else{
						setFboRow(index, {
							fboWidth: viewW,
							fboHeight: viewH,
							fboX: x,
							fboY: y,
							visible : false
						});
					}
				}

				onBeforeSetCurrentImageProperty: {
					if (zoom !== 100) {
						zoom = 100
						applyZoomToPreview()
					}
					if(!fitToWindow){
						fitToWindow = true
						fboFlickable.contentHeight = 0
						fboFlickable.contentWidth = 0
					}
					if (index >= 0 && index < fboModel.count) {
						setFboRow(index, {
							visible: false
						});
					}
				}

				onSetImagePropertyFailed: {
					
					// Hide only the specific FBO that failed
					if (index >= 0 && index < fboModel.count) {
						setFboRow(index, {
							visible: false
						});
					}
				}

				onRecordingStateChanged: {
					window.startVideoRecording(recState)
					videoRecordingStarted = recState;
				}

				onSetImagePropertySuccess: {	
					if(zoom != 100){
						zoom = 100
					}				
					// Show the specific FBO that succeeded
					if (index >= 0 && index < fboModel.count) {
						setFboRow(index, {
							visible: true
						});
					}
				}

				onCameraOpened: {	
					isCameraOpened = true
					window.fitToWindow = true
					fpsTimer.start()
					prevController.getStreamFormat(index)  
					for (let i = 0; i < fboModel.count; ++i) {
						if(i == index){
							let item = fboModel.get(i);
							setFboRow(i, {
								rectWidth: prevController.getFrameWidth(i, previewInnerRect.width) - 10,
								rectHeight: ( selectedDevCnt > 2 ) ? prevController.getFrameHeight(i, previewInnerRect.height - 70) - 10 : prevController.getFrameHeight(i, previewInnerRect.height - 40) - 10,
								rectX: prevController.getFrameX(i, previewInnerRect.width) + 5,
								rectY: previewFrameY(i, previewInnerRect.height),
								cameraName: prevController.cameraName(index)
							});
							prevController.setViewPort(index,item.rectWidth, item.rectHeight)
							focusRestoreTimer.start()
						}
					}
				}

				onFormatChanged: {
					setFboRow(index, {
						format: format
					});
					
					let item = fboModel.get(index);
				}

				onResolutionChanged: {
					setFboRow(index, {
						resolution: resolution
					});
					if(resolution){
						var parts = resolution.split("x")
						contentH = parts[1]
						contentW = parts[0]
					}
				}

				onFpsChanged: {
					setFboRow(index, {
						fps: fpsVal
					});
				}

				onStillCaptured: {
					var count = multiCameraCapture ? selectedDevCnt : 1
					for (var i = 0; i < count; i++)
						prevController.resumeVideoStream(i);
				}

				onUsbDeviceAdded: {
					let newItem = {
						objectName: "framebufobj_" + index,
						rectWidth: 0,
						rectHeight: 0,
						rectX: 0,
						rectY: 0,
						visible: false,
						fboX: 0,
						fboY: 0,
						fboWidth: 0,
						fboHeight: 0,
						format: "--",
						resolution: "--",
						zoomFactor: 1.0,
						histogramMode: 0,
						histX: 0,
						histY: 0,
						histWidth: 0,
						histHeight: 0,
						histColor: "#20b7ff",
						cameraName: "",
						fps: "--"
					};
					// Only appends one new row/delegate â€” the already-streaming
					// camera's fboModel row and FrameBufferObject item are left
					// untouched (no clear(), no Loader.sourceComponent change).
					fboModel.append(newItem);

					// fboLoader.sourceComponent already points at fboComponent
					// (set by the first device's cold-open path), so no Loader
					// status change happens here and fboLoaded() won't auto-fire â€”
					// resync fbos[] with the scene explicitly.
					prevController.updateFramebufferObject();

					reflowFboLayout(index + 1);
				}

				onUsbDeviceRemoved: {
					// Removes exactly one delegate; the Repeater leaves every
					// other FrameBufferObject item (and its GL resources) alone.
					fboModel.remove(removedIndex);

					if (newCount <= 0) {
						// Defensive fallback â€” the checkbox-toggle path in
						// Devices.qml always routes "close the last device" through
						// setSelectedDeviceCount/onCameraClosed instead, so this
						// should not normally be reached.
						zoom = 100
						fboInstantiated = false
						fboLoader.sourceComponent = null
						fitToWindow = true
						closeRightUp = false
						isCameraOpened = false
						return
					}

					prevController.updateFramebufferObject();
					reflowFboLayout(newCount);
				}
			}

			Connections {
				target : densicamController

				onActionPerformed: {
					if(action == "ImageCapture") {
						 prevController.setCaptureFlag(0)
					} else if (action == "VideoRecord") {
						if(window.videoRecord){
							window.videoRecord = false	
							logController.displayMessage(verboseLogPriority, "UI: Stop Recording button clicked.\n ");
							if(prevController.stopRecording() == 1){		
								window.stopVideoRecording()
								videoRecordingStarted = false;
								restoreRightContainerAfterRecording()
							} else{
								logController.displayMessage(verboseLogPriority, "UI: Stop Recording action failed.\n ");
								window.videoRecord = true
							}
						}else{
							durationTimer.stop()
							window.videoRecord = true
							logController.displayMessage(verboseLogPriority, "UI: Start Recording button clicked.\n ");
							if(prevController.startVideoRecording() == 1){	
								videoRecordingStarted = true		
								hideRightContainerForRecording()
							} else{
								logController.displayMessage(verboseLogPriority, "UI: Start Recording action failed.\n ");
								window.startVideoRecording(false)
								window.videoRecord = false
							}
						}
					}
				}
			}
        }//Second Rectangle
    } //Main Container

    Rectangle {
        id: middleIntersection
        width: container.width
		color: "#172837"
		border.color: "#36536b"
		border.width: 1
		z: 50
        height: 5
		y: descriptionOuterRect.y - height / 2
        anchors.right: rightContainer.left
		anchors.left: leftContainer.right

        MouseArea {
            id: middledragArea
            anchors.fill: parent
            cursorShape: Qt.SplitVCursor
			hoverEnabled : true

            property real initialY: 0
			property bool isPressed: false

            onPressed: {
				isPressed = true
                middledragArea.initialY = mouse.y;
            }
			onReleased:{
				isPressed = false
				middleIntersection.color = "#172837"
				setFitToWindow();
			}
			// Hover state tracking
			onEntered: {
				middleIntersection.color = accentColor
			}
			onExited: {
				if (!isPressed) {
					middleIntersection.color = "#172837"
				}
			}
            onPositionChanged: {
				if(isPressed){
					middleIntersection.color = accentColor
					const deltaY = mouse.y - middledragArea.initialY;
	                // Calculate new heights
		            const newHeight1 = renderingRect.height + deltaY / 2;
			        const newHeight2 = descriptionOuterRect.height - deltaY / 2;
				    // Ensure no overlap
					if (newHeight1 >= (window.height*0.55) && newHeight2 >= 100)
					{	
						descriptionOuterRect.height = newHeight2;
						middle_con_down.height = newHeight2;
					}
				}
            }
        }
    }

    Rectangle {
        id: descriptionOuterRect
        width: container.width
        height: container.height * 0.30
        anchors.left: leftContainer.right
        anchors.bottom: importStatusBar.top
        y:200
        color: panelBackground
		border.color: panelBorder
		border.width: 1
    }

	//left up con and left right con
	Rectangle
	{
		id:middle_con_down
		width:descriptionOuterRect.width
		height: descriptionOuterRect.height
		x:descriptionOuterRect.x
		y:descriptionOuterRect.y
		Loader {
            id: pageLoaderDownM
			source:middleDownFile
            anchors.fill:parent
        }
	 }

	//left up con and left right con
	Rectangle
	 {
		id:left_con_up
		anchors.fill: leftContainer
		//Loaders source automatically inherit the parent 
		Loader {
            id: pageLoaderUPL
			source:leftUpFile
            anchors.fill:parent
        }
	 }
	  
	  //Left-Side Intersection
      Rectangle {
		
		id: intersectionHorizontal
        width: 5
		color: "#172837"
		border.color: "#36536b"
		border.width: 1
		z: 50
        height: container.height
		visible : left_con_up.visible
		x: container.x - width / 2
		y: container.y

        MouseArea {
	        id: dragAreaHorizontal
			anchors.fill: parent
            cursorShape: Qt.SplitHCursor
			hoverEnabled: true

            property real initialX: 0
			property bool isPressed: false

            onPressed: {
				isPressed = true
				dragAreaHorizontal.initialX = mouse.x;
            }
			onReleased :{
				isPressed = false
				intersectionHorizontal.color = "#172837"
				setFitToWindow();
			}
				
			// Hover state tracking
			onEntered: {
				intersectionHorizontal.color = accentColor
			}
			onExited: {
				if (!isPressed) {
					intersectionHorizontal.color = "#172837"
				}
			}

            onPositionChanged: {	
				if(isPressed){
					intersectionHorizontal.color = accentColor
					const deltaX = mouse.x - dragAreaHorizontal.initialX;

					// Calculate new width
					const newWidth1 = leftContainer.width + deltaX / 2;
					const newWidth2 = container.width - deltaX / 2;

					// Ensure no overlap
					if (newWidth1 >= 200 && newWidth1 < (window.width*1/5) && newWidth2 >= 200)
					{
						leftContainer.width = newWidth1;
						left_con_up.width = newWidth1;
						container.width = newWidth2;
						renderingRect.width = container.width
						previewInnerRect.width = renderingRect.width 
						middleIntersection.width = newWidth2;
						middle_con_down.width = container.width
					}
				}  
             }
         }
    }  


    //Right Container
	Rectangle {
		id: rightContainer
		width: deviceType > 0 ? window.width * 0.22 : 0
		anchors.right: parent.right
		anchors.top: menuBar.bottom
		anchors.bottom: importStatusBar.top
		color: panelBackground
		border.color: panelBorder
		border.width: 1
	}

	Rectangle {
		id: right_con_up
		anchors.fill: rightContainer   
		visible: deviceType > 0
		Loader {
            id: pageLoaderUP
            objectName: "pageLoaderUP"
            width:  rightContainer.width
			source: rightUpFile
            anchors.fill:parent
        }
	}
	
	//intersection of right container with container
	Rectangle {
        id: intersectionHorizontalRight
        width: 5
		color: "#172837"
		border.color: "#36536b"
		border.width: 1
		z: 50
		x: rightContainer.x - width / 2
		y: rightContainer.y
		height: rightContainer.height

        MouseArea {
            id: dragAreaHorizontalRight
            anchors.fill: parent
            cursorShape: Qt.SplitHCursor
			hoverEnabled : true

            property real initialX: 0
			property bool isPressed: false

            onPressed: {
				isPressed = true
                dragAreaHorizontalRight.initialX = mouse.x;
            }
			onReleased: {
				isPressed = false
				intersectionHorizontalRight.color = "#172837"
				setFitToWindow();
			}
			// Hover state tracking
			onEntered: {
				intersectionHorizontalRight.color = accentColor
			}
			onExited: {
				if (!isPressed) {
					intersectionHorizontalRight.color = "#172837"
				}
			}
            onPositionChanged: {
				if(isPressed){
					intersectionHorizontalRight.color = accentColor
	                const deltaX = dragAreaHorizontalRight.initialX - mouse.x;

		            // Calculate new width
			        const newWidth1 = rightContainer.width + deltaX / 2;
				    const newWidth2 = container.width - deltaX / 2;

					// Ensure no overlap
					if (newWidth1 >= 200 && newWidth1 < (window.width* 1.7 /5) && newWidth2 >= 200)
					{
						rightContainer.width = newWidth1;
						container.width = newWidth2;
						renderingRect.width = container.width
						previewInnerRect.width = renderingRect.width 
						middle_con_down.width = newWidth2;
					}
				}
            }
        }
    }//ends

	CustomTitleBar {
		id: customTitleBar
		width: window.width
		height: titleBarHeight
		anchors.top: window.top
		targetWindow: window
	}

	FramelessResizeArea { targetWindow: window; edges: Qt.LeftEdge; width: 5; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; cursorShape: Qt.SizeHorCursor }
	FramelessResizeArea { targetWindow: window; edges: Qt.RightEdge; width: 5; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; cursorShape: Qt.SizeHorCursor }
	FramelessResizeArea { targetWindow: window; edges: Qt.TopEdge; height: 5; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; cursorShape: Qt.SizeVerCursor }
	FramelessResizeArea { targetWindow: window; edges: Qt.BottomEdge; height: 5; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; cursorShape: Qt.SizeVerCursor }
	FramelessResizeArea { targetWindow: window; edges: Qt.LeftEdge | Qt.TopEdge; width: 8; height: 8; anchors.left: parent.left; anchors.top: parent.top; cursorShape: Qt.SizeFDiagCursor }
	FramelessResizeArea { targetWindow: window; edges: Qt.RightEdge | Qt.TopEdge; width: 8; height: 8; anchors.right: parent.right; anchors.top: parent.top; cursorShape: Qt.SizeBDiagCursor }
	FramelessResizeArea { targetWindow: window; edges: Qt.LeftEdge | Qt.BottomEdge; width: 8; height: 8; anchors.left: parent.left; anchors.bottom: parent.bottom; cursorShape: Qt.SizeBDiagCursor }
	FramelessResizeArea { targetWindow: window; edges: Qt.RightEdge | Qt.BottomEdge; width: 8; height: 8; anchors.right: parent.right; anchors.bottom: parent.bottom; cursorShape: Qt.SizeFDiagCursor }

    // Custom Menu Bar
    Rectangle {
        id:menuBar
        width: window.width
        height: menuBarHeight
        color: "#0f0e0e"
		anchors.top: customTitleBar.bottom
		 Loader {
            id: pageLoaderMenu
			source:"MenuBar.qml"
            anchors.fill:parent
        }
    }

    SideBar{
        id: sideBar
    }

    // Native settings/About windows do not get Dialog's modal dimmer automatically,
    // so dim the main window manually while any of them is open.
    Rectangle {
        id: settingsWindowDimmer
        anchors.fill: parent
        z: 10000
        color: "#80000000"
        visible: stillCaptureWindow.visible || filePathWindow.visible
                 || vidRecWindow.visible || manualIPConnWin.visible
                 || crossHairSettingsWindow.visible || gridSettingsWindow.visible
                 || audioRecWindow.visible || zoomWindow.visible
                 || aboutDialog.visible

        MouseArea {
            anchors.fill: parent
        }
    }

	About{
		id: aboutDialog 
	}

	ValidationDialog{
		id: validationDialog
	}
	
    StatusBar{
        id:importStatusBar
    }
	
	AddDeviceDialog{
		id : ethernetContextDialog
	} 

	StillCaptureDialog{
        	id: stillCaptureWindow
	}

	ImageFolderDialog{
		id: folderDialog
	}

	JSONFileDialog{
		id: fileDialog
		objectName: "fileDialog"
	}

	FilePathDialog{
		id: filePathWindow
	}

	VideoRecFolderDialog{
		id: vidRecFolderDialog
	}

	VideoRecordDialog{
		id: vidRecWindow
	}

	ManualIPConnection {
		id: manualIPConnWin
	}

	DurationTimer {
		id: durationTimer
	}

	WifiContextDialog {
		id : wifiContextDialog
	}

	CrossHairSettingsWindow {
		id : crossHairSettingsWindow
	}

	GridSettingsWindow {
		id : gridSettingsWindow
	}

	AudioRecWindow {
		id : audioRecWindow
	}

	ZoomWindow {
		id : zoomWindow
	}

    // Shows or hides the left Devices panel and resizes the preview container
    // (78.5% or 60% of the window) and the log/description panel to match, then
    // re-lays out the preview via setFitToWindow().
	// functions to operate the operating check box open and close
	//check box closes based on whats on left con ,up or down 
    function handleCheckedChanged(closeLeftUpValue) {
		if(!closeLeftUpValue){
			leftContainer.width = 0
			left_con_up.visible = false
		}else{
			leftContainer.width = devicesPanelWidth
			left_con_up.width=leftContainer.width
			left_con_up.y=leftContainer.y
			left_con_up.height=leftContainer.height
			left_con_up.visible = true
		}
		if(!closeLeftUp){
			container.width = window.width * 0.785
			renderingRect.width = container.width
			previewInnerRect.width = renderingRect.width 
		} else{
			container.width = window.width * 0.60
			renderingRect.width = container.width
			previewInnerRect.width = renderingRect.width 
		}
		if(!closeMiddleDown){
			descriptionOuterRect.width = container.width
			middle_con_down.width = container.width
			middleIntersection.width = container.width
		}
		setFitToWindow();								
	}
	
	// Hides the right settings panel while recording, remembering whether it was
	// open so restoreRightContainerAfterRecording() can reopen it.
	function hideRightContainerForRecording()
	{
		reopenRightContainerAfterRecording = !closeRightUp
		if (!closeRightUp) {
			handleCheckChangedUpRight(true)
			closeRightUp = true
		}
	}

	// Reopens the right settings panel after recording if it was open before
	// hideRightContainerForRecording(), and clears the remembered flag.
	function restoreRightContainerAfterRecording()
	{
		if (reopenRightContainerAfterRecording && closeRightUp) {
			handleCheckChangedUpRight(false)
			closeRightUp = false
		}
		reopenRightContainerAfterRecording = false
	}

	// Shows (closeRightUpValue false) or hides the right settings panel, resizes the
	// preview container and log/description panel to match, then re-lays out the
	// preview via setFitToWindow().
	function handleCheckChangedUpRight(closeRightUpValue)
	{
	    rightContainer.width=width_container
        right_con_up.height=rightContainer.height
		right_con_up.y=rightContainer.y
		if(!closeRightUpValue)
		{   
			right_con_up.visible = true
			right_con_up.height=wifiCntlh
		}
		else
		{  
			rightContainer.width=0
			right_con_up.visible = false
		}
		if(!closeRightUp){
			container.width = window.width * 0.785
			renderingRect.width = container.width
			previewInnerRect.width = renderingRect.width 
		} else{
			container.width = window.width*0.60
			renderingRect.width = container.width
			previewInnerRect.width = renderingRect.width 
		}
		if(!closeMiddleDown){
			descriptionOuterRect.width = container.width
			middle_con_down.width = container.width
			middleIntersection.width = container.width
		}
		setFitToWindow();
	}	

	// Shows msg in the validation (error) dialog and opens it.
	function setTextMessage(msg){
		validationDialog.sendTextMessage(msg)
		validationDialog.open(); // This will show the dialog
		return; // Prevent further processing if needed
	}
	 
	// Shows (30% of the container height) or hides the bottom log/description
	// panel, then re-lays out the preview via setFitToWindow().
	function handleLogCheckedChanged(closeMiddleDownValue)
	{

		if(closeMiddleDownValue)
		{					
			middleIntersection.visible = true		
			middleIntersection.width = container.width
			middle_con_down.width = container.width
			descriptionOuterRect.visible = true
			descriptionOuterRect.height = container.height * 0.30
			middle_con_down.height = container.height * 0.30
        }
		else
		{	
			middleIntersection.visible = false
			middleIntersection.width = 0
			descriptionOuterRect.visible = false		
			descriptionOuterRect.height = 0
		}
		setFitToWindow();
	}
	 
	// Switches the active device type: loads the matching right-panel container
	// (Wi-Fi, Routecam/Ethernet or USB) and opens the panel, or hides the panel for
	// any other value (e.g. -1). No-op if the type is unchanged.
	function setDeviceType(devType){
		if(deviceType != devType){
			    deviceType = devType
			    if(devType == wifiDev){
				    rightUpFile = "WifiContainer.qml"
				    handleCheckChangedUpRight(false)    
			    } else if(devType == ethernetDev){
				    rightUpFile = "RoutecamContainer.qml"
				    handleCheckChangedUpRight(false)  
				}else if(devType == usbDev){
					rightUpFile = "UsbcamContainer.qml"
				    handleCheckChangedUpRight(false)  
				}else {
				    handleCheckChangedUpRight(true)
		    }
		}
	}

	// Recomputes each preview FBO rectangle and viewport. With zoom active (single
	// camera) it defers to applyZoomToPreview(); with fit-to-window off (single
	// camera) it scrolls or centres the native-size frame; otherwise it fits all
	// selected cameras into the preview area.
	// Still capture on camera 0, or on every open camera when supported.
	function captureStillImage(){
		if (multiCameraCapture && selectedDevCnt > 1)
			prevController.captureAllCameras()
		else
			prevController.setCaptureFlag(0)
	}

	// Updates an existing preview row. ListModel.set() appends when index == count,
	// so a layout pass or signal that runs before the row is created would add an
	// unnamed tile; the controller then counts it as a camera and the grid switches
	// to the two-row, half-height layout.
	function setFboRow(index, values) {
		if (index < 0 || index >= fboModel.count)
			return
		fboModel.set(index, values)
	}
	function setFitToWindow(){
		if (zoomIndex >= 0 && (zoom !== 100 || selectedDevCnt > 1) && isCameraOpened) {
			applyZoomToPreview()
			return
		}
		if(!fitToWindow && selectedDevCnt == 1){
			if(renderingRect.height <= contentH || renderingRect.width <= contentW){
				// content larger than viewport — scroll mode
				for (var i = 0; i < Math.min(selectedDevCnt, fboModel.count); i++){
					fboFlickable.contentWidth = contentW
					fboFlickable.contentHeight = contentH
					setFboRow(i, {
						rectWidth: prevController.getFrameWidth(i, fboFlickable.contentWidth) - 10,
						rectHeight: prevController.getFrameHeight(i, fboFlickable.contentHeight) - 10,
						rectX: prevController.getFrameX(i, fboFlickable.contentWidth) + 5,
						rectY: prevController.getFrameY(i, fboFlickable.contentHeight)
					});
					let item = fboModel.get(i);
					prevController.setViewPort(i, item.rectWidth, item.rectHeight)
				}
			} else {
				// render area larger than content in one/both axes — center the container
				for (var i = 0; i < Math.min(selectedDevCnt, fboModel.count); i++){
					let frameW = contentW
					let frameH = contentH
					// Center the fboContainer inside renderingRect
					let centeredX = (renderingRect.width - frameW) / 2
					let centeredY = (previewInnerRect.height - frameH - activePreviewStatusBarHeight) / 2
					fboFlickable.contentWidth = 0
					fboFlickable.contentHeight = 0
					setFboRow(i, {
						rectWidth: frameW,
						rectHeight: frameH,
						rectX: centeredX,
						rectY: Math.max(0, centeredY)
					});
					prevController.setViewPort(i, frameW, frameH)
				}
			}
		} else {
			// fitToWindow path — unchanged
			fitToWindow = true
			fboFlickable.contentWidth = 0
			fboFlickable.contentHeight = 0
			for (var i = 0; i < Math.min(selectedDevCnt, fboModel.count); i++){
				setFboRow(i, {
					rectWidth: prevController.getFrameWidth(i, previewInnerRect.width) - 10,
					rectHeight: (selectedDevCnt > 2) ? prevController.getFrameHeight(i, previewInnerRect.height - 70) - 10
													: prevController.getFrameHeight(i, previewInnerRect.height - 40) - 10,
					rectX: prevController.getFrameX(i, previewInnerRect.width) + 5,
					rectY: previewFrameY(i, previewInnerRect.height)
				});
				let item = fboModel.get(i);
				if(item.rectWidth && item.rectHeight){
					prevController.setViewPort(i, item.rectWidth, item.rectHeight)
				}
			}
		}
	}

	// Recomputes rect/viewport geometry for every currently-selected USB
	// preview slot after a single device was incrementally added/removed.
	// Reuses the same getFrameWidth/Height/X/Y + setViewPort calls as
	// setFitToWindow()” this only repositions each surviving FBO's on-screen
	// boundary via onViewPortChanged; it never recreates or destroys any FBO.
	function reflowFboLayout(count){
		fitToWindow = true
		fboFlickable.contentWidth = 0
		fboFlickable.contentHeight = 0
		for (var i = 0; i < Math.min(count, fboModel.count); i++){
			setFboRow(i, {
				rectWidth: prevController.getFrameWidth(i, previewInnerRect.width) - 10,
				rectHeight: (count > 2) ? prevController.getFrameHeight(i, previewInnerRect.height - 70) - 10
											: prevController.getFrameHeight(i, previewInnerRect.height - 40) - 10,
				rectX: prevController.getFrameX(i, previewInnerRect.width) + 5,
				rectY: previewFrameY(i, previewInnerRect.height)
			});
			let item = fboModel.get(i);
			if(item.rectWidth && item.rectHeight){
				prevController.setViewPort(i, item.rectWidth, item.rectHeight)
			}
		}
	}
	// Returns the Y offset for a preview frame: the controller's value for
	// multi-camera layouts, or a vertically centred value (above the status bar)
	// for a single camera.
	function previewFrameY(index, availableHeight) {
		if (selectedDevCnt !== 1)
			return prevController.getFrameY(index, availableHeight)

		var frameHeight = prevController.getFrameHeight(index, availableHeight - 40) - 10
		return Math.max(0, Math.round((availableHeight - frameHeight - activePreviewStatusBarHeight) / 2))
	}
	// Shows tile @p i alone over the whole preview area (multi-camera double-click).
	function showFocusedPreview(i) {
		fboFlickable.contentWidth = 0
		fboFlickable.contentHeight = 0
		setFboRow(i, {
			rectWidth : previewInnerRect.width,
			rectHeight : previewInnerRect.height,
			rectX : 0,
			rectY : 0
		});
		prevController.setViewPort( i, previewInnerRect.width, previewInnerRect.height - 50)
	}
	// Applies the current zoom (%) to the single-camera preview: 100 = fitted
	// frame, >100 = enlarged, scrollable frame at (0,0), <100 = shrunk and centred.
	// Non-100 levels are passed to prevController.applyZoom().
	function applyZoomToPreview() {
	    var zi = zoomIndex
	    if (zi < 0 || !isCameraOpened) return

	    var zoomScale = zoom / 100.0
	    var baseW = prevController.getFrameWidth(0, previewInnerRect.width) - 10
	    var baseH = (selectedDevCnt > 2)
		? prevController.getFrameHeight(0, previewInnerRect.height - 70) - 10
		: prevController.getFrameHeight(0, previewInnerRect.height - 40) - 10

	    var scaledW = Math.round(baseW * zoomScale)
	    var scaledH = Math.round(baseH * zoomScale)

	    if (selectedDevCnt !== 1) {
		// A double-clicked tile fills the preview area; zoom scales from that
		baseW = Math.max(1, Math.floor(previewInnerRect.width))
		baseH = Math.max(1, Math.floor(previewInnerRect.height) - 50)
		scaledW = Math.round(baseW * zoomScale)
		scaledH = Math.round(baseH * zoomScale)
	    }

	    if (zoom === 100 && selectedDevCnt !== 1) {
		showFocusedPreview(zi)

	    } else if (zoom === 100) {
		fboFlickable.contentWidth  = 0
		fboFlickable.contentHeight = 0

		setFboRow(zi, {
		    rectWidth:  baseW,
		    rectHeight: baseH,
		    rectX: prevController.getFrameX(0, previewInnerRect.width) + 5,
		    rectY: previewFrameY(0, previewInnerRect.height)
		})
		prevController.setViewPort(zi, baseW, baseH)

	    } else if (zoom > 100) {
		// ── KEY FIX 1: set BOTH contentWidth and contentHeight ──────────
		fboFlickable.contentWidth  = scaledW
		fboFlickable.contentHeight = scaledH

		// ── KEY FIX 2: place container at (0,0), full scaled size ───────
		// Do NOT rely on fboX/fboY from calculateViewPort for positioning —
		// those are internal letterbox offsets within the FBO, not container offsets.
		setFboRow(zi, {
		    rectWidth:  scaledW,
		    rectHeight: scaledH,
		    rectX: 0,          // start at left edge, flickable handles scrolling
		    rectY: 0
		})

		// Tell C++ the scaled viewport size so it letterboxes correctly inside
		prevController.applyZoom(zi, baseW, baseH, zoomScale)

	    } else {
		// Zoomed out — shrink and center, no scrollbars needed
		fboFlickable.contentWidth  = 0
		fboFlickable.contentHeight = 0

		var centeredX = Math.round((previewInnerRect.width  - scaledW) / 2)
		var centeredY = Math.round((previewInnerRect.height - scaledH - activePreviewStatusBarHeight) / 2)

		setFboRow(zi, {
			rectWidth:  scaledW,
			rectHeight: scaledH,
			rectX: centeredX,
			rectY: centeredY
		})
		prevController.applyZoom(zi, baseW, baseH, zoomScale)
	    }
	}

	// Zooms the single-camera preview in/out by 25% per wheel step (range 50-500%)
	// around the cursor point (viewX, viewY), keeping that image point under the
	// cursor when zoomed in; resets scrolling otherwise.
	function zoomPreviewAt(viewX, viewY, wheelDelta) {
		if (zoomIndex < 0 || !isCameraOpened || fboModel.count === 0 || !zoomAllowed)
			return

		var oldItem = fboModel.get(zoomIndex)
		var oldWidth = Math.max(1, oldItem.rectWidth)
		var oldHeight = Math.max(1, oldItem.rectHeight)
		var imageX = fboFlickable.contentX + viewX - oldItem.rectX
		var imageY = fboFlickable.contentY + viewY - oldItem.rectY
		var focusX = Math.max(0, Math.min(1, imageX / oldWidth))
		var focusY = Math.max(0, Math.min(1, imageY / oldHeight))

		var nextZoom = Math.max(50, Math.min(500,
			zoom + (wheelDelta > 0 ? 25 : -25)))
		if (nextZoom === zoom)
			return

		zoom = nextZoom
		applyZoomToPreview()

		if (zoom > 100) {
			var newItem = fboModel.get(zoomIndex)
			var maxX = Math.max(0, fboFlickable.contentWidth - fboFlickable.width)
			var maxY = Math.max(0, fboFlickable.contentHeight - fboFlickable.height)
			fboFlickable.contentX = Math.max(0, Math.min(maxX,
				newItem.rectX + focusX * newItem.rectWidth - viewX))
			fboFlickable.contentY = Math.max(0, Math.min(maxY,
				newItem.rectY + focusY * newItem.rectHeight - viewY))
		} else {
			fboFlickable.contentX = 0
			fboFlickable.contentY = 0
		}
	}

}
