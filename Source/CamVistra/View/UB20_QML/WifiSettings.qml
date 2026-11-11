import QtQuick 2.12
import QtQuick.Controls 2.12
import "../JS/Wifi.js" as ModelData

WifiAccordion {
    id: wifiAcc
    //anchors.fill: wifiInnerRectangle
    anchors.margins: 10
    width: wifiInnerRectangle.width - 20
	height : implicitHeight

    property var wifiProperty  
	wifiProperty: ModelData.getModelData()
	property var setAPData
	property var setSTAData
	property var setServerData
    property var setCamConfigdata
	property var localWifiprop
	property var cloudProvider
	property var azureSharedKeyFileName : ""
	property var saJsonFileData : ""
	property var azureSharedKey : ""
	property bool isHmacAndSaAvailable : false
	property bool isAzureConfigAvailable : false
	property bool isSASTokenAvailable : false
	property bool isSAS : false
	property bool isOEM : false
	property var capabilities

	property var sharedKey: ""
	property var sasToken: ""
	
	property int heightVal : 5 * 0.052 * screenHeight
	model: wifiProperty
	Connections{
	target: wifiOnvifController
		//newly added to load json
		onJsonArrayRead: {
            wifiProperty = jsonArray;
            ModelData.updateModelData(jsonArray);           
        }
		onSaJsonFileContent: {
		  saJsonFileData = JSON.stringify(jsonArray)
		}
		onAzureJsonFileRead: {
			azureSharedKey = sharedKey
			// Get changed fields
			var changedFields = ModelData.updateSharedKeyJsonFileName(fileName);
    
			// Emit signals for changed fields
			if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i];
            
					if (change.hasOwnProperty('text')) {
						wifiAcc.fieldTextChanged(change.id, change.text);
					}
				}
			}
			azureSharedKeyFileName = fileName
		}

		 onOnvifInitialized: {
		//Call All get API to fetch the Data from the Camera
			fetchCapabilities();
			ModelData.setCapabilities(capabilities)
			fetchDeviceInformation();
			fetchAPConfigData();
			fetchSTAConfigData();
			fetchServerConfigData();
			fetchTimerConfigData();
			fetchCameraSettingsConfiguration()
			if(capabilities.BatteryStatus){ 
				fetchBatteryInfo()
			}

			if(isOEM){
				fetchVideoProperties()
				fetchSDCardInfo()
				fetchVidRecConfiguration()
				fetchVidRecStatus()
				if(capabilities.wbMode){
					fetchWhiteBalanceSettings()
				}
				ModelData.setOEMPropertiesVisibility()
				heightVal = 11 * 0.052 * screenHeight
			}
			wifiProperty = ModelData.getModelData()
			logController.readJsonTooltipArrayFile()
        }
		onJsonFileReadFailed: {
			setTextMessage(msg)
		}

		onAvailableResolutionsList: {
			ModelData.updateAvailableResolutions(list)
		}

		onCurrentResolutionReceived: {
			ModelData.updateCurrentResolution(currentResolution)
		}

		onDefaultResolution: {
			isResolutionChanged = true
			var changedFields = ModelData.setDefaultResolution(resolution);

			window.wifiResolutionChanged()
			// Emit targeted signals for only the changed fields
			if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i]

					if (change.hasOwnProperty('selected')) {
						wifiAcc.fieldValueChanged(change.id, change.selected);
					}

					if (change.hasOwnProperty('options')) {
						// Notify specific field about options change
						wifiAcc.fieldOptionsChanged(change.id, change.options, change.selected);
					}

				}
			}
		}

		onDefaultUiValues: {
			var changedFields = ModelData.setUiDefaultValues(values)
			 if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i];
                
					if (change.hasOwnProperty('enabled')) {
						// Notify specific field about enabled state change
						wifiAcc.fieldChanged(change.id, change.enabled);
					}
                
					if (change.hasOwnProperty('options')) {
						// Notify specific field about options change
						wifiAcc.fieldOptionsChanged(change.id, change.options, change.selected);
					}

					 if (change.hasOwnProperty('value')) {
						// Notify specific field about options change
						wifiAcc.fieldValueChanged(change.id, change.currentValue);
					}

					if (change.hasOwnProperty('selected')) {
						// Notify about value change for label update
						wifiAcc.fieldValueChanged(change.id, change.selected);
					}
				}
			}
		}

		onSdCardEjected: {
			var changedFields = ModelData.sdCardEjected()

			if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i];					
					if (change.hasOwnProperty('visible')) {
						wifiAcc.fieldVisibilityChanged(change.id, change.visible);
					}
				}
			}

		}
			
		onSdCardInfo: {
			var changedFields = ModelData.updateSDCardinfo(message)
			if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i];					
					if (change.hasOwnProperty('text')) {
						wifiAcc.fieldLabelTextChanged(change.id, change.text);
					}
				}
			}
		}
	}
	Connections{
		target : fileDialog
		onSelectedFileName: {
			cloudProvider = ModelData.getCloudProvider()
			if( isHmacAndSaAvailable || (isAzureConfigAvailable && cloudProvider == "Google" )){
				handleSAJsonFileChange(filename, filePath)
			} else{
				handleAzureJsonFileRead(filename, filePath, isSAS)
			}
		}
	}
	Connections{
		target: logController
		onTooltipJsonArrayRead: {
			wifiProperty = ModelData.setTooltip(jsonTooltipArray)
		}
	}


	Connections {
		target : prevController
		onCameraClosed: {
			if(selectedDevices.length == 0){
				if(window.isOnvifRecording){
					window.isOnvifRecording = false
					window.stopVideoRecording()
				}
				if (!isResolutionChanged){
					wifiFlickable.contentWidth = 0
					saJsonFileData = ""
					azureSharedKey = ""
					azureSharedKeyFileName = ""
					if (isOEM){
						heightVal =  11 * 0.052 * screenHeight
					} else{
						heightVal =  5 * 0.052 * screenHeight
					}
					isHmacAndSaAvailable = false
					isAzureConfigAvailable = false
					isSASTokenAvailable = false
					setAPData = {};
					setSTAData = {};
					setServerData = {};
					setCamConfigdata = {};
					cloudProvider = ""
					azureSharedKeyFileName = ""
					isOEM = false
					sharedKey= ""
					sasToken = ""
					isSAS = false
					ModelData.setIsHmacAndSaAvailable(false)
				} else{
					isResolutionChanged = false
				}
			}
		}
	}
	// Reads the selected service-account JSON via wifiOnvifController and shows
	// its file name in the Cloud > SA mode "fileName" field (emits fieldTextChanged).
	//Function to set the name of the loaded json into the fileName field
	function handleSAJsonFileChange(filename, filePath) {
		wifiOnvifController.readSAJsonArrayFile(filePath);
		for (const item of wifiProperty) {
			if (item.label === "Device Configuration") {
				const serverConfig = item.children.find(c => c.label === "Server Configuration");
				if (!serverConfig) continue;

				const cloudMode = serverConfig.children.find(c => c.label === "Cloud");
				if (!cloudMode) continue;

				const saMode = cloudMode.children.find(c => c.id === "saMode");
				if (!saMode) continue;

				const fileNameField = saMode.children.find(f => f.id === "fileName");
				if (fileNameField) {
					fileNameField.text = filename;
					// Emit the signal to update UI
					wifiAcc.fieldTextChanged("fileName", filename);
					return;
				}
			}
		}
	}

	// Passes the selected Azure key JSON file to wifiOnvifController, which reads
	// it as a SAS token (isSAS true) or a shared key.
	//Function to set the name of the loaded json into the fileName field
	function handleAzureJsonFileRead(filename, filePath, isSAS) {
		wifiOnvifController.readAzureJsonFile(filename, filePath, isSAS);
	}

	// Saves the current Azure shared key to a file via wifiOnvifController, or
	// shows an error message if no shared key is set.
	function downloadSharedKeyFile(){
		if(sharedKey == ""){
			setTextMessage("Shared Key is null or empty")
		} else{
			wifiOnvifController.downloadSharedKeyFile( sharedKey)
		}
	}

	// Saves the current Azure SAS token to a file via wifiOnvifController, or
	// shows an error message if no SAS token is set.
	function downloadSasKeyFile(){
		if(sasToken == ""){
			setTextMessage("SAS Token is null or empty")
		} else{
			wifiOnvifController.downloadSasKeyFile(isSAS, sasToken)
		}
	}
	
	//API to fetch the Device Information 
	function fetchDeviceInformation(){
		var deviceInfo = wifiOnvifController.getDeviceInformationMap();
		ModelData.getDeviceInformation(deviceInfo);
	}

	// Reads the camera's SD card information via ONVIF and loads it into ModelData.
	function fetchSDCardInfo(){
		var sdCardInfo = wifiOnvifController.getSDCardInfoMap();
		ModelData.updateSDCardInfo(sdCardInfo);
	}

	// Reads the camera's video recording configuration via ONVIF and loads it
	// into ModelData.
	function fetchVidRecConfiguration() {
		var vidRecConfigData = wifiOnvifController.getVidRecConfigMap();
		ModelData.updateVidRecConfig(vidRecConfigData);		
	}

	// Reads the camera's recording status via ONVIF; if "true", marks ONVIF
	// recording active and starts local video recording, then updates ModelData.
	function fetchVidRecStatus(){
		var vidRecStatus = wifiOnvifController.getRecordingStatus();
		if (vidRecStatus == "true"){
			window.isOnvifRecording = true
			window.startVideoRecording(true)
		} else if ( vidRecStatus == "false"){
			window.isOnvifRecording = false
		}
		ModelData.handleVidRecStatus(vidRecStatus)
	}

	// Reads the camera's white balance value via ONVIF and loads it into ModelData.
	function fetchWhiteBalanceSettings() {
		var wbValue = wifiOnvifController.getWhiteBalance();
		ModelData.updateWBValue(wbValue)
	}

	// Reads the camera capabilities map via ONVIF and sets the OEM, Azure,
	// SAS-token and HMAC+ServiceAccount availability flags used by the cloud
	// server configuration UI.
	function fetchCapabilities() {
		capabilities = wifiOnvifController.getCapabilitiesMap();
		if (Object.keys(capabilities).length === 0) {
			isHmacAndSaAvailable = false
		} else {
			if (capabilities.OEM == true){
			 	isOEM = true
				ModelData.setIsOEM(isOEM)
			}
			if (capabilities.Azure == true){
				isAzureConfigAvailable = true
				if(capabilities.SASToken == true){
					isSASTokenAvailable = true
				}
			} else if(capabilities.HMAC == true && capabilities.ServiceAccount == true){
				isHmacAndSaAvailable = true
			} 
		}
	}

    //API to fetch the Battery Status Information 
	function fetchBatteryInfo(){
		var batteryInfo = wifiOnvifController.getBatteryStatusMap();
		ModelData.getBatteryStatus(batteryInfo);
	}

	// Handles the Read Battery Status button: re-reads battery and charging status from the
	// camera and refreshes only those label fields; shows an error if the read fails.
	function readBatteryStatus(){
		var batteryInfo = wifiOnvifController.getBatteryStatusMap();
		if (Object.keys(batteryInfo).length === 0) {
			setTextMessage("Failed to read battery status")
			return
		}
		var changedFields = ModelData.getBatteryStatus(batteryInfo);
		if (changedFields && changedFields.length > 0) {
			for (var i = 0; i < changedFields.length; i++) {
				var change = changedFields[i];
				if (change.hasOwnProperty('text')) {
					wifiAcc.fieldLabelTextChanged(change.id, change.text);
				}
			}
		}
	}

	//API to fetch the Camera Settings Configuration 
	function fetchCameraSettingsConfiguration(){
		var camConfig = wifiOnvifController.getCameraConfigMap();
		ModelData.getCameraConfig(camConfig);
	}

	// Requests the available and the current stream resolutions from the camera
	// (results arrive through wifiOnvifController signals).
	function fetchVideoProperties(){
		wifiOnvifController.getAvailableResolutions()
		wifiOnvifController.getCurrentResolution()
	}

	//API to get the AP Configuration Data
	function fetchAPConfigData() {
		var configData = wifiOnvifController.getAPConfigMap();
		ModelData.getAPConfig(configData); 
	}

	//API to get the STA Configuration Data
	function fetchSTAConfigData() {
		var staConfigData = wifiOnvifController.getSTAConfigMap();
		ModelData.getSTAConfig(staConfigData); 
    
	}

	//API to get the Server Configuration Data
	function fetchServerConfigData() {
		var serverConfigData = wifiOnvifController.getServerConfigMap();
		ModelData.getServerConfig(serverConfigData, isHmacAndSaAvailable, isAzureConfigAvailable, isSASTokenAvailable); 
		var keys = ModelData.getSharedKeys()
		sharedKey = keys.sharedKey
		sasToken  = keys.sasToken
		
		isSAS = keys.isSAS
		
	}
	
	// Rebuilds the "Image Capture Timer Configuration" section of wifiProperty
	// from timerConfig, appending an "Update" button if missing, and passes the
	// timer data to ModelData.
	//API to get the Timer Configuration Data
	function updateTimerConfigSection(timerConfig) {
		let children = wifiProperty.slice();

		// Remove any existing "Timer Configuration" section
		children = children.filter(item => item.label !== "Image Capture Timer Configuration");

		// Get current timer children or start fresh
		let updatedChildren = timerConfig.children || [];

		// Check if "Save Timer" button with id "updateTimerConfig" already exists
		let hasSaveButton = updatedChildren.some(child => child.id === "updateTimerConfig");

		if (!hasSaveButton) {
			updatedChildren.push({
				id: "updateTimerConfig",
				value: "button",
				name: "Update",
				enabled: true,
				visible: true
			});
		}
		// Add Timer Configuration section back with updated children
		children.push({
			label: "Image Capture Timer Configuration",
			toolTip: "Configure timing settings",
			children: updatedChildren
		});
		wifiProperty = children;
		ModelData.timerdata(timerConfig);
	}
	

	//API to get the Timer Configuration Data
	function fetchTimerConfigData() {
		var timerConfig = wifiOnvifController.getTimerConfigMap();
	  	updateTimerConfigSection(timerConfig);		
	}

	//Function for value update in the text box
	function handleTextBoxValChanged(label, id, text){
		ModelData.updateTextBoxField(label, id, text); //textbox
		wifiAcc.fieldTextChanged(id, text);
	}

	// Applies a drop-down selection via ModelData (a "resolution" change is also
	// sent to the camera and raises window.wifiResolutionChanged) and emits
	// targeted wifiAcc signals for only the fields it reports changed.
	// QML Side - Updated handleDropBoxValChanged function
	function handleDropBoxValChanged(label, id, value) {
		// Get the list of changed fields from JS
		var changedFields = ModelData.handleDropBoxValChanged(label, id, value);
		if(id == "resolution"){
			isResolutionChanged = true
			wifiOnvifController.setCurrentResolution(value)
			window.wifiResolutionChanged()
		}

		// Emit targeted signals for only the changed fields
		if (changedFields && changedFields.length > 0) {
			for (var i = 0; i < changedFields.length; i++) {
				var change = changedFields[i];
		
				if (change.hasOwnProperty('enabled')) {
					wifiAcc.fieldChanged (change.id, change.enabled);
				}
				
				if (change.hasOwnProperty('options')) {
					wifiAcc.fieldOptionsChanged(change.id, change.options, change.selected);
				}

				if (change.hasOwnProperty('selected')) {
					wifiAcc.fieldValueChanged(change.id, change.selected);
				}

				if (change.hasOwnProperty('visible')) {
					wifiAcc.fieldVisibilityChanged(change.id, change.visible);
				}

				if (change.hasOwnProperty('expanded')) {
					wifiAcc.fieldExpandedChanged(change.id, change.expanded);
				}

				if (change.hasOwnProperty('checked')) {	
					wifiAcc.fieldCheckedChanged(change.id, change.checked);
				}

				if (change.hasOwnProperty('text')) {
					wifiAcc.fieldTextChanged(change.id, change.text);
				}	

			}
		}
	}

	// Applies a radio-button change via ModelData (the Azure SAS/Shared Key choice
	// also sets isSAS), emits targeted wifiAcc signals for changed fields, and
	// recalculates heightVal from the rows made visible/hidden by the selection.
	//Function for value update in the radiobutton
	function radioButtonChanged(mode, label, checked){ 

	if(label == "SAS Token Server Config"){
		isSAS = true
	} else if (label == "Shared Key Server Config"){
		isSAS = false
	}

	var length = 0

		// Get the list of changed fields from JS
    var changedFields = ModelData.updateRadioButton(mode, label, checked);
    
    // Emit targeted signals for only the changed fields
    if (changedFields && changedFields.length > 0) {
        // Collect text changes for delayed processing
        var textChanges = [];
        
        for (var i = 0; i < changedFields.length; i++) {
            var change = changedFields[i];
            
           if (change.hasOwnProperty('enabled')) {
					wifiAcc.fieldChanged (change.id, change.enabled);
				}
				if (change.hasOwnProperty('options')) {
					wifiAcc.fieldOptionsChanged(change.id, change.options, change.selected);
				}

				if (change.hasOwnProperty('selected')) {
					wifiAcc.fieldValueChanged(change.id, change.selected);
				}

				if (change.hasOwnProperty('visible')) {
					wifiAcc.fieldVisibilityChanged(change.id, change.visible);
				}

				if (change.hasOwnProperty('expanded')) {
					wifiAcc.fieldExpandedChanged(change.id, change.expanded);
				}


				if (change.hasOwnProperty('checked')) {	
					wifiAcc.fieldCheckedChanged(change.id, change.checked);
				}


				if (change.hasOwnProperty('text')) {
					wifiAcc.fieldTextChanged(change.id, change.text);
				}	
        }
	}

		
        var indexes = findLabelIndex(wifiProperty,label)
		if(indexes.length === 3){
			var lengthChild = 0
			var item = wifiProperty[indexes[0]].children[indexes[1]]
			var children = item.children

			for (var i = 0; i < children.length; i++) {
				if (i == indexes[2]) {
					for (var m = 0; m < children[i].children.length; m++){
						if (children[i].children[m].visible === true) {
							lengthChild += 1
						}
					}
					var item1 = children[i].children
					for (var j = 0; j < item1.length; j++){
						if (item1[j].checked === true && item1[j].visible === true) {
							for (var k = 0; k < item1[j].children.length; k++) {
								if (item1[j].children[k].visible === true) {
									lengthChild += 1
								}
							}
						}
					}
				}else{
					for (var m = 0; m < children[i].children.length; m++) {
						length += 1
					}
					var item1 = children[i].children
					for (var j = 0; j < item1.length; j++){
						if (item1[j].checked === true) {
							for (var k = 0; k < item1[j].children.length; k++) {
								length+= 1
							}
						}
					}
				}
			}	
			
			length =  lengthChild - length 
		}
		if(indexes.length === 4){
				
				var lengthChild = 0
				var item = wifiProperty[indexes[0]].children[indexes[1]].children[indexes[2]]
				var children = item.children

				for (var i = 1; i < children.length; i++) {
					if (i == indexes[3] && children[i].visible === true) {
						for (var k = 0; k < children[i].children.length; k++) {
							if (children[i].children[k].visible === true) {
								lengthChild += 1
							}
						}
					} else {
						if(children[i].visible === true && children[i].children){
							for (var k = 0; k < children[i].children.length; k++) {
								length += 1
							}
						}
					}
				}
				
			length =  lengthChild - length 
		}
				
		if(checked == true){
			heightVal = length*  0.052 * screenHeight + heightVal
		} else{			
			heightVal = heightVal - length * 0.052 * screenHeight 
		}
		
	}

	//Function for value update in the SpinBox
	function handleSpinBoxValChanged(label,text,id){
		ModelData.updateSpinValueField(label,text,id)
	}

    // Stores the slider value in ModelData, sends it to the camera via setCamConfig
    // (except "Quantization"), and emits enabled-state changes for dependent fields.
	//Function for value update in the Slider   
    function handleSliderValChanged(label, id, currentVal){
		var changedFields = ModelData.updateSliderVal(label,id,currentVal)
		if(id != "Quantization"){
			wifiOnvifController.setCamConfig(id, currentVal)
		}
		if (changedFields && changedFields.length > 0) {
        
			for (var i = 0; i < changedFields.length; i++) {
				var change = changedFields[i];
            
			   if (change.hasOwnProperty('enabled')) {
					wifiAcc.fieldChanged (change.id, change.enabled);
				}
			}
		}
    }

	//Function for value update in the Duration text box
	function handleDurationValChanged(label,text, id){		
		ModelData.updateDurationTextBoxField(label,text, id); //textbox	
	}

	//Function to set the timer Configuration Data to the Camera
	function setTimerData() {
		
		localWifiprop = ModelData.getModelData()
		var timerConfigItem = localWifiprop.find(function(item) {
			return item.label === "Image Capture Timer Configuration";
		});
		if (!timerConfigItem) {
			return;
		}

		var childrenList = [];
		for (var i = 0; i < timerConfigItem.children.length; i++) {
			var field = timerConfigItem.children[i];
		
			if (field.label === "Start Time") {
				childrenList.push({
					label: "Start Time",
					startHour: field.startHour,
					startMin: field.startMin,
					startSec: field.startSec || 0
				});
			} else if (field.label === "End Time") {
				childrenList.push({
					label: "End Time",
					endHour: field.endHour,
					endMin: field.endMin,
					endSec: field.endSec || 0
				});
			} else if (field.label === "Duration") {
				childrenList.push({
					label: "Duration",
					hour: parseInt(field.hour) || 0,
					min: parseInt(field.min) || 0,
					sec: parseInt(field.sec) || 0
				});

				if(field.hour == "" || field.min == "" || field.sec == ""){
						setTextMessage("Please Fill all the fields")	
						return;
				} else if (	!Number.isInteger(Number(field.hour)) ||
					!Number.isInteger(Number(field.min)) ||
					!Number.isInteger(Number(field.sec))){
						setTextMessage("Please fill all the fields with valid integers");
						return;
				}else if (	(parseInt(field.hour) < 0 || parseInt(field.hour) > 23)
					|| (parseInt(field.min) < 0 || parseInt(field.min) > 60)
					|| (parseInt(field.sec) < 0 || parseInt(field.sec) > 60)){
						setTextMessage("Please fill the duration within limits");
						return;
				}
			} else if (field.label === "Format") {
				childrenList.push({
					label: "Format",
					value: field.selected
				});
			}
		}
		var timerConfigMap = {
			children: childrenList
		};
		wifiOnvifController.setTimerConfigMap(timerConfigMap);
	}

	// Collects the video recording timer fields (duration 10-1200, pre/post event,
	// circular/event recording) from ModelData, validates the duration and sends
	// them to the camera via wifiOnvifController.setRecordingConfig().
	function setVidRecTimerConfig(){
		localWifiprop = ModelData.getModelData()
		var vidRecTimerConfigItm = localWifiprop.find(function(item) {
			return item.id === "vidRecTimerConfig";
		});
		if (!vidRecTimerConfigItm) {
			return;
		}
		var vidRecTimerConfigMap = {};

		let vidRecDuration, preRecDuration, postRecDuration, isCircularRec, isEventRec;
		for (let field of vidRecTimerConfigItm.children) {
			if (field.id === "vidRecDuration") {
				if( field.text == "" || field.text < 10 || field.text > 1200){
					setTextMessage("Recording duration must be between 10-1200")	
					return
				} else{
					vidRecDuration = field.text;
				}
			}
			if (field.id === "preEventDuration") {
				preRecDuration = field.selected;
			}
			if (field.id === "postEventDuration") {
				postRecDuration = field.selected;
			}
			if (field.id === "circularRecording") {
				isCircularRec = field.selected;
			}
			if (field.id === "eventRecording") {
				isEventRec = field.selected;
			}
		}
		vidRecTimerConfigMap = {
			circularRecording: isCircularRec,
			eventRecording: isEventRec,
			vidRecDuration: vidRecDuration,
			postEventDuration: postRecDuration,
			preEventDuration: preRecDuration
		};

		wifiOnvifController.setRecordingConfig(vidRecTimerConfigMap);
	}

	function isValidIP(ip) {
		const regex = /^(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)){3}$/;
		return regex.test(ip);
	}


		//Function to set the STA Configuration Data to the Camera
	function setSTAConfigData() {
		setSTAData = {}; // reset map

		let ssid = "", password = "", ipConfig = "", ipAddress = "", subnet = "", gateway = "", dns = "";

		const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
		if (!deviceConfig) return console.log("Device Configuration not found");

		const wifiConfig = deviceConfig.children.find(c => c.label === "WiFi Configuration");
		if (!wifiConfig) return console.log("WiFi Configuration not found");

		const staGroup = wifiConfig.children.find(c => c.label === "STA Mode"  && c.checked === true);
		if (!staGroup || !staGroup.children) return console.log("STA Mode group not found");

		for (let field of staGroup.children) {
			switch (field.id) {
				case "STA_SSID":
				{
					ssid = field.text;
					break;
				}
				case "STA_Password":
				{
					password = field.text;
					break;
				}
				case "STA_IPMode":
				{
					ipConfig = field.selected; // "Static" or "Dynamic"
					break;
				}
				case "STA_IPAddress":
				{
					ipAddress = field.text;
					break;
				}
				case "STA_Subnet":
				{
					subnet = field.text;
					break;
				}
				case "STA_Gateway":
				{
					gateway = field.text;
					break;
				}
				case "STA_DNS":
				{
					dns = field.text;
					break;
				}
			}
		}

		if (ipConfig === "STATIC") {	
			const isIPValid = isValidIP(ipAddress);
			const isSubnetValid = isValidIP(subnet);
			const isGatewayValid = isValidIP(gateway);
			const isDnsValid = isValidIP(dns);
			if (!ipAddress || !subnet || !gateway || !dns || !isIPValid || !isSubnetValid || !isGatewayValid || !isDnsValid || !ssid || !password) {
				setTextMessage("Please enter valid details")
				return
			}
		} else if(ipConfig === "DHCP"){
			if (!ssid || !password) {
				setTextMessage("Please fill ssid and password")
				return
			}
		} 

		if(gateway == ipAddress && gateway != ""){
                setTextMessage("Network and Gateway IP should be different.")
				return
		}

		setSTAData = {
			SSID: ssid,
			password: password,
			ipConfig: ipConfig,
			ipAddress: ipAddress,
			subnetMask: subnet,
			gateway: gateway,
			primaryDNS: dns
		};

	   wifiOnvifController.setSTAConfigMap(setSTAData);
	}

		//Function to set the AP Configuration Data to the Camera
	function setAPConfigData() {
		setAPData = {}; // reset to empty map

		const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
		if (!deviceConfig) return console.log("Device Configuration not found");

		const wifiConfig = deviceConfig.children.find(c => c.label === "WiFi Configuration");
		if (!wifiConfig) return console.log("WiFi Configuration not found");

		// Directly find the AP mode based on checked flag
		const apMode = wifiConfig.children.find(m => m.label === "AP Mode" && m.checked === true);
		if (!apMode) return console.log("AP mode is not active");

		let ssid = "", password = "", securityType = "", band = "", channel = "";

		// Extract data from AP Mode's children
		for (let field of apMode.children) {
			if (field.label === "SSID") {
				if( field.text == ""){
					setTextMessage("Please Fill all the fields")	
					return
				} else{
					ssid = field.text;
				}
			}
			if (field.label === "Password") {
				if( field.text == ""){
					setTextMessage("Please Fill all the fields")
					return
				} else{
					password = field.text;
				}
			}
			if (field.label === "Security Type") {
				if (field.selected === "WPA2") {
					securityType = field.selected;
				}
				else if (field.selected === "WPA3") {
					securityType = field.selected;
				}
			}
			if (field.label === "WiFi Band") {
				if (field.selected === "2.4 GHz") {
					band = 0;  // 0 for 2.4 GHz
				}
				else if (field.selected === "5 GHz") {
					band = 1;  // 1 for 5 GHz
				}
			}
			if (field.label === "Channel") {
				channel = parseInt(field.selected);  // Channel number
			}
		}

		setAPData = {
			SSID: ssid,
			password: password,
			securityMode: securityType,
			band: band,
			channel: channel
		};

		wifiOnvifController.setAPConfigMap(setAPData);
	}

	// Collects Anti-Banding and Q-Parameter from the "Camera Setting Configuration"
	// section and sends them to the camera via setCameraConfigMap().
	//Function to set the AP Configuration Data to the Camera
	function setCameraConfig() {
		setCamConfigdata = {}; // reset to empty map

		const camConfig = wifiProperty.find(item => item.label === "Camera Setting Configuration");
		if (!camConfig) return console.log("Camera Setting Configuration not found");

		let antiBanding = "", quantFac;

		// Extract data from AP Mode's children
		for (let field of camConfig.children) {
			if (field.label === "Anti-Banding") {
				antiBanding = field.selected
			}
			if (field.label === "Q-Parameter") {
				quantFac = parseInt(field.currentValue);  // Channel number
			}
		}

		setCamConfigdata = {
			antibanding: antiBanding,
			qFactor: quantFac
		};
	   wifiOnvifController.setCameraConfigMap(setCamConfigdata);
	}

		//Function to set the Cloud Server Configuration Data to the Camera
	function setCloudServer() {
		setServerData = {}; // Reset

		const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
		if (!deviceConfig) return console.log("Device Configuration not found");

		const serverConfig = deviceConfig.children.find(c => c.label === "Server Configuration");
		if (!serverConfig) return console.log("Server Configuration not found");

		let selectedMode = serverConfig.children.find(c => c.checked === true);
		if (!selectedMode) return console.log("No server mode is selected");

		let mode = selectedMode.label === "Cloud"; // false = Local, true = Cloud

		let localConfig = {}, cloudConfig = {};

		if (selectedMode.label === "Local") {
			selectedMode.children.forEach(field => {
				if (field.label === "IP Address") {
					localConfig.IP = field.text;
				}
				if (field.label === "Port") {
					localConfig.Port = parseInt(field.text);
				}
			});
		} else if (selectedMode.label === "Cloud") {
			selectedMode.children.forEach(field => { 
							// Provider
				if (field.label === "Provider") {
					cloudConfig.Provider = field.selected;
				}
 
				if(isHmacAndSaAvailable || (isAzureConfigAvailable && (cloudConfig.Provider == "Amazon" || cloudConfig.Provider == "Google"))){

					
					sasToken = ""
					sharedKey = ""
					// HMAC Credentials
					if (field.id === "hmacMode" && field.checked === true) {
						cloudConfig.AccountType = "HMAC";

						field.children.forEach(hmacField => {
							if (hmacField.label === "Access Key"){
								cloudConfig.AccessKey = hmacField.text;				
							}
							if (hmacField.label === "Secret Key"){
								cloudConfig.SecretKey = hmacField.text;
							}
							if (hmacField.label === "Region"){
								cloudConfig.Region = hmacField.text;
							}
							if (hmacField.label === "Bucket"){
								cloudConfig.BucketNameHMAC = hmacField.text;
							}
						});
					}

					// SA Credentials
					if (field.id === "saMode" && field.checked === true) {
						cloudConfig.AccountType = "SA";

						field.children.forEach(saField => {
							if (saField.id === "bucketNameSA"){
								cloudConfig.BucketNameSA = saField.text;
							}  
							if (saField.id === "fileName"){
								cloudConfig.ServiceAccountJsonFileName = saField.text;
							}
							cloudConfig.ServiceAccountJsonFile = saJsonFileData
						});
					}
				} else if( isAzureConfigAvailable){
					if(field.id === "AzureSAS" && field.checked === true){
						cloudConfig.AccountType = "AzureSAS";
						field.children.forEach(sasField => {
							if (sasField.id === "accountName_sas"){
								cloudConfig.AzureAccountName = sasField.text;
							}  
							if (sasField.id === "containerName_sas"){
								cloudConfig.AzureContainerName = sasField.text;
							}
							cloudConfig.AzureAccountKey = azureSharedKey
							sasToken = azureSharedKey
							sharedKey = ""
						});
					} else	if(field.id === "AzureSharedKey" && field.checked === true){
						cloudConfig.AccountType = "AzureSharedKey";
						field.children.forEach(sharedKeyField => {
							if (sharedKeyField.id === "accountName_sharedKey"){
								cloudConfig.AzureAccountName = sharedKeyField.text;
							}  
							if (sharedKeyField.id === "containerName_sharedKey"){
								cloudConfig.AzureContainerName = sharedKeyField.text;
							}
							cloudConfig.AzureAccountKey = azureSharedKey
							sharedKey = azureSharedKey
							sasToken = ""
						});
					} 
				}else{
					if (field.id === "cloudAccessKey"){
							cloudConfig.AccessKey = field.text;				
						}
						if (field.id === "cloudSecretKey"){
							cloudConfig.SecretKey = field.text;
						}
						if (field.id === "cloudRegion"){
							cloudConfig.Region = field.text;
						}
						if (field.id === "cloudBucket"){
							cloudConfig.BucketName = field.text;
						}
				}
			});
		}

		if(isHmacAndSaAvailable || (isAzureConfigAvailable && (cloudConfig.Provider == "Amazon" || cloudConfig.Provider == "Google"))){
			if(cloudConfig.AccountType == "HMAC"){
				if(!cloudConfig.AccessKey || !cloudConfig.SecretKey || !cloudConfig.Region || !cloudConfig.BucketNameHMAC){
					setTextMessage("Please Fill all the fields")
					return
				}
			} else if(cloudConfig.AccountType == "SA"){
				if(!cloudConfig.BucketNameSA){
					setTextMessage("Please Fill all the fields")
					return
				} else if( !cloudConfig.ServiceAccountJsonFile || !cloudConfig.ServiceAccountJsonFileName){
					setTextMessage("Please select a valid json file")	
					return
				}
			}
		} else if(isAzureConfigAvailable){
			if(cloudConfig.AccountType == "AzureSAS" || cloudConfig.AccountType == "AzureSharedKey"){
				if(!cloudConfig.AzureAccountName || !cloudConfig.AzureContainerName){
					setTextMessage("Please Fill all the fields")
					return
				} else if( !cloudConfig.AzureAccountKey ){
					setTextMessage("Please select a valid json file")	
					return
				}
			}
		}else{
			if(!cloudConfig.AccessKey || !cloudConfig.SecretKey || !cloudConfig.Region || !cloudConfig.BucketName){
				setTextMessage("Please Fill all the fields")
				return
			}
		}

		setServerData = {
			mode: mode,
			localConfig: localConfig,
			cloudConfig: cloudConfig
		};
		wifiOnvifController.setServerConfigMap(setServerData);
	}

	//Function to set the Local Server Configuration Data to the Camera
	function setLocalServerData() {
		setServerData = {}; // reset

		const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
		if (!deviceConfig) return console.log("Device Configuration not found");

		const serverConfig = deviceConfig.children.find(c => c.label === "Server Configuration");
		if (!serverConfig) return console.log("Server Configuration not found");

		let selectedMode = serverConfig.children.find(c => c.checked === true);
		if (!selectedMode) return console.log("No server mode is selected");

		let mode = selectedMode.label === "Cloud";  // false = Local, true = Cloud
		let localConfig = {}, cloudConfig = {};

		if (selectedMode.label === "Local") {
			selectedMode.children.forEach(field => {
				if (field.label === "IP Address") {
					localConfig.IP = field.text;
				}
				if (field.label === "Port") {
					localConfig.Port = parseInt(field.text);
				}
			});
		} else if (selectedMode.label === "Cloud") {
			selectedMode.children.forEach(field => {
				if (field.label === "Provider") {
					cloudConfig.Provider = field.selected;
				}

				// HMAC
				if (field.id === "hmacMode" && field.checked === true) {
					cloudConfig.AccountType = "HMAC";

					field.children.forEach(hmacField => {
						if (hmacField.label === "Access Key") cloudConfig.AccessKey = hmacField.text;
						if (hmacField.label === "Secret Key") cloudConfig.SecretKey = hmacField.text;
						if (hmacField.label === "Region") cloudConfig.Region = hmacField.text;
						if (hmacField.label === "Bucket") cloudConfig.BucketNameHMAC = hmacField.text;
					});
				}

				// SA
				if (field.id === "saMode" && field.checked === true) {
					cloudConfig.AccountType = "SA";

					field.children.forEach(saField => {
						if (saField.id === "bucketNameSA") cloudConfig.BucketNameSA = saField.text;
						if (saField.id === "fileName") cloudConfig.ServiceAccountJsonFileName = saField.text;
						cloudConfig.ServiceAccountJsonFile = saJsonFileData
					});
				}
			});
		}

		if(!localConfig.Port || !Number.isInteger(Number(localConfig.Port)) || !isValidIP(localConfig.IP)  || !localConfig.IP){
			setTextMessage("Please enter valid details")
			return
		}
		setServerData = {
			mode: mode,
			localConfig: localConfig,
			cloudConfig: cloudConfig
		};

		wifiOnvifController.setServerConfigMap(setServerData);
	}


	// Expands/collapses the accordion node with the given label (found via
	// findLabelIndex), counts the visible child rows it adds/removes, adjusts
	// heightVal and grows or resets the flickable contentWidth accordingly.
	// For a level-2 node, also notifies logController.expandedItem() for each
	// expanded child.
	function setExpandedState(label, expanded){
		var length = 0
        var indexes = findLabelIndex(wifiProperty,label)
        if(indexes.length == 1){
			var lengthChild = 0
			var lengthGrandChild =0
            wifiProperty[indexes[0]].expanded = expanded
			length = wifiProperty[indexes[0]].children.length
			
			var children = wifiProperty[indexes[0]].children
			length = children.length

			for (var i = 0; i < children.length; i++) {
				if (children[i].expanded === true) {
					lengthChild += children[i].children.length
					var grandchild = children[i].children
					for (var j = 0; j < grandchild.length; j++) {
						if (grandchild[j].expanded === true) {
							lengthGrandChild += grandchild[j].children.length
						}
					}
				}
			}
			length = length + lengthChild + lengthGrandChild
        }else if (indexes.length === 2) {
			var lengthChild = 0
			var lengthGrandChild = 0
			var item = wifiProperty[indexes[0]].children[indexes[1]]
			item.expanded = expanded
			wifiProperty[indexes[0]].children[indexes[1]].expanded = expanded

			var children = item.children
			length = children.length

			for (var i = 0; i < children.length; i++) {
				if (children[i].expanded === true) {
					lengthChild += children[i].children.length
					if(item.expanded == true){
						logController.expandedItem(children[i].id)
					}
				}
			}
			length = length + lengthChild + lengthGrandChild			
		} else if(indexes.length == 3){
            wifiProperty[indexes[0]].children[indexes[1]].children[indexes[2]].expanded = expanded
			length = wifiProperty[indexes[0]].children[indexes[1]].children[indexes[2]].length
		}  else if(indexes.length == 4){
            wifiProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children[indexes[3]].expanded = expanded
			length =  wifiProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children[indexes[3]].length
		} 

		var width = 0.0805 * MonitorHandler.screenResolution.width
		var scrollWidth;
		if(expanded == true){
			heightVal = length*  0.052 * screenHeight + heightVal
			if(heightVal > wifiInnerRectangle.height){
				scrollWidth = 0.183 * MonitorHandler.screenResolution.width
			} else{
				scrollWidth = 0.183 * MonitorHandler.screenResolution.width
			}
			if(indexes.length == 1){
				if(indexes[0] != 0){
					width =  indexes.length* width
				} else{
					width = 0
				}
			} else{
				width = width *1.4
			}
			if(wifiInnerRectangle.width > 0 && wifiFlickable.contentWidth < scrollWidth + width){
				wifiFlickable.contentWidth = scrollWidth + width
			}
		} else{			
			heightVal = heightVal - length * 0.052 * screenHeight 
			var count =0
			for(i =0 ; i < wifiProperty.length ; i++){
				if(wifiProperty[i]. expanded == false){
					count ++
				}
				if(count == wifiProperty.length){
					wifiFlickable.contentWidth = 0
				}
			}
		}
    }

    // Recursively searches the property tree for labelToFind and returns the
    // index path to it (e.g. [section, group, item]), or null if not found.
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

	// Enables the children of a checked+enabled radio button (except the read-only
	// file-name fields) and disables the children of an unchecked one; "mode1" and
	// "mode2" are left untouched. Returns the (modified) itemData.
	function updateEnabledStatus(itemData) {
		if (!itemData) {
			return itemData;
		}

		if( itemData.id == "mode2" || itemData.id == "mode1"){
			return itemData;
		}
    
		// If this is a radio button that's checked and enabled
		if (itemData.value === "radioButton" && itemData.checked === true && itemData.enabled === true) {
        
			// Enable all children (except specific read-only fields)
			if (itemData.children && Array.isArray(itemData.children)) {
				const disabledFields = ["fileName", "fileName_sharedKey", "fileName_sas"];
            
				itemData.children.forEach(function(child) {
					if (!disabledFields.includes(child.id)) {
						child.enabled = true;
					} else {
						child.enabled = false;
					}
				});
			}
		}
		// If radio button is unchecked, disable children
		else if (itemData.value === "radioButton" && itemData.checked === false) {
			if (itemData.children && Array.isArray(itemData.children)) {
				itemData.children.forEach(function(child) {
					child.enabled = false;
				});
			}
		}
    
		return itemData;
	}

	// Shows/hides cloud credential fields for the selected provider: HMAC/SA
	// options for Amazon/Google (when supported), Azure SAS/Shared Key options for
	// Azure, or the basic access-key fields when neither is supported.
	function updateCloudProviderVisibility(accordionData) {
    
		if (!accordionData || !accordionData.children) {
			return accordionData;
		}
    
		// Find the provider dropdown
		const providerField = accordionData.children.find(child => child.id === "cloud_Provider");
	//	if(poviderField){
			const selectedProvider = providerField ? providerField.selected : null;
    
			// Case 1: HMAC and SA available OR (Azure config available AND Amazon/Google selected)
			if (isHmacAndSaAvailable || (isAzureConfigAvailable && (selectedProvider === "Amazon" || selectedProvider === "Google"))) {
        
				accordionData.children.forEach(child => {
					// Hide Azure-specific fields
					if (["AzureSharedKey", "AzureSAS"].includes(child.id)) {
						child.visible = false;
						child.expanded = false;
                
						// Hide all children of Azure radio buttons
						if (child.children && Array.isArray(child.children)) {
							child.children.forEach(subChild => {
								subChild.visible = false;
							});
						}
					}
            
					// Hide basic cloud fields (they're replaced by HMAC/SA)
					if (["cloudAccessKey", "cloudSecretKey", "cloudRegion", "cloudBucket", "updateCloudConfig"].includes(child.id)) {
						child.visible = false;
					}
            
					// Show HMAC/SA options
					if (["hmacMode", "saMode"].includes(child.id)) {
						child.visible = true;
					}
				});
			}
			// Case 2: Azure config available AND Azure selected
			else if (isAzureConfigAvailable && selectedProvider === "Azure") {
        
				accordionData.children.forEach(child => {
					// Hide HMAC/SA fields
					if (["saMode", "hmacMode"].includes(child.id)) {
						child.visible = false;
						child.expanded = false;
                
						// Hide all children of HMAC/SA radio buttons
						if (child.children && Array.isArray(child.children)) {
							child.children.forEach(subChild => {
								subChild.visible = false;
							});
						}
					}
            
					// Hide basic cloud fields (they're replaced by Azure options)
					if (["cloudAccessKey", "cloudSecretKey", "cloudRegion", "cloudBucket", "updateCloudConfig"].includes(child.id)) {
						child.visible = false;
					}
            
					// Show Azure options
					if (["AzureSharedKey", "AzureSAS"].includes(child.id)) {
						child.visible = true;
					}
				});
			}
			// Case 3: Neither HMAC/SA nor Azure config available
			else if (!isHmacAndSaAvailable && !isAzureConfigAvailable) {
        
				accordionData.children.forEach(child => {
					// Hide all advanced options
					if (["saMode", "hmacMode", "AzureSharedKey", "AzureSAS"].includes(child.id)) {
						child.visible = false;
						child.expanded = false;
                
						// Hide all children
						if (child.children && Array.isArray(child.children)) {
							child.children.forEach(subChild => {
								subChild.visible = false;
							});
						}
					}
            
					// Show basic cloud fields
					if (["cloudAccessKey", "cloudSecretKey", "cloudRegion", "cloudBucket", "updateCloudConfig"].includes(child.id)) {
						child.visible = true;
					}
				});
			}
    
			return accordionData;
		//}
	}
}
