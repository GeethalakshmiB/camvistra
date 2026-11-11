import QtQuick 2.12
import QtQuick.Controls 2.12
import "../JS/devices.js" as DevicesJS
DeviceAccordion {
    x: 10
    y: 10
    width: parent ? parent.width - 20 : 0
    height: implicitHeight
	property var wifi_devices: []
	property var ethernet_devices: []
	property var usb_devices : []
	property var gmsl_devices : []
	property var mipi_devices : []
	property var pci_devices : []
	readonly property var localCameraTypes: ["Usb", "GMSL", "MIPI", "PCI"]  // transports shown under the USB camera row
     property var audio_devices : []
	property var lastCheckedDevice: ""
	property var onvifdevice:""
    property var selectedAudioDev : ""
    property var selectedAudioDevicePath : ""
	onSelectedAudioDevicePathChanged: window.audioDeviceSelected = selectedAudioDevicePath !== ""
	property bool audioManuallyDeselected : false
	property var selectedDev : []
	property var checkedDevCnt : 0
	property bool deviceUnplug: false
	property bool isCameraClosed: true
	property var modelData: DevicesJS.getModelDevices()
	property bool onvifInitialize : false
	property bool manualUncheck: false
	property bool isCheckedDevRemoved : false
	property bool isDeviceRemoved : false
	property bool isTimeout : false
	property bool opencamInitiated : false
	model: modelData

	// GMSL, MIPI and PCI grabber cameras exist only on Ubuntu/Jetson PCs, so their
	// sidebar rows are left out on Windows.
	readonly property var linuxOnlyCategoryIds: ["gmslDev", "mipiDev", "pciDev"]
	function sidebarRows(jsonArray) {
		if (Qt.platform.os !== "windows") return jsonArray
		return jsonArray.filter(row => linuxOnlyCategoryIds.indexOf(row.id) < 0)
	}

	function localCameraList(transportType) {
		if (transportType === "GMSL") return gmsl_devices
		if (transportType === "MIPI") return mipi_devices
		if (transportType === "PCI") return pci_devices
		return usb_devices
	}

	function setLocalCameraList(transportType, devices) {
		if (transportType === "GMSL") gmsl_devices = devices
		else if (transportType === "MIPI") mipi_devices = devices
		else if (transportType === "PCI") pci_devices = devices
		else usb_devices = devices
	}

	function localCategoryId(transportType) {
		if (transportType === "GMSL") return "gmslDev"
		if (transportType === "MIPI") return "mipiDev"
		if (transportType === "PCI") return "pciDev"
		return "usbDev"
	}

	function audioCategoryIndex() {
		return modelData.findIndex(row => row.id === "audioDev")
	}

	function updateLocalCameraRow(transportType, expand) {
		const id = localCategoryId(transportType)
		const rowIndex = modelData.findIndex(row => row.id === id)
		if (rowIndex < 0) return
		const devices = localCameraList(transportType)
		modelData[rowIndex].children = devices.length > 0
			? devices
			: [{ label: "No devices found", noDevices: true, enabled: false }]
		if (expand) modelData[rowIndex].expanded = true
		model = modelData
	}

	function updateAllLocalCameraRows() {
		updateLocalCameraRow("Usb", false)
		updateLocalCameraRow("GMSL", false)
		updateLocalCameraRow("MIPI", false)
		updateLocalCameraRow("PCI", false)
	}

	function setLocalCameraChecked(devicePath, checked) {
		localCameraTypes.forEach(function(transportType) {
			const devices = localCameraList(transportType).map(function(device) {
				if (device.devicePath === devicePath) device.checked = checked
				return device
			})
			setLocalCameraList(transportType, devices)
			updateLocalCameraRow(transportType, false)
		})
	}

	function addLocalCamera(device) {
		const transportType = device.transportType || "Usb"
		const devices = localCameraList(transportType).slice()
		let existing = devices.find(item => item.devicePath === device.devicePath)
		if (!existing) {
			existing = {
				label: device.deviceName || device.devicePath,
				checked: false,
				devicePath: device.devicePath,
				deviceName: device.deviceName || device.devicePath,
				deviceVid: device.deviceVid,
				devicePid: device.devicePid,
				deviceSerialNo: device.deviceSerialNo,
				manuallyAdded: device.manuallyAdded,
				transportType: transportType,
				type: "Usb"
			}
			devices.push(existing)
		}
		setLocalCameraList(transportType, devices)

		if (selectedDevices.length === 0 && !manualUncheck && !isDeviceRemoved) {
			const first = devices[0]
			first.checked = true
			selectedDevType = "Usb"
			logController.readUsbControlJsonArrayFile()
			selectedDevices = [{
				deviceType: "Usb",
				deviceName: first.deviceName,
				deviceSerialNo: first.deviceSerialNo,
				srcUrl: first.devicePath,
				devicePath: first.devicePath,
				deviceVid: first.deviceVid,
				devicePid: first.devicePid,
				transportType: first.transportType
			}]
			checkedDevCnt = 1
			selectedDevCnt = 1
			selectedDeviceCount = 1
			fpsTimer.stop()
			prevController.setSelectedDeviceCount(1, selectedDevType)
			prevController.setSelectedDevices(selectedDevices)
			setDeviceType(usbDev)
			opencamInitiated = true
			openCamTimer.start()
		}
		updateLocalCameraRow(transportType, true)
	}


	// Returns true if audio can be used: only when exactly one USB camera is
	// selected.
	function isAudioAvailable() {
		return selectedDevType == "Usb" &&
			selectedDevices.length == 1
	}

	// Enables/disables the audio device entries based on isAudioAvailable(); when
	// disabled, unchecks them and clears the selected audio device (also in the
	// controller). Rebuilds the Audio node (located by category ID) of the device tree.
	function refreshAudioAvailability() {
		window.audioDeviceAvailable = audio_devices.length > 0
		var enabled = isAudioAvailable()
		for (var i = 0; i < audio_devices.length; i++) {
			audio_devices[i].enabled = enabled
			if (!enabled) {
				audio_devices[i].checked = false
			}
		}

		if (!enabled) {
			if (selectedAudioDevicePath !== "") {
				prevController.setSelectedAudioDevice("", -1)
			}
			selectedAudioDev = ""
			selectedAudioDevicePath = ""
			audioManuallyDeselected = true
		}

		if (modelData.length > 5) {
			modelData[audioCategoryIndex()].enabled = enabled
			modelData[audioCategoryIndex()].children = audio_devices.length > 0
				? audio_devices
				: [{ label: "No devices found", noDevices: true, enabled: false }]
			model = modelData
		}
	}

	Timer{
		id: openCamTimer
		interval: 1000
		running: false  
		repeat: false  
		onTriggered: {
		   prevController.setSelectedDevices(selectedDevices)
			if(isCheckedDevRemoved){
				isCheckedDevRemoved = false
			}
			if(isTimeout){
				isTimeout = false	
			}
			opencamInitiated = false
		}
	}
 
	// Handles checking a device in the tree. Switching device type first clears
	// all previous selections. Then adds the device to selectedDevices, loads the
	// type's control JSON (Wi-Fi also initialises ONVIF) and, if the checked count
	// changed, opens the camera(s): a 2nd USB camera is added incrementally,
	// otherwise openCamTimer is started. Audio entries go to selectAudioDevice().
	function setSelectedDevice(device) {
          if (device.type === "Audio") {
               selectAudioDevice(device)
               return
          }
		if(selectedDevType != device.type){
				setDeviceType(-1)
				const previousDevType = selectedDevType
				const hasManualDevice = selectedDevices.some(sd => sd.manuallyAdded === true)

				if (hasManualDevice && (previousDevType === "Wi-Fi" || previousDevType === "Ethernet")) {
					// Manually uncheck in modelData so handleUncheckedDeviceRemoval
					// sees it as an unchecked removal
					const parentIndex = previousDevType === "Wi-Fi" ? 0 : 1
					const manualDevices = selectedDevices.filter(sd => sd.manuallyAdded === true)
					manualDevices.forEach(manDev => {
						const childrenList = modelData[parentIndex].children
						for (let i = 0; i < childrenList.length; i++) {
							if (childrenList[i].deviceIP === manDev.deviceIP) {
								modelData[parentIndex].children[i].checked = false
								break
							}
						}
					})
					devController.removeManuallyAddedDevice()
				}

			  selectedDevices.forEach(dev => {
				if(selectedDevType == "Ethernet" || selectedDevType == "Wi-Fi"){
					// Find and uncheck in modelData by IP
					let parentIndex = selectedDevType == "Wi-Fi" ? 0 : 1;
					let childrenList = modelData[parentIndex].children;
					for (let i = 0; i < childrenList.length; i++) {
						if (childrenList[i].deviceIP === dev.deviceIP) {
							modelData[parentIndex].children[i].checked = false;
							break;
						}
					}
				} else if(selectedDevType == "Usb") {
					setLocalCameraChecked(dev.devicePath, false)
				}
			});
			// Clear the selectedDevices array
			selectedDevices = [];
			// Reset counts and notify
			checkedDevCnt = 0;
			selectedDevCnt = 0;
			selectedDeviceCount = 0;
			prevController.setSelectedDeviceCount(0, selectedDevType);
			// Update the selectedDevType for the new device
			selectedDevType = device.deviceType;
		}
		if(isDeviceRemoved){
			isDeviceRemoved = false
		}
		var matchedIndex = -1
		let alreadyCheckedDev;
		if(selectedDevType == "Ethernet" || selectedDevType == "Wi-Fi"){
			alreadyCheckedDev = selectedDevices.find(d => d.deviceIP === device.deviceIP);
		} else{
			alreadyCheckedDev = selectedDevices.find(d => d.devicePath === device.devicePath);
		}
		
		if(!alreadyCheckedDev){ 
            selectedDev = {
					label: device.label,
					type: device.type,
					deviceIP: device.devicePath,
					devicePath: device.devicePath,
					manuallyAdded: device.manuallyAdded,
					deviceName: device.deviceName,
					checked: device.checked,
			}

			if(device.type == "Wi-Fi"){			
				if(selectedDevType != "Wi-Fi"){
					selectedDevType = "Wi-Fi"
					logController.readJsonArrayFile();
				} 
				var childrenList = modelData[0].children;
				for (var i = 0; i < childrenList.length; ++i) {
					if (childrenList[i].deviceIP === device.deviceIP) {
						matchedIndex = i;
						break;
					}
				}
				modelData[0].children[matchedIndex].checked = true
				selectedDevices.push({'deviceType' : device.type, 'deviceIP': device.deviceIP, 'srcUrl': "rtsp://" + device.deviceIP + "/video", 'deviceName' : device.deviceName, 'manuallyAdded': device.manuallyAdded})
					
				setDeviceType(wifiDev);
				wifiOnvifController.readJsonArrayFile()				
				var onvif = wifiOnvifController.initializeOnvif(selectedDevices[0].deviceName);
				onvifInitialize = true
				
				model = modelData;
				checkedDevCnt = 0
				var children = model[0].children
				for (var i = 0; i < children.length; i++) {
					if (children[i].checked === true) {
						checkedDevCnt = checkedDevCnt + 1;
					}
				}
					
				if(selectedDevCnt != checkedDevCnt){
					selectedDevCnt = checkedDevCnt
					selectedDeviceCount = checkedDevCnt
					prevController.setSelectedDeviceCount(checkedDevCnt, selectedDevType)

					opencamInitiated = true
					openCamTimer.start()
				}		
			} 
			else if(device.type == "Ethernet"){
				if(selectedDevType != "Ethernet"){
					selectedDevType = "Ethernet"
					logController.readControlJsonArrayFile();
				}
				var childrenList = modelData[1].children;
				for (var i = 0; i < childrenList.length; ++i) {
					if (childrenList[i].deviceIP === device.deviceIP) {
						matchedIndex = i;
						break;
					}
				}
				modelData[1].children[matchedIndex].checked = true
				
				var deviceDetails = routecamOnvifController.getStreamUrl(device.deviceIP)
				var srcUrl = deviceDetails.srcUrl
				selectedDevices.push({'deviceType' : device.type, 'deviceIP': device.deviceIP, 'deviceName' : device.deviceName, 'srcUrl': srcUrl, 'manuallyAdded': device.manuallyAdded})
				 model = modelData;
				checkedDevCnt = 0
					
				var children = model[1].children
				for (var i = 0; i < children.length; i++) {
					if (children[i].checked === true) {
						checkedDevCnt = checkedDevCnt + 1;
					}
				}
				if(selectedDevCnt != checkedDevCnt){
					selectedDevCnt = checkedDevCnt
					selectedDeviceCount = checkedDevCnt
					prevController.setSelectedDeviceCount(checkedDevCnt, selectedDevType)

					opencamInitiated = true
					openCamTimer.start()
				}
			} 
			else if(device.type == "Usb"){
				if(selectedDevType != "Usb"){
					selectedDevType = "Usb"
					logController.readUsbControlJsonArrayFile();
				}

				setDeviceType(usbDev);
				closeRightUp = false
				handleCheckChangedUpRight(false)
				var wasAlreadyStreaming = selectedDevCnt > 0

				// Record the selection before setLocalCameraChecked() rebuilds the device
				// list: the recreated, already-checked checkbox re-enters setSelectedDevice(),
				// which must find this device selected rather than push it a second time.
				if (!selectedDevices.some(d => d.devicePath === device.devicePath)) {
					selectedDevices.push({'deviceType' : "Usb", 'deviceSerialNo' : device.deviceSerialNo, 'deviceName' : device.deviceName, 'srcUrl': device.devicePath, 'devicePath': device.devicePath, 'manuallyAdded': device.manuallyAdded, 'deviceVid' : device.deviceVid, 'devicePid': device.devicePid, 'transportType': device.transportType || "Usb"})
				}
				setLocalCameraChecked(device.devicePath, true)

				model = modelData;
				checkedDevCnt = 0

				var children = usb_devices.concat(gmsl_devices, mipi_devices, pci_devices)
				for (var i = 0; i < children.length; i++) {
					if (children[i].checked === true) {
						checkedDevCnt = checkedDevCnt + 1;
					}
				}
				if(selectedDevCnt != checkedDevCnt){
					selectedDevCnt = checkedDevCnt
					selectedDeviceCount = checkedDevCnt

					if (wasAlreadyStreaming) {
						// Another USB camera is already streaming — open just
						// this one device; the already-open camera and its FBO
						// are never touched.
						prevController.addSelectedUsbDevice(selectedDevices[selectedDevices.length - 1])
					} else {
						fpsTimer.stop()
						prevController.setSelectedDeviceCount(checkedDevCnt, selectedDevType)
						opencamInitiated = true
						openCamTimer.start()
					}
				}
			}
        }
		refreshAudioAvailability()
    }
 
	// Handles unchecking a device: removes it from selectedDevices and the model,
	// removes manually added network devices via devController, and re-opens the
	// remaining cameras (or closes just this USB camera if others stay selected).
	// Audio entries go to deselectAudioDevice().
	function deSelectDevice(device) {
          if (device.type === "Audio") {
               deselectAudioDevice(device)
               return
          }

		var matchedIndex = -1
		setDeviceType (-1)
		let alreadyCheckedDev;
		if(selectedDevType == "Ethernet" || selectedDevType == "Wi-Fi"){
			alreadyCheckedDev = selectedDevices.find(d => d.deviceIP === device.deviceIP);
		} else{
			alreadyCheckedDev = selectedDevices.find(d => d.devicePath === device.devicePath);
		}
		var children;
		if(alreadyCheckedDev){
				if(device.type == "Wi-Fi"){				
					if(selectedDevType != "Wi-Fi"){
						selectedDevType = "Wi-Fi"
						logController.readJsonArrayFile();
					}
					var childrenList = modelData[0].children;
					for (var i = 0; i < childrenList.length; ++i) {
						if (childrenList[i].deviceIP === device.deviceIP) {
							matchedIndex = i;
							break;
						}
					}
					modelData[0].children[matchedIndex].checked = false
					
					selectedDevices = selectedDevices.filter(d => d.deviceIP !== device.deviceIP)
					manualUncheck = true
					onvifInitialize = false		

					// If manually added, remove from list entirely
					if (device.manuallyAdded) {
						devController.removeManuallyAddedDevice()
						// don't update model here — onDeviceRemoved will rebuild it
						// still need to count remaining checked for setSelectedDeviceCount
						checkedDevCnt = 0
						children = wifi_devices.filter(d => d.deviceIP !== device.deviceIP)
						for (var i = 0; i < children.length; i++) {
							if (children[i].checked === true) {
								checkedDevCnt = checkedDevCnt + 1;
							}
						}
						if(selectedDevCnt != checkedDevCnt){
							selectedDevCnt = checkedDevCnt
							selectedDeviceCount = checkedDevCnt
							fpsTimer.stop()
							prevController.setSelectedDeviceCount(checkedDevCnt, selectedDevType)
							opencamInitiated = true
							openCamTimer.start()
						}
						return  // ← let onDeviceRemoved handle the rest
					}			
					
					model = modelData;
					checkedDevCnt = 0
					children = model[0].children 
				} 
				else if(device.type == "Ethernet"){
					
					if(selectedDevType != "Ethernet"){
						selectedDevType = "Ethernet"
						logController.readControlJsonArrayFile();
					}
					var childrenList = modelData[1].children;
					for (var i = 0; i < childrenList.length; ++i) {
						if (childrenList[i].deviceIP === device.deviceIP) {
							matchedIndex = i;
							break;
						}
					}
					modelData[1].children[matchedIndex].checked = false
					
					selectedDevices = selectedDevices.filter(d => d.deviceIP !== device.deviceIP)
					manualUncheck = true

					// If manually added, remove from list entirely
					if (device.manuallyAdded) {
						devController.removeManuallyAddedDevice()
						// count remaining checked before model rebuild
						checkedDevCnt = 0
						children = ethernet_devices.filter(d => d.deviceIP !== device.deviceIP)
						for (var i = 0; i < children.length; i++) {
							if (children[i].checked === true) {
								checkedDevCnt = checkedDevCnt + 1;
							}
						}
						if(selectedDevCnt != checkedDevCnt){
							selectedDevCnt = checkedDevCnt
							selectedDeviceCount = checkedDevCnt
							fpsTimer.stop()
							prevController.setSelectedDeviceCount(checkedDevCnt, selectedDevType)
							opencamInitiated = true
							openCamTimer.start()
						}
						return  // ← let onDeviceRemoved handle the rest
					}
					
					model = modelData;
					checkedDevCnt = 0
					children = model[1].children
				}
				else if(device.type == "Usb"){
					if(selectedDevType != "Usb"){
						selectedDevType = "Usb"
						logController.readUsbControlJsonArrayFile();
						//logController.readUsbExtControlJsonArrayFile(device.deviceVid, device.devicePid);
					}
					setLocalCameraChecked(device.devicePath, false)
					
					selectedDevices = selectedDevices.filter(d => d.devicePath !== device.devicePath)
					manualUncheck = true
					
					model = modelData;
					checkedDevCnt = 0
					children = usb_devices.concat(gmsl_devices, mipi_devices, pci_devices)
				}
				for (var i = 0; i < children.length; i++) {
					if (children[i].checked === true) {
						checkedDevCnt = checkedDevCnt + 1;
					}
				}
				if(selectedDevCnt != checkedDevCnt){
					selectedDevCnt = checkedDevCnt
					selectedDeviceCount = checkedDevCnt

					if (device.type === "Usb" && checkedDevCnt > 0) {
						// At least one other USB camera stays selected — close
						// just this one device; the survivor(s) and their FBOs
						// are never touched.
						ecam212usbUvcextController.removeDevice(device.devicePath)
						prevController.removeSelectedUsbDevice(device.devicePath)
						setDeviceType(usbDev)
						closeRightUp = false
						handleCheckChangedUpRight(false)
						refreshAudioAvailability()
						return
					}

					fpsTimer.stop()
					prevController.setSelectedDeviceCount(checkedDevCnt, selectedDevType)

					opencamInitiated = true
					openCamTimer.start()
				}
			}
		refreshAudioAvailability()
    }
 
    // Stores the expanded state of the top-level or second-level tree node with
    // the given label in modelData.
    function setExpandedState(label, expanded){
        var indexes = findLabelIndex(modelData,label)
        if(indexes.length == 1){
            modelData[indexes[0]].expanded = expanded
        }else{
            modelData[indexes[0]].children[indexes[1]].expanded = expanded
        }
    }

    // Recursively searches the device tree for labelToFind and returns the index
    // path to it (e.g. [category, device]), or null if not found.
    function findLabelIndex(data, labelToFind) {
        // Iterate over the data
        for (let i = 0; i < data.length; i++) {
            const item = data[i];
            // If the current label matches the one we're looking for, return the path
            if (item.label === labelToFind) {
                return [i];
            }
            // If the current item has children, recurse through them
            if (item.children && item.children.length > 0) {
                const childResult = findLabelIndex(item.children, labelToFind);
                if (childResult) {
                    return [i, ...childResult]; // If found in children, return the full path
                }
            }
        }
        return null; // Return null if not found
    }

	Connections
	{
		target: window
		onWifiResolutionChanged: {
			isTimeout = true
			handleDeviceRemovedByIndex(0)
		}
	}

    Connections 
    {
        target: devController
        onUiControllerInitialized: {
			//devController.getDevices(); //wifi device enumeration	
        }
 
		onDeviceAdded: {
			if(device.type == "Wi-Fi"){
				
				let existingDevice = wifi_devices.find(d => d.deviceIP === device.deviceIP);
				if (!existingDevice) {
					wifi_devices.push({
						'label': device.deviceIP,
						'checked': false,
						'deviceIP': device.deviceIP,
						'devicePath': device.deviceIP,
						'deviceName' : device.deviceName,
						'manuallyAdded' : device.manuallyAdded,
						'type' : device.type
					});
					existingDevice = wifi_devices[wifi_devices.length - 1];
				}
				if( wifi_devices.length >= 1 && wifi_devices[0].checked !== true && selectedDevices.length == 0 && !manualUncheck) {
					
				if(selectedDevType != "Wi-Fi"){
					selectedDevType = "Wi-Fi"
					logController.readJsonArrayFile();
				}
					checkedDevCnt = checkedDevCnt + 1;
					if(selectedDevCnt != checkedDevCnt){
						selectedDevCnt = checkedDevCnt
						selectedDeviceCount = checkedDevCnt
						prevController.setSelectedDeviceCount(checkedDevCnt, selectedDevType)
					}	
					wifi_devices[0].checked = true;
							
					if(selectedDevices.length == 0){
						selectedDevices.push({'deviceType' : device.type, 'deviceIP': device.deviceIP, 'deviceName' : device.deviceName, 'srcUrl': "rtsp://" + device.deviceIP + "/video", 'manuallyAdded': device.manuallyAdded})
						prevController.setSelectedDevices(selectedDevices)
						setDeviceType(wifiDev);
						if(onvifInitialize == false){
							onvifInitialize = true
	  						wifiOnvifController.readJsonArrayFile()
							var onvif = wifiOnvifController.initializeOnvif(device.deviceName);
						}
					}
				}
				modelData[0].expanded = true
				// Always update model
				modelData[0].children = wifi_devices;
				model = modelData;	
				
			} 
			else if (device.type == "Ethernet"){
				
				let existingDevice = ethernet_devices.find(d => d.deviceIP === device.deviceIP);
				if (!existingDevice) {
					ethernet_devices.push({
						'label': device.deviceIP,
						'checked': false,
						'deviceIP': device.deviceIP,
						'deviceName' : device.deviceName,
						'devicePath': device.deviceIP,
						'manuallyAdded' : device.manuallyAdded,
						'type' : device.type
					});
					existingDevice = ethernet_devices[ethernet_devices.length - 1];
				}
					
				if((ethernet_devices.length >= 1 && ethernet_devices[0].checked !== true && selectedDevices.length == 0 && !manualUncheck && !isDeviceRemoved) || (ethernet_devices.length >= 1 && ethernet_devices[0].checked !== true && selectedDevices.length == 0 && !manualUncheck)) {
				
					if(selectedDevType != "Ethernet"){
						selectedDevType = "Ethernet"
						logController.readControlJsonArrayFile();
					}
					checkedDevCnt = checkedDevCnt + 1;
					if(selectedDevCnt != checkedDevCnt){
						selectedDevCnt = checkedDevCnt
						selectedDeviceCount = checkedDevCnt
						prevController.setSelectedDeviceCount(checkedDevCnt, selectedDevType)
					}	
					ethernet_devices[0].checked = true;
	
					if(selectedDevices.length == 0){
						var deviceDetails = routecamOnvifController.getStreamUrl(device.deviceIP)
						var srcUrl = deviceDetails.srcUrl
						selectedDevices.push({'deviceType' : device.type, 'deviceIP': device.deviceIP, 'deviceName' : device.deviceName, 'srcUrl': srcUrl, 'manuallyAdded': device.manuallyAdded})
						if(!opencamInitiated){
							prevController.setSelectedDevices(selectedDevices)
							setDeviceType(ethernetDev);
						}
					}
				} 
               			modelData[1].expanded = true
				// Always update model
				modelData[1].children = ethernet_devices;
				model = modelData;	
			}

			else if (device.type == "Usb"){
				addLocalCamera(device)
			}

               else if (device.type == "Audio"){
				let existingDevice = audio_devices.find(d => d.devicePath === device.devicePath);
				if (!existingDevice) {
					audio_devices.push({
						'label': device.deviceName,
						'checked': false,
						'devicePath': device.devicePath,
						'deviceName' : device.deviceName,
						'deviceVid': device.deviceVid,
						'devicePid': device.devicePid,
						'manuallyAdded': device.manuallyAdded,
						'type' : device.type,
						'enabled': isAudioAvailable()
					});
					existingDevice = audio_devices[audio_devices.length - 1];
				}

				refreshAudioAvailability()
					
				if (isAudioAvailable() && audio_devices.length >= 1 && audio_devices[0].checked !== true && selectedAudioDev == "" && !audioManuallyDeselected) {
					audio_devices[0].checked = true
					selectedAudioDev = audio_devices[0].deviceName
					selectedAudioDevicePath = audio_devices[0].devicePath
					prevController.setSelectedAudioDevice(audio_devices[0].devicePath, 0)  // index is always 0 here
				}

               	modelData[audioCategoryIndex()].expanded = true
				modelData[audioCategoryIndex()].children = audio_devices;
				model = modelData;	
			}
			refreshAudioAvailability()
		}

		onDeviceRemoved: {
			const { checkedRemoved, uncheckedRemoved } = getRemovedDevices(currentDeviceList);		
			if (checkedRemoved.length > 0) {
				isCheckedDevRemoved = true;
				// Pass all checked-removed devices instead of just one index
				handleDeviceRemoved(currentDeviceList, checkedRemoved);
			}
			if (uncheckedRemoved.length > 0) {
				handleUncheckedDeviceRemoval(currentDeviceList);
			}
		}
		
        onDeviceJsonArrayRead: {
            const rows = sidebarRows(jsonArray)
            modelData = rows;
            DevicesJS.updateModelData(rows); 
        }
    }
	Connections{
		target: prevController
		onDevicesUpdated: {
				if (devStat === 1) { // Disconnected
					if(manualUncheck == false && !isCheckedDevRemoved && !isTimeout){
						isTimeout = true
						isCameraOpened = false
						
						handleDeviceRemovedByIndex(index)
					}
				}
			}
			onCameraOpened: {	
				if( selectedDevType == "Wi-Fi" && !onvifInitialize){
					
					manualUncheck = false
					setDeviceType(wifiDev)
				    wifiOnvifController.readJsonArrayFile()				
					var onvif = wifiOnvifController.initializeOnvif(selectedDevices[0].deviceName);
					onvifInitialize = true
				}  else if(selectedDevType == "Ethernet"){
					manualUncheck = false
					onvifInitialize = false
					if(!isControlUpdated){
						setDeviceType(ethernetDev)
					} else{
						isControlUpdated = false
					}
				} else if(selectedDevType == "Usb"){
					onvifInitialize = false
					manualUncheck = false
					setDeviceType(usbDev)
				}
			}
    }

	Connections{
		target: window
		onUpdateProperty: {
			if(manualUncheck == false && !isCheckedDevRemoved && !isTimeout){
				isCameraOpened = false
				isTimeout = true
				isControlUpdated = true
				handleDeviceRemovedByIndex(index)
			}
		}
    }
	

	// Returns the checked state of the first device of the current type that is
	// missing from currentDeviceList (i.e. was removed); false if none removed.
	function isRemovedDeviceChecked(currentDeviceList) {
		if (selectedDevType == "Wi-Fi" ){
			const removedDevice = wifi_devices.find(dev =>
				!currentDeviceList.some(currentDev => currentDev.deviceIP === dev.deviceIP)
			);

			if (removedDevice) {
				return removedDevice.checked;
			}		
		} else if(selectedDevType == "Ethernet"){
			const removedDevice = ethernet_devices.find(dev =>
				!currentDeviceList.some(currentDev => currentDev.deviceName === dev.deviceName)
			);

			if (removedDevice) {
				return removedDevice.checked;
			}
		} else if(selectedDevType == "Usb"){
			const removedDevice = usb_devices.concat(gmsl_devices, mipi_devices, pci_devices).find(dev =>
				!currentDeviceList.some(currentDev => currentDev.devicePath === dev.devicePath)
			);

			if (removedDevice) {
				return removedDevice.checked;
			}
		}

		// No device removed
		return false;
	}

	// Compares every Wi-Fi/Ethernet/USB/Audio device list with currentDeviceList
	// and returns { checkedRemoved, uncheckedRemoved } entries ({device, index,
	// type}) for devices that disappeared, split by whether they were checked.
	function getRemovedDevices(currentDeviceList) {
	    const categories = [
	        { devList: wifi_devices,     matchKey: "deviceName",   type: "Wi-Fi"    },
	        { devList: ethernet_devices, matchKey: "deviceName", type: "Ethernet" },
	        { devList: usb_devices,      matchKey: "devicePath", type: "Usb"      },
	        { devList: gmsl_devices,     matchKey: "devicePath", type: "GMSL"     },
	        { devList: mipi_devices,     matchKey: "devicePath", type: "MIPI"     },
	        { devList: pci_devices,      matchKey: "devicePath", type: "PCI"      },
             { devList: audio_devices,    matchKey: "devicePath", type: "Audio"   },
	    ];

	    let checkedRemoved = [];
	    let uncheckedRemoved = [];

	    categories.forEach(({ devList, matchKey, type }) => {
	        devList.forEach((dev, index) => {
	            const stillExists = currentDeviceList.some(
	                currentDev => currentDev[matchKey] === dev[matchKey]
	            );
	            if (!stillExists) {
	                const entry = { device: dev, index: index, type: type };
	                if (dev.checked) {
	                    checkedRemoved.push(entry);
	                } else {
	                    uncheckedRemoved.push(entry);
	                }
	            }
	        });
	    });

	    return { checkedRemoved, uncheckedRemoved };
	}

	// Returns the index (in the current type's device list) of the first device
	// missing from currentDeviceList, or -1 if none was removed.
	function getRemovedDeviceIndex(currentDeviceList) {
		var removedIndex = -1;
		if (selectedDevType == "Wi-Fi" ){
			removedIndex = wifi_devices.findIndex(dev =>
				!currentDeviceList.some(currentDev => currentDev.deviceIP === dev.deviceIP)
			);
		}
		else if(selectedDevType == "Ethernet"){
			removedIndex = ethernet_devices.findIndex(dev =>
				!currentDeviceList.some(currentDev => currentDev.deviceName === dev.deviceName)
			);
		}
		else if(selectedDevType == "Usb"){
			removedIndex = usb_devices.concat(gmsl_devices, mipi_devices, pci_devices).findIndex(dev =>
				!currentDeviceList.some(currentDev => currentDev.devicePath === dev.devicePath)
			);
		}

		if (removedIndex !== -1) {
			return removedIndex;
		}

		// No device removed
		return -1;
	}

	// Drops devices that are no longer present (and were not selected) from the
	// Wi-Fi, Ethernet, USB and Audio lists and rebuilds the tree nodes. For audio,
	// auto-selects the first remaining device if the selected one disappeared.
	function handleUncheckedDeviceRemoval(currentDeviceList) {

		// --- Wi-Fi ---
		if (wifi_devices.length > 0) {
			const removedDevices = wifi_devices.filter(dev =>
				!currentDeviceList.some(currentDev => currentDev.deviceName === dev.deviceName)
			);

			if (removedDevices.length > 0) {
				// Remove only the devices no longer present
				wifi_devices = wifi_devices.filter(dev =>
					currentDeviceList.some(currentDev => currentDev.deviceIP === dev.deviceIP)
				);

				if (wifi_devices.length === 0) {
					modelData[0].children = [{ label: "No devices found", noDevices: true }];
					if (selectedDevType == "Wi-Fi") setDeviceType(-1);
				} else {
					modelData[0].children = wifi_devices.map(dev => ({
						label: dev.deviceIP,
						deviceIP: dev.deviceIP,
						deviceName: dev.deviceName || dev.deviceIP,
						manuallyAdded: dev.manuallyAdded,
						checked: selectedDevices.some(sd => sd.deviceIP === dev.deviceIP),
						type: "Wi-Fi"
					}));
				}
				model = modelData;
			}
		}

		// --- Ethernet --- (unchanged)
		if (ethernet_devices.length > 0) {
			const removedDevices = ethernet_devices.filter(dev =>
				!currentDeviceList.some(currentDev => currentDev.deviceName === dev.deviceName)
			);
			if (removedDevices.length > 0) {
				ethernet_devices = ethernet_devices.filter(dev =>
					currentDeviceList.some(currentDev => currentDev.deviceName === dev.deviceName)
				);
				if (ethernet_devices.length === 0) {
					modelData[1].children = [{ label: "No devices found", noDevices: true }];
					if (selectedDevType == "Ethernet") setDeviceType(-1);
				} else {
					modelData[1].children = ethernet_devices.map(dev => ({
						label: dev.deviceIP,
						deviceIP: dev.deviceName,
						deviceName: dev.deviceName || dev.deviceIP,
						checked: selectedDevices.some(sd => sd.deviceName === dev.deviceName),
						type: "Ethernet"
					}));
				}
				model = modelData;
			}
		}

		// --- USB, GMSL and MIPI cameras ---
		localCameraTypes.forEach(function(transportType) {
			const devices = localCameraList(transportType)
			const survivors = devices.filter(dev => currentDeviceList.some(
				currentDev => currentDev.devicePath === dev.devicePath
			))
			if (survivors.length !== devices.length) {
				setLocalCameraList(transportType, survivors)
				updateLocalCameraRow(transportType, false)
				if (selectedDevType === "Usb" && selectedDevices.length === 0 &&
					usb_devices.length + gmsl_devices.length + mipi_devices.length + pci_devices.length === 0) {
					setDeviceType(-1)
					selectedDeviceCount = selectedDevCnt = checkedDevCnt = 0
					fpsTimer.stop()
					prevController.setSelectedDeviceCount(0, "Usb")
				}
			}
		})

          // --- Audio ---
          if (audio_devices.length > 0) {
          const removedAudio = audio_devices.filter(dev =>
               !currentDeviceList.some(currentDev => currentDev.devicePath === dev.devicePath)
          )
          if (removedAudio.length > 0) {
               audio_devices = audio_devices.filter(dev =>
                    currentDeviceList.some(currentDev => currentDev.devicePath === dev.devicePath)
               )
			window.audioDeviceAvailable = audio_devices.length > 0

               if (audio_devices.length === 0) {
                    modelData[audioCategoryIndex()].children = [{ label: "No devices found", noDevices: true }]
                    selectedAudioDev = ""
                    selectedAudioDevicePath = ""
                    prevController.setSelectedAudioDevice("", -1)
               } else {
                    // If the selected audio device was removed, auto-select first remaining
                    const selectedStillExists = audio_devices.some(
                         d => d.devicePath === selectedAudioDevicePath
                    )
                    if (isAudioAvailable() && !selectedStillExists && audio_devices.length > 0) {
                         if (selectedAudioDevicePath !== "" &&
                             selectedAudioDevicePath !== audio_devices[0].devicePath)
                         {
                              prevController.setSelectedAudioDevice("", -1)
                         }
                         audio_devices[0].checked = true
                         selectedAudioDev = audio_devices[0].deviceName
                         selectedAudioDevicePath = audio_devices[0].devicePath
                         prevController.setSelectedAudioDevice(audio_devices[0].devicePath , 0)
                    }
                    refreshAudioAvailability()
                    modelData[audioCategoryIndex()].children = audio_devices
               }
               model = modelData
          }
          }
	}

	// Handles removal of checked (in-use) devices reported by onDeviceRemoved:
	// clears/filters the affected Wi-Fi, Ethernet, USB and Audio selections,
	// closes removed USB cameras via prevController and updates the tree. On the
	// timeout path it simply re-applies the selected device count and reopens.
	function handleDeviceRemoved(currentDeviceList, checkedRemoved) {
		if (checkedRemoved.length === 0) return;

		isDeviceRemoved = true;

		if (!isTimeout) {

			// --- Wi-Fi ---
			if (selectedDevType == "Wi-Fi") {
				const hasCheckedWifi = checkedRemoved.some(r => r.device.type === "Wi-Fi");
				if (hasCheckedWifi && wifi_devices.length > 0) {
					wifi_devices = [];
					selectedDeviceCount = 0;
					var res = prevController.setSelectedDeviceCount(0, selectedDevType);
					if (res == 1) {
						selectedDevCnt = 0;
						checkedDevCnt = 0;
						onvifInitialize = false;
					}
					selectedDevices = [];
					selectedDev = [];
					if (!manualUncheck) {
						setDeviceType(-1);
					} else {
						manualUncheck = false;
						onvifInitialize = false;
					}
					modelData[0].children = [{ label: "No devices found", noDevices: true }];
					setDeviceType(-1)
					model = modelData;
				}
			}

			// --- Ethernet ---
			if (ethernet_devices.length > 0) {
				const ethernetRemoved = checkedRemoved.filter(r => r.device.type === "Ethernet");

				if (ethernetRemoved.length > 0) {
					const removedNames = new Set(ethernetRemoved.map(r => r.device.deviceName));

					const affectsSelection = ethernetRemoved.some(
						r => r.device.checked === true  // was it the selected/checked device?
					);

					// Remove all checked-removed devices at once
					ethernet_devices = ethernet_devices.filter(
						dev => !removedNames.has(dev.deviceName)
					);

					if (ethernet_devices.length === 0) {
						modelData[1].children = [{ label: "No devices found", noDevices: true }];
						setDeviceType(-1);
					} else {
						modelData[1].children = ethernet_devices.map(dev => ({
							label: dev.deviceIP,
							deviceIP: dev.deviceIP,
							deviceName: dev.deviceName || dev.deviceIP,
							manuallyAdded: dev.manuallyAdded,
							checked: selectedDevices.some(sd => sd.deviceIP === dev.deviceIP),
							type: "Ethernet"
						}));
					}
					model = modelData;

					if (affectsSelection) {
					
						selectedDevices = selectedDevices.filter(
							sd => !removedNames.has(sd.deviceName)
						);
						selectedDeviceCount = selectedDevices.length;
						const res = prevController.setSelectedDeviceCount(selectedDeviceCount, selectedDevType);
						if (res == 1) {
							selectedDevCnt = selectedDeviceCount;
							checkedDevCnt = selectedDeviceCount;
							opencamInitiated = true;
							openCamTimer.start();
						}
					}
				}
			}

			// --- USB, GMSL and MIPI cameras ---
			const localRemoved = checkedRemoved.filter(r =>
				localCameraTypes.indexOf(r.type) !== -1)
			if (localRemoved.length > 0) {
				const removedPaths = new Set(localRemoved.map(r => r.device.devicePath))
				const removedSelected = selectedDevices.filter(sd => removedPaths.has(sd.devicePath))
				selectedDevices = selectedDevices.filter(sd => !removedPaths.has(sd.devicePath));
				localCameraTypes.forEach(function(transportType) {
					setLocalCameraList(transportType, localCameraList(transportType).filter(
						dev => !removedPaths.has(dev.devicePath)))
					updateLocalCameraRow(transportType, false)
				})
				removedSelected.forEach(dev => {
					ecam212usbUvcextController.removeDevice(dev.devicePath)
					prevController.removeSelectedUsbDevice(dev.devicePath)
				})
				const remainingLocalCount = usb_devices.length + gmsl_devices.length + mipi_devices.length + pci_devices.length
				if (remainingLocalCount === 0) {
					setDeviceType(-1)
					selectedDeviceCount = selectedDevCnt = checkedDevCnt = 0
					fpsTimer.stop()
					prevController.setSelectedDeviceCount(0, "Usb")
					isDeviceRemoved = false
					opencamInitiated = false
					isCheckedDevRemoved = false
					isTimeout = false
				} else {
					const selectedPaths = new Set(selectedDevices.map(sd => sd.devicePath));
					localCameraTypes.forEach(function(transportType) {
						setLocalCameraList(transportType, localCameraList(transportType).map(function(dev) {
							dev.checked = selectedPaths.has(dev.devicePath)
							return dev
						}))
						updateLocalCameraRow(transportType, false)
					})
					selectedDeviceCount = selectedDevices.length
					selectedDevCnt = selectedDeviceCount
					checkedDevCnt = selectedDeviceCount
					if (selectedDeviceCount > 0) {
						setDeviceType(usbDev)
						closeRightUp = false
						handleCheckChangedUpRight(false)
					} else {
						setDeviceType(-1)
						fpsTimer.stop()
						prevController.setSelectedDeviceCount(0, "Usb")
					}
					isDeviceRemoved = false
					isCheckedDevRemoved = false
					refreshAudioAvailability()
				}
				model = modelData
			}

			// --- Audio ---
			if (audio_devices.length > 0) {
				const audioRemoved = checkedRemoved.filter(r => r.device.type === "Audio")

				if (audioRemoved.length > 0) {
					const removedPaths = new Set(audioRemoved.map(r => r.device.devicePath))

					audio_devices = audio_devices.filter(
						dev => !removedPaths.has(dev.devicePath)
					)
					window.audioDeviceAvailable = audio_devices.length > 0

					if (audio_devices.length === 0) {
						modelData[audioCategoryIndex()].children = [{ label: "No devices found", noDevices: true }]
						selectedAudioDev = ""
						selectedAudioDevicePath = ""
						prevController.setSelectedAudioDevice("", -1)
					} else {
						// Auto-select first remaining audio device if selected one was removed
						const selectedStillExists = audio_devices.some(
								d => d.devicePath === selectedAudioDevicePath
						)
						if (isAudioAvailable() && !selectedStillExists) {
								if (selectedAudioDevicePath !== "" &&
									selectedAudioDevicePath !== audio_devices[0].devicePath)
								{
									prevController.setSelectedAudioDevice("", -1)
								}
								audio_devices[0].checked = true
								selectedAudioDev = audio_devices[0].deviceName
								selectedAudioDevicePath = audio_devices[0].devicePath
								prevController.setSelectedAudioDevice(audio_devices[0].devicePath, 0)
						}
						refreshAudioAvailability()
						modelData[audioCategoryIndex()].children = audio_devices
					}
					model = modelData
				}
			}

		} else {
			// Timeout path — unchanged
			fpsTimer.stop();
			const res = prevController.setSelectedDeviceCount(selectedDeviceCount, selectedDevType);
			if (res == 1) {
				opencamInitiated = true;
				openCamTimer.start();
			}
		}
	}

	// Handles a device disconnect by list index (streaming timeout, Wi-Fi
	// resolution change or property update): resets Wi-Fi selection, removes the
	// Ethernet/USB entry, closes or reopens cameras as needed and, for USB,
	// auto-selects the first remaining camera when the selection was lost.
	function handleDeviceRemovedByIndex(index){
		if(index != -1){
			isDeviceRemoved = true
			if(!isTimeout){
				if(selectedDevType == "Wi-Fi" && !manualUncheck){
					if (wifi_devices.length > 0) {    
						// Remove the device from the list
						wifi_devices = []
						selectedDeviceCount = 0
						var res = prevController.setSelectedDeviceCount(0, selectedDevType);
						if (res == 1) {
							selectedDevCnt = 0
							checkedDevCnt = 0
							onvifInitialize = false
						}
	
						selectedDevices = []
						selectedDev = []
						
						setDeviceType(-1);
					}
 
					// If no devices remain, update the model with "No devices" UI state
					if (wifi_devices.length === 0) {
						// Reset device-related variables
						modelData[0].children = [
							{
								label: "No devices found",
								noDevices: true
							}
						];
						
						setDeviceType(-1);
						model = modelData;
					}
				} else if(selectedDevType == "Wi-Fi" && manualUncheck){
					if (wifi_devices.length > 0) {  
						// Remove the device from the list
						wifi_devices = []
						// If no devices remain, update the model with "No devices" UI state
						if (wifi_devices.length === 0) {

								setDeviceType(-1);
								modelData[0].children = [
									{
										label: "No devices found",
										noDevices: true
									}
								];
								model = modelData;
								manualUncheck = false
								onvifInitialize = false
						}
					}
				}
				if (ethernet_devices.length > 0) {
					// The device that got removed (based on index)
					const removedDevice = ethernet_devices[index];

					if (removedDevice) {

						// Check if it was in selectedDevices
						const affectsSelection = selectedDevices.some(sd => sd.deviceIP === removedDevice.deviceIP);

						// Remove the device from ethernet_devices
						ethernet_devices.splice(index, 1);

						// Update modelData[1] children
						if (ethernet_devices.length === 0) {
							modelData[1].children = [
								{ label: "No devices found", noDevices: true }
							];
							
							setDeviceType(-1);
						} else {
							modelData[1].children = ethernet_devices.map(dev => ({
								label: dev.deviceIP,
								deviceIP: dev.deviceIP,
								deviceName: dev.deviceName || dev.deviceIP,
								manuallyAdded: dev.manuallyAdded,
								checked: selectedDevices.some(sd => sd.deviceIP === dev.deviceIP),
								type: "Ethernet"
							}));
						}

						model = modelData;

						// If removed device was selected, update selection info
						if (affectsSelection) {
							selectedDevices = selectedDevices.filter(sd => sd.deviceIP !== removedDevice.deviceIP);

							selectedDeviceCount = selectedDevices.length;

							const res = prevController.setSelectedDeviceCount(selectedDeviceCount, selectedDevType);
							if (res == 1) {
								selectedDevCnt = selectedDeviceCount;
								checkedDevCnt = selectedDeviceCount;
								opencamInitiated = true
								
								openCamTimer.start();
							}
						}
					}
				}
				if (selectedDevType === "Usb") {
				const removedSelection = selectedDevices[index] || selectedDevices[0]
				if (removedSelection && removedSelection.devicePath) {
					const removedPath = removedSelection.devicePath
					const affectsSelection = selectedDevices.some(sd => sd.devicePath === removedPath)
					const canRemoveIncrementally = affectsSelection && selectedDevices.length > 1;
					localCameraTypes.forEach(function(transportType) {
						setLocalCameraList(transportType, localCameraList(transportType).filter(
							dev => dev.devicePath !== removedPath))
						updateLocalCameraRow(transportType, false)
					})
					if (canRemoveIncrementally) {
						selectedDevices = selectedDevices.filter(dev => dev.devicePath !== removedPath)
						selectedDeviceCount = selectedDevCnt = checkedDevCnt = selectedDevices.length
						ecam212usbUvcextController.removeDevice(removedPath)
						prevController.removeSelectedUsbDevice(removedPath)
						setDeviceType(usbDev)
						closeRightUp = false
						handleCheckChangedUpRight(false)
						refreshAudioAvailability()
					} else if (affectsSelection) {
						selectedDevices = []
						selectedDeviceCount = selectedDevCnt = checkedDevCnt = 0
						fpsTimer.stop()
						prevController.setSelectedDeviceCount(0, "Usb")
						autoSelectFirstUsbDevice()
					}
					model = modelData
				}
				}

			} else {
				// isTimeout path
				fpsTimer.stop()

				if (selectedDevType === "Usb") {
					// Reset and reconnect to first device
					selectedDevices = []
					selectedDeviceCount = 0
					selectedDevCnt = 0
					checkedDevCnt = 0;
					localCameraTypes.forEach(function(transportType) {
						setLocalCameraList(transportType, localCameraList(transportType).map(function(dev) {
							dev.checked = false
							return dev
						}))
						updateLocalCameraRow(transportType, false)
					})
					prevController.setSelectedDeviceCount(0, selectedDevType)
					isTimeout = false
					// Small delay then auto-select
					autoSelectFirstUsbDevice()
				} else {
					// Ethernet/WiFi timeout path unchanged
					if (selectedDevType === "Ethernet") {
						const hasManualDevice = selectedDevices.some(sd => sd.manuallyAdded === true)
						if (hasManualDevice) {
							isTimeout = false
							devController.removeManuallyAddedDevice()
						}
					} else if (selectedDevType === "Wi-Fi") {
						const hasManualDevice = selectedDevices.some(sd => sd.manuallyAdded === true)
						if (hasManualDevice) {
							isTimeout = false
							devController.removeManuallyAddedDevice()
						}
					}
					const res = prevController.setSelectedDeviceCount(selectedDeviceCount, selectedDevType)
					if (res == 1) {
						opencamInitiated = true
						openCamTimer.start()
					}
				}
			}
		}
		refreshAudioAvailability()
	}

     // Selects an audio device (single selection): unchecks any other one, stores
     // its name/path, clears audioManuallyDeselected and passes it to
     // prevController.setSelectedAudioDevice(). No-op if audio is unavailable.
     function selectAudioDevice(device) {
		if (!isAudioAvailable()) {
			refreshAudioAvailability()
			return
		}

		for (var i = 0; i < audio_devices.length; i++) {
			if (audio_devices[i].checked === true &&
				audio_devices[i].devicePath !== device.devicePath)
			{
				audio_devices[i].checked = false
			}
		}

		var matchedIndex = -1
		for (var i = 0; i < audio_devices.length; i++) {
			if (audio_devices[i].devicePath === device.devicePath) {
				matchedIndex = i
				break
			}
		}

		if (matchedIndex === -1) { return }

		if (selectedAudioDevicePath !== "" &&
			selectedAudioDevicePath !== device.devicePath)
		{
			prevController.setSelectedAudioDevice("", -1)
		}

		audio_devices[matchedIndex].checked = true
		selectedAudioDev = device.deviceName
		selectedAudioDevicePath = device.devicePath

		// ── User explicitly selected — clear the manual deselect flag ────────
		audioManuallyDeselected = false

		modelData[audioCategoryIndex()].children = audio_devices
		model = modelData

		prevController.setSelectedAudioDevice(device.devicePath, matchedIndex)
	}

     // Unchecks an audio device, clears the selected audio device (also in the
     // controller) and sets audioManuallyDeselected to suppress auto-selection.
     function deselectAudioDevice(device) {
		var matchedIndex = -1
		for (var i = 0; i < audio_devices.length; i++) {
			if (audio_devices[i].devicePath === device.devicePath) {
				matchedIndex = i
				break
			}
		}

		if (matchedIndex === -1) { return }

		audio_devices[matchedIndex].checked = false
		if (selectedAudioDevicePath === device.devicePath ||
			selectedAudioDevicePath === "")
		{
			selectedAudioDev = ""
			selectedAudioDevicePath = ""
			prevController.setSelectedAudioDevice("", -1)
		}

		// ── Mark that the user explicitly deselected — suppress auto-select ──
		audioManuallyDeselected = true

		modelData[audioCategoryIndex()].children = audio_devices
		model = modelData
	}

	// Automatically selects and opens the first USB camera when nothing is
	// selected: marks it checked, rebuilds the USB node, fills selectedDevices and
	// starts openCamTimer after setting the device count in prevController.
	function autoSelectFirstUsbDevice() {
		if (selectedDevices.length > 0) return
		const groups = [
			{ type: "GMSL", devices: gmsl_devices },
			{ type: "MIPI", devices: mipi_devices },
			{ type: "PCI", devices: pci_devices },
			{ type: "Usb", devices: usb_devices }
		]
		const group = groups.find(item => item.devices.length > 0)
		if (!group || !group.devices[0] || group.devices[0].noDevices) return
		const firstDev = group.devices[0]
		firstDev.checked = true
		selectedDevType = "Usb"
		logController.readUsbControlJsonArrayFile()
		selectedDevices = [{
			deviceType: "Usb",
			deviceName: firstDev.deviceName,
			deviceSerialNo: firstDev.deviceSerialNo,
			srcUrl: firstDev.devicePath,
			devicePath: firstDev.devicePath,
			manuallyAdded: firstDev.manuallyAdded,
			deviceVid: firstDev.deviceVid,
			devicePid: firstDev.devicePid,
			transportType: firstDev.transportType || group.type
		}]
		updateLocalCameraRow(group.type, false)
		checkedDevCnt = selectedDevCnt = selectedDeviceCount = 1
		fpsTimer.stop()
		prevController.setSelectedDeviceCount(1, selectedDevType)
		prevController.setSelectedDevices(selectedDevices)
		setDeviceType(usbDev)
		opencamInitiated = true
		openCamTimer.start()
	}

}
