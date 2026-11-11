import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import DeviceEnums 1.0

Rectangle {
    id: usbcamRect
    anchors.top: parent.top
    height: right_con_up.height
    color: "#0d1926"
	border.color: "#263949"
	border.width: 1

    property int expandedIndex: -1         // Track which device tab is expanded
	property int selectedIndex: -1
    property int fileDesc: -1
    property int propertyCount: 0
    property bool isHidInitialized : false

    onExpandedIndexChanged: {
        if (expandedIndex < 0 && usbcamFlickable)
            usbcamFlickable.dynamicContentWidth = 0
    }
	
	property var result

    signal setExposureMode(bool mode);
    signal setFocusMode(bool mode);
	signal setUvcGainValue(int value);
	signal setUvcAntiFlicker(var value);

	signal setHidGainValue(int value);
	signal setHidAntiFlicker(var value);
	
	Connections{
		target : prevController
		// Handles prevController.usbDeviceAdded signal: after the repeater grows, re-initialises
		// the controls of the currently expanded camera (deferred with Qt.callLater).
		function onUsbDeviceAdded(newIndex) {
			// Growing the Repeater may recreate the already-expanded delegate.
			// Restore its controls after the new delegate set has settled.
			const activeIndex = expandedIndex
			if (activeIndex < 0)
				return
			Qt.callLater(function() {
				const activeItem = cameraRepeater.itemAt(activeIndex)
				if (activeItem)
					activeItem.restoreExpandedControls()
			})
		}
		// Handles prevController.usbDeviceRemoved signal: shifts/clamps the expanded and selected
		// indices for the removed device, resets HID state and restores the expanded controls.
		function onUsbDeviceRemoved(removedIndex, newCount) {
			var activeIndex = expandedIndex
			if (newCount <= 0) {
				activeIndex = -1
			} else if (activeIndex === removedIndex) {
				activeIndex = Math.min(removedIndex, newCount - 1)
			} else if (activeIndex > removedIndex) {
				activeIndex--
			}

			expandedIndex = activeIndex
			selectedIndex = activeIndex
			isHidInitialized = false
			usbcamFlickable.dynamicContentWidth = 0

			if (activeIndex >= 0) {
				Qt.callLater(function() {
					const activeItem = cameraRepeater.itemAt(activeIndex)
					if (activeItem)
						activeItem.restoreExpandedControls()
				})
			}
		}
		// Handles prevController.cameraClosed signal: collapses the accordion, resets HID state
		// and, on Windows, deinitialises the extension unit of the closed camera's controller.
		function onCameraClosed(){
			ecam212usbUvcextController.clearDevices()
			expandedIndex = -1
			selectedIndex = -1
			isHidInitialized = false
			usbcamFlickable.dynamicContentWidth = 0
			if (Qt.platform.os === "windows") {
				const devType = DeviceEnumInstance.resolveDevice(controlSelectedVid, controlSelectedPid)
				switch(devType) {
					case DeviceEnums.See3CAM_130E:
					case DeviceEnums.See3CAM_130E_H02R1:
						see3cam130eController.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_1318_TC:
						see3cam1318tcController.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU31:
						see3camcu31Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU83:
						see3camcu83Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_27CUG:
						see3cam27cugController.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_37CUG:
						see3cam37cugController.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU130:
						see3camcu130Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU135M_H01R1:
						see3camcu135mh01r1Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU135:
						see3camcu135Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU512M:
						see3camcu512mController.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU84:
						see3camcu84Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU27:
						see3camcu27Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU200M:
						see3camcu200mController.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU200:
						see3camcu200Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_160:
						see3cam160Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU55:
						see3camcu55Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_24CUG:
						see3cam24cugController.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU81:
						see3camcu81Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU58:
					case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
						see3camcu58Controller.deinitExtensionUnit(); break
					case DeviceEnums.See3CAM_CU55_MH:
						see3camcu55mhController.deinitExtensionUnit(); break
					case DeviceEnums.DensiCAM:
						densicamController.deinitExtensionUnit(); return  // note: original had early return here
					default: break
				}
				densicamController.deinitExtensionUnit()
			}
		}
		// Handles prevController.cameraOpened signal: resolves the opened device from its VID/PID
		// and initialises the matching camera controller's extension unit (Windows/Linux paths).
		function onCameraOpened(index){
			selectedDevices = selectedDevices
			if (index >= 0 && index < selectedDevices.length) {
				var dev = selectedDevices[index]
        
				// Guard: vid/pid must be present
				if (!dev.deviceVid || !dev.devicePid) return

				const devType = DeviceEnumInstance.resolveDevice(dev.deviceVid, dev.devicePid)

				if (Qt.platform.os === "windows") {
					switch(devType) {
						case DeviceEnums.ECAM212_USB:
							ecam212usbUvcextController.initUVCExtension(dev.devicePath)
							break
						case DeviceEnums.ECAM16_USB:
							ecam16usbController.initUVCExtension(dev.devicePath)
							break
                        case DeviceEnums.ECAM82_USB:
							ecam82usbController.initUVCExtension(dev.devicePath)
							break
						case DeviceEnums.See3CAM_130E:
						case DeviceEnums.See3CAM_130E_H02R1:
						case DeviceEnums.See3CAM_130E_H03R1:
							see3cam130eController.initializeFromDevicePath(dev.devicePath)
							if(selectedDevices.length == 1){
								see3cam130eController.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_1318_TC:
							see3cam1318tcController.initializeFromDevicePath(dev.devicePath)
							if(selectedDevices.length == 1){
								see3cam1318tcController.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU130:
							see3camcu130Controller.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU31:
							see3camcu31Controller.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU83:
							see3camcu83Controller.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_27CUG:
							see3cam27cugController.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_37CUG:
							see3cam37cugController.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU135M_H01R1:
							see3camcu135mh01r1Controller.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU135:
							see3camcu135Controller.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU512M:
							see3camcu512mController.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU84:
							see3camcu84Controller.initializeFromDevicePath(dev.devicePath)
							if(selectedDevices.length == 1){
								see3camcu84Controller.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU27:
							see3camcu27Controller.initializeFromDevicePath(dev.devicePath)
							if(selectedDevices.length == 1){
								see3camcu27Controller.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_160:
							see3cam160Controller.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU200M:
							see3camcu200mController.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU200:
							see3camcu200Controller.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_24CUG:
							see3cam24cugController.initializeFromDevicePath(dev.devicePath)
							if(selectedDevices.length == 1){
								see3cam24cugController.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU81:
							see3camcu81Controller.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.See3CAM_CU55:
							see3camcu55Controller.initializeFromDevicePath(dev.devicePath)
							if(selectedDevices.length == 1){
								see3camcu55Controller.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU58:
						case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
							see3camcu58Controller.initializeFromDevicePath(dev.devicePath)
							if(selectedDevices.length == 1){
								see3camcu58Controller.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU55_MH:
							see3camcu55mhController.initializeFromDevicePath(dev.devicePath)
							break
						case DeviceEnums.DensiCAM:
							densicamController.initializeFromDevicePath(dev.devicePath)
							break
						default:
							break
					}
				} else {
					prevController.getFileDescriptor(index)
					// Linux path
					switch(devType) {
						case DeviceEnums.ECAM212_USB:
							ecam212usbUvcextController.initialize(
								dev.devicePath, prevController.getFileDescriptorForCamera(index))
							break
						case DeviceEnums.ECAM16_USB:
							ecam16usbController.initialize(dev.devicePath)
							break
                        case DeviceEnums.ECAM82_USB:
							ecam82usbController.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_130E:
						case DeviceEnums.See3CAM_130E_H02R1:
						case DeviceEnums.See3CAM_130E_H03R1:
							see3cam130eController.initialize(fileDesc)
							if(selectedDevices.length == 1){
								see3cam130eController.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_1318_TC:
							see3cam1318tcController.initialize(fileDesc)
							if(selectedDevices.length == 1){
								see3cam1318tcController.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU130:
							see3camcu130Controller.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_CU31:
							see3camcu31Controller.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_CU83:
							see3camcu83Controller.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_27CUG:
							see3cam27cugController.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_37CUG:
							see3cam37cugController.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_CU135M_H01R1:
							see3camcu135mh01r1Controller.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_CU135:
							see3camcu135Controller.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_CU512M:
							see3camcu512mController.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_160:
							see3cam160Controller.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_CU84:
							see3camcu84Controller.initialize(fileDesc)
							if(selectedDevices.length == 1){
								see3camcu84Controller.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU27:
							see3camcu27Controller.initialize(fileDesc)
							if(selectedDevices.length == 1){
								see3camcu27Controller.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU200M:
							see3camcu200mController.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_CU200:
							see3camcu200Controller.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_24CUG:
							see3cam24cugController.initialize(fileDesc)
							if(selectedDevices.length == 1){
								see3cam24cugController.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU81:
							see3camcu81Controller.initialize(fileDesc)
							break
						case DeviceEnums.See3CAM_CU58:
						case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
							see3camcu58Controller.initialize(fileDesc)
							if(selectedDevices.length == 1){
								see3camcu58Controller.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU55:
							see3camcu55Controller.initialize(fileDesc)
							if(selectedDevices.length == 1){
								see3camcu55Controller.getBurstLength()
							}
							break
						case DeviceEnums.See3CAM_CU55_MH:
							see3camcu55mhController.initialize(fileDesc)
							break
						case DeviceEnums.DensiCAM:
							densicamController.initialize(fileDesc)
							break
						default:
							break
					}
				}
			}
		}

        function onFileDescriptor(fd){
            fileDesc = fd;
        }
	}
    // --- Header (Usbcam Controls) ---
    Rectangle {
        id: usbcamLabel
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
        clip: true

        Text {
			anchors.left: parent.left
			anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Helvetica"
            font.pixelSize: menuFontSize + 1
            font.bold: true
			text: "USB Camera Controls"
            color: "#ffffff"
        }

        // --- Close Button ---
        Rectangle {
            id: usbcamCloseImgBg
            width: expandedStateIconW + 5
            height: expandedStateIconH + 5
            color: mouseArea.containsMouse ? "#c90808" : "transparent"
            anchors.right: usbcamLabel.right
			anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            visible: true

            Image {
                id: x_usbcam
                source: "qrc:View/icons/closeSmall.svg"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                id: mouseArea
                objectName: "usbcamCloseMouseArea"
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
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
					text: "Close USB Camera Controls"
                }
            }
        }
    }

    // --- Vertical Tabs + Expandable UsbcamSettings ---

    Flickable {
        id: usbcamFlickable
        objectName: "usbcamFlickable"
        anchors.top: usbcamLabel.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        property int horizontalScrollPadding: usbcamCustomHScrollBar.visible ? usbcamCustomHScrollBar.height : 0
        property real dynamicContentWidth: 0
        property real fixedContentWidth: usbcamRect.expandedIndex >= 0 ? Math.max(
            right_con_up.width,
            cameraSettingsTabMeasure.implicitWidth + extensionSettingsTabMeasure.implicitWidth + 112
        ) : 0
        contentHeight: Math.max(height, contentColumn.implicitHeight + horizontalScrollPadding)
        // Vertical only: the camera headers and the settings tabs always fit the visible
        // width. Wide settings scroll sideways inside settingsScroll instead.
        contentWidth: width
        flickableDirection: Flickable.VerticalFlick
        clip: true
        interactive: contentHeight > height || contentWidth > width
         // ── Scroll speed controls ──────────────────────────────
        flickDeceleration: 3000 // (Brake) Higher value : stops quickly
        maximumFlickVelocity: 1200 // Low value : Low speed of scrolling

		boundsBehavior: Flickable.StopAtBounds  //Prevents overscroll

        onContentWidthChanged: {
            if (usbcamRect.expandedIndex < 0 && dynamicContentWidth !== 0)
                dynamicContentWidth = 0
        }

        Text {
            id: cameraSettingsTabMeasure
            visible: false
            text: "Camera Settings"
            font.pixelSize: menuFontSize
            font.bold: true
        }

        Text {
            id: extensionSettingsTabMeasure
            visible: false
            text: "Extension Settings"
            font.pixelSize: menuFontSize
            font.bold: true
        }

        Column {
            id: contentColumn
            // Leaves a lane at the right edge for the scroll bars (5 left margin + 12 bar + 3 gap)
            width: Math.max(0, usbcamFlickable.width - usbcamCustomVScrollBar.width - 8)
            spacing: 0
            anchors.left: parent.left
            anchors.leftMargin: 5
            anchors.rightMargin: 5

			Repeater {
				id: cameraRepeater
                model: selectedDeviceCount

	                Column {
	                    // Re-selects this expanded camera and reloads its UVC and extension control JSON, control
	                    // values and tooltips, then shows the first settings tab.
	                    function restoreExpandedControls() {
	                        if (index !== usbcamRect.expandedIndex ||
	                                index < 0 || index >= selectedDevices.length)
	                            return

	                        const device = selectedDevices[index]
	                        ecam212usbUvcextController.setActiveDevicePath(device.devicePath)
	                        selectedIndex = index
	                        controlSelectedDevName = device.deviceName
	                        controlSelectedVid = device.deviceVid
	                        controlSelectedPid = device.devicePid
	                        prevController.readUsbJsonArrayFile()
	                        if (device.devicePath)
	                            usbcamSettingsComponent.initializeControls(index)
	                        prevController.readExtensionUsbJsonArrayFile(device.deviceVid, device.devicePid)
	                        logController.readUsbExtControlJsonArrayFile(device.deviceVid, device.devicePid)
	                        settingsPanel.currentTab = 0
	                        settingsPanel.loadControls()
	                    }

	                    width: parent.width
	                    property real requiredWidth: Math.max(tabButton.implicitWidth, settingsPanel.implicitWidth)
	                    spacing: 10

	                    // --- Device Tab Button ---
	                    Rectangle {
	                        id: tabButton
	                        implicitWidth: visible ? Math.max(usbcamSettingsComponent.implicitWidth, right_con_up.width) : 0
	                        width:  visible ? parent.width : 0
                        height: 40
                        color: (usbcamRect.expandedIndex === index) ? "#0b5fae" : "#111f2d"
                        radius: 7
						border.color: (usbcamRect.expandedIndex === index) ? "#0b84f3" : "#263949"

                        Text {
                            text: (selectedDevices
                            && index >= 0
                            && index < selectedDevices.length
                            && selectedDevices[index]
                            && selectedDevices[index].deviceName !== undefined)
                            ? selectedDevices[index].deviceName
                            : ""
                            color: "white"
                            font.bold: true
							font.pixelSize: baseFontSize
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                        }

                        MouseArea {
                            objectName: "tabMouseArea"
                            anchors.fill: parent

							onClicked: {
								if(usbcamRect.expandedIndex === index){
									selectedIndex = index
								} else if (selectedIndex != index){
									selectedIndex = index
									const device = selectedDevices[index]
									ecam212usbUvcextController.setActiveDevicePath(device.devicePath)
									controlSelectedDevName = device.deviceName

									controlSelectedVid = device.deviceVid 
									controlSelectedPid = device.devicePid 

									prevController.readUsbJsonArrayFile()
									if(device.devicePath){
										usbcamSettingsComponent.initializeControls(selectedIndex)
									}
									prevController.readExtensionUsbJsonArrayFile(device.deviceVid, device.devicePid)
									logController.readUsbExtControlJsonArrayFile(device.deviceVid, device.devicePid);

									const devType = DeviceEnumInstance.resolveDevice(controlSelectedVid, controlSelectedPid)
				
									if (Qt.platform.os === "windows") {
										switch(devType) {
											case DeviceEnums.ECAM212_USB:
												propertyCount = 5
												isHidInitialized = true
												break
											case DeviceEnums.ECAM16_USB:
												propertyCount = 1
												isHidInitialized = true
												break
                                            case DeviceEnums.ECAM82_USB:
												propertyCount = 1
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_130E:
											case DeviceEnums.See3CAM_130E_H02R1:
												propertyCount = 30
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_1318_TC:
												propertyCount = 30
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU130:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU135M_H01R1:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU135:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_24CUG:
												propertyCount = 21
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_160:
												propertyCount = 21
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU512M:
												propertyCount = 5
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU84:
												propertyCount = 21
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU81:
												propertyCount = 21
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU58:
											case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU27:
												propertyCount = 10
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU55:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.DensiCAM:
												propertyCount = 21
												isHidInitialized = true
												break
											default: break
										}
									} else {
										switch(devType) {
											case DeviceEnums.ECAM212_USB:
												propertyCount = 5
												isHidInitialized = true
												break
											case DeviceEnums.ECAM16_USB:
												propertyCount = 1
												isHidInitialized = true
												break
                                            case DeviceEnums.ECAM82_USB:
												propertyCount = 1
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_130E:
											case DeviceEnums.See3CAM_130E_H02R1:
												propertyCount = 30
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_1318_TC:
												propertyCount = 30
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU130:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU135M_H01R1:
												propertyCount = 25
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_24CUG:
												propertyCount = 21
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU512M:
												propertyCount = 5
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU81:
												propertyCount = 21
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_160:
												propertyCount = 30
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU135:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU84:
												propertyCount = 25
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_160:
												propertyCount = 21
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU58:
											case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU55:
												propertyCount = 18
												isHidInitialized = true
												break
											case DeviceEnums.See3CAM_CU27:
												propertyCount = 10
												isHidInitialized = true
												break
											case DeviceEnums.DensiCAM:
												propertyCount = 21
												isHidInitialized = true
												break
											default: break
										}
									}
								}
								usbcamRect.expandedIndex = (usbcamRect.expandedIndex === index) ? -1 : index
							}
                        }
                    }

                   // --- Expandable Settings Panel with Tabs ---
	                    Rectangle {
	                        id: settingsPanel
	                        implicitWidth: visible ? Math.max(right_con_up.width, tabBar.implicitWidth) : 0
	                        width: visible ? parent.width : 0
                        color: "#0d1926"
                        radius: 8
						border.color: "#263949"
						border.width: 1
                        visible: usbcamRect.expandedIndex === index
                        height: {
                            if (!visible) return 0
                            var contentHeight = currentSettingsComponent.implicitHeight
                            if (contentHeight <= 0) contentHeight = 400  // fallback minimum height
                            var naturalHeight = tabBar.height + contentHeight + 20 + 40 // 20 for margins
                            // Fit below the camera headers (40 each, plus this camera's 10 spacing) so
                            // the tab bar never scrolls away; the settings scroll inside settingsScroll.
                            // and stop above the settings horizontal bar at the panel's bottom edge
                            var available = usbcamFlickable.height - usbcamFlickable.horizontalScrollPadding
                                - cameraRepeater.count * 40 - 10 - 2
                                - (settingsHScrollBar.visible ? settingsHScrollBar.height + 2 : 0)
                            return Math.min(naturalHeight, Math.max(tabBar.height + 160, available))
                        }
                        clip: true

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // Tab Bar
	                            Rectangle {
	                                id: tabBar
	                                implicitWidth: tabRow.requiredWidth
	                                width: parent.width
	                                // Tabs always side by side; when their names don't fit on one line
	                                // each name wraps onto two lines inside its own half
	                                property bool twoLines: tabRow.requiredWidth > width
                                height: twoLines ? 56 : 40
								color: "#0e1b28"
								border.color: "#263949"
								border.width: 1
								radius: 6
                                
	                                Grid {
	                                    id: tabRow
	                                    anchors.fill: parent
	                                    property real requiredWidth: cameraTab.implicitWidth + extensionTab.implicitWidth + spacing
	                                    columns: 2
	                                    spacing: 2

	                                    // Camera Settings Tab
	                                    Rectangle {
	                                        id: cameraTab
	                                        implicitWidth: cameraTabText.implicitWidth + 40
	                                        width: (parent.width - parent.spacing) / 2
	                                        height: parent.height
										color: "transparent"
                                        radius: 6
                                        
	                                        Text {
	                                            id: cameraTabText
	                                            anchors.centerIn: parent
	                                            width: Math.min(implicitWidth, parent.width - 8)
	                                            wrapMode: Text.WordWrap
	                                            horizontalAlignment: Text.AlignHCenter
                                            text: "Camera Settings"
                                            color: settingsPanel.currentTab === 0 ? "#ffffff" : "#808080"
                                            font.pixelSize: menuFontSize
                                            font.bold: settingsPanel.currentTab === 0
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
												settingsPanel.currentTab = 0
												settingsPanel.loadControls()
											}
                                        }
                                        
                                        // Active indicator
                                        Rectangle {
                                            visible: settingsPanel.currentTab === 0
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 3
                                            color: "#0b84f3"
                                            radius: 1.5
                                        }
                                    }

                                    // Extension Settings Tab
	                                    Rectangle {
	                                        id: extensionTab
	                                        implicitWidth: extensionTabText.implicitWidth + 40
	                                        width: (parent.width - parent.spacing) / 2
	                                        height: parent.height
										color: "transparent"
                                        radius: 6
                                        
	                                        Text {
	                                            id: extensionTabText
	                                            anchors.centerIn: parent
	                                            width: Math.min(implicitWidth, parent.width - 8)
	                                            wrapMode: Text.WordWrap
	                                            horizontalAlignment: Text.AlignHCenter
                                            text: "Extension Settings"
                                            color: settingsPanel.currentTab === 1 ? "#ffffff" : "#808080"
                                            font.pixelSize: menuFontSize
                                            font.bold: settingsPanel.currentTab === 1
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                settingsPanel.currentTab = 1
												settingsPanel.loadControls()
                                            }
                                        }
                                        
                                        // Active indicator
                                        Rectangle {
                                            visible: settingsPanel.currentTab === 1
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 3
                                            color: "#0b84f3"
                                            radius: 1.5
                                        }
                                    }
                                }
                            }

                            // Settings Content Area: scrolls on its own below the fixed tab bar
                            Rectangle {
                                id: settingsContent
                                width: parent.width
                                height: parent.height - tabBar.height - 20
                            	color: "#0b1723"
                                clip: true

                                Flickable {
                                    id: settingsScroll
                                    objectName: "usbcamSettingsScroll"
                                    // The scroll bars sit at the panel's right and bottom edges
                                    // (outside this box), so the settings use all of it
                                    anchors.fill: parent
                                    // dynamicContentWidth: room the expanded settings ask for (set by
                                    // UsbcamSettings/UsbcamHidSettings), less the panel's own left offset
                                    // (the wrapped "No extension available" message needs no sideways scrolling)
                                    contentWidth: (settingsPanel.currentTab === 1 && usbcamHidSettingsComponent.showsNoExtensionMessage)
                                                  ? width : Math.max(width, usbcamFlickable.dynamicContentWidth - 15)
                                    contentHeight: settingsPanel.currentSettingsComponent.implicitHeight + 8
                                    flickableDirection: Flickable.AutoFlickIfNeeded
                                    boundsBehavior: Flickable.StopAtBounds
                                    interactive: contentHeight > height || contentWidth > width
                                    clip: true

                                    // Camera Settings Component
                                    UsbcamSettings {
                                        id: usbcamSettingsComponent
                                        objectName: "usbcamSettingsComponent"
                                        width: settingsScroll.contentWidth
                                        height: implicitHeight
                                        visible: settingsPanel.currentTab === 0
                                    }

                                    // Extension Settings Component
                                    UsbcamHidSettings {
                                        id: usbcamHidSettingsComponent
                                        objectName: "usbcamHidSettingsComponent"
                                        width: settingsScroll.contentWidth
                                        height: implicitHeight
                                        visible: settingsPanel.currentTab === 1
                                    }

                                    ScrollBar.vertical: ScrollBar {
                                        id: settingsVScrollBar
                                        objectName: "usbcamSettingsVScrollBar"
                                        // At the panel's right edge, from the top of the settings
                                        // (below the fixed tabs) down to the bottom edge
                                        parent: usbcamFlickable
                                        width: 12
                                        x: usbcamFlickable.width - width
                                        y: Math.max(0, contentColumn.y + settingsPanel.parent.y + settingsPanel.y + 10
                                                       + settingsContent.y - usbcamFlickable.contentY)
                                        height: Math.max(0, usbcamFlickable.height - y
                                                         - (settingsHScrollBar.visible ? settingsHScrollBar.height + 2 : 0))
                                        active: false
                                        visible: settingsPanel.visible && settingsScroll.contentHeight > settingsScroll.height
                                        contentItem: Rectangle {
                                            implicitWidth: 8
                                            implicitHeight: 15
                                            radius: 4
                                            color: (settingsVScrollBar.active || settingsVScrollBar.hovered) ? "#2087cc" : "#45a7ff"
                                        }
                                        background: Rectangle {
                                            color: "#07111d"
                                            border.color: "#263949"
                                            border.width: 1
                                            radius: 4
                                            width: 12
                                        }
                                    }
                                    // Sideways scrolling for wide settings only; the tabs above never move
                                    ScrollBar.horizontal: ScrollBar {
                                        id: settingsHScrollBar
                                        objectName: "usbcamSettingsHScrollBar"
                                        // Along the panel's bottom edge
                                        parent: usbcamFlickable
                                        height: 12
                                        x: 0
                                        y: usbcamFlickable.height - height
                                        width: usbcamFlickable.width - (settingsVScrollBar.visible ? settingsVScrollBar.width + 2 : 0)
                                        active: false
                                        visible: settingsPanel.visible && settingsScroll.contentWidth > settingsScroll.width
                                        contentItem: Rectangle {
                                            implicitWidth: 15
                                            implicitHeight: 8
                                            radius: 4
                                            color: (settingsHScrollBar.active || settingsHScrollBar.hovered) ? "#2087cc" : "#45a7ff"
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

                        // Property to track current tab (0 = Camera, 1 = Extension)
                        property int currentTab: 0
                        
                        // Property to get current component for height calculation
                        property var currentSettingsComponent: currentTab === 0 ? 
                            usbcamSettingsComponent : usbcamHidSettingsComponent

							// Loads controls for the active settings tab: UVC controls (tab 0) or HID/extension
							// controls (other tabs).
							function loadControls() {
								if (currentTab === 0) {
									if (usbcamSettingsComponent) {
										 usbcamSettingsComponent.readCameraControls()
									}
								}
								else {
									if (usbcamHidSettingsComponent) {	
											usbcamHidSettingsComponent.getCameraControls()		
									}
								}
							}
                        
                        // A tab starts at its top-left; keeps the other tab's scroll position
                        // from hiding the start of short content
                        onCurrentTabChanged: {
                            settingsScroll.contentX = 0
                            settingsScroll.contentY = 0
                        }

                        // Reset to Camera Settings tab when panel becomes visible
                        onVisibleChanged: {
                            if (visible) {
                                currentTab = 0
								loadControls()
                            }
                        }
                    }
                }
            }
        }

        // Custom vertical scrollbar
        ScrollBar.vertical: ScrollBar {
            id: usbcamCustomVScrollBar
            objectName: "usbcamCustomVScrollBar"
            width: 12
            active: false
            visible: usbcamFlickable.contentHeight > usbcamFlickable.height
            contentItem: Rectangle {
                implicitWidth: 8
                implicitHeight: 15
                radius: 4
                color: (usbcamCustomVScrollBar.active || usbcamCustomVScrollBar.hovered) ? "#2087cc" : "#45a7ff"
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
            id: usbcamCustomHScrollBar
            objectName: "usbcamCustomHScrollBar"
            height: 12
            active: false
            visible: usbcamFlickable.contentWidth > usbcamFlickable.width
            contentItem: Rectangle {
                implicitWidth: 15
                implicitHeight: 8
                radius: 4
                color: (usbcamCustomHScrollBar.active || usbcamCustomHScrollBar.hovered) ? "#2087cc" : "#45a7ff"
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
