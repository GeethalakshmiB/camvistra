var wifiProperty = [];
var isHmacAndSaAvail;
var isAzureConfigAvail;
var isSASTokenAvail;
var cloudProvider
var sharedKey = "";
var sasToken = "";
var isSAS = false;
var isOEMVariant = false;
var isExposureAuto = false;
var isWbAuto = false
var cameraConfigNode = null;
var cameraUiIndex = {};
var capabilities

var cloudProviderCache = {
    Amazon: {
        AccessKey: "",
        SecretKey: "",
        Region: "",
        Bucket: ""
    },
    Google: {
        AccessKey: "",
        SecretKey: "",
        Region: "",
        Bucket: ""
    }
};

var saCache = {
    bucketName: "",
    fileName: ""
};

var TokenCache = {
    AzureSAS: {
        AccountName: "",
        ContainerName: "",
        FileName : "No files selected"
    },
    AzureSharedKey: {
        AccountName: "",
        ContainerName: "",
        FileName: "No files selected"
    }
};

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCloudProvider()
//
//  PURPOSE		:	To return the cloud provider (Amazon/Google/Azure) currently cached
//					from the device server config or the Provider drop-down.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	string - current cloudProvider value
///////////////////////////////////////////////////////////////////////////
function getCloudProvider() {
    return cloudProvider
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To replace the cached WiFi property tree (wifiProperty) with the
//					JSON array supplied by the QML view.
//
//	ARGUMENTS	:	jsonArray - array of property nodes loaded from the WiFi UI JSON
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    wifiProperty = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getModelData()
//
//  PURPOSE		:	To return the cached WiFi property tree used to build the UI model.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	array - wifiProperty
///////////////////////////////////////////////////////////////////////////
function getModelData() {
    return wifiProperty;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setTooltip(jsonTooltipArray)
//
//  PURPOSE		:	To walk the whole wifiProperty tree recursively and set the tooltip
//					of every node whose id matches an entry in the tooltip list.
//
//	ARGUMENTS	:	jsonTooltipArray - array of { id, tooltip } objects
//
//	RETURN		:	array - the updated wifiProperty tree
///////////////////////////////////////////////////////////////////////////
function setTooltip( jsonTooltipArray) {
        // Create a map for faster lookup of tooltips by ID
        const tooltipMap = new Map();
        jsonTooltipArray.forEach(item => {
            tooltipMap.set(item.id, item.tooltip);
        });
    
        ///////////////////////////////////////////////////////////////////////////
        //  FUNCTION	:	addTooltipRecursive(obj)
        //
        //  PURPOSE		:	To recursively visit arrays/objects of the property tree and assign
        //					the tooltip from tooltipMap to every node whose id is present in it.
        //
        //	ARGUMENTS	:	obj - array or object node of the property tree to traverse
        //
        //	RETURN		:	None
        ///////////////////////////////////////////////////////////////////////////
        // Recursive function to traverse and update tooltip
        function addTooltipRecursive(obj) {
            if (Array.isArray(obj)) {
                obj.forEach(item => addTooltipRecursive(item));
            } else if (typeof obj === 'object' && obj !== null) {
                if (obj.id && tooltipMap.has(obj.id)) {
                    obj.tooltip = tooltipMap.get(obj.id);
                }
                // Check all child fields that could hold nested elements
                for (let key of Object.keys(obj)) {
                    addTooltipRecursive(obj[key]);
                }
            }
        }
    
        addTooltipRecursive(wifiProperty);
        
        return wifiProperty;
}   

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setIsHmacAndSaAvailable(value)
//
//  PURPOSE		:	To set the HMAC/SA, Azure config and SAS token availability flags to
//					the same value; when false, clears cloudProviderCache and TokenCache.
//					Also resets isOEMVariant to false and empties wifiProperty.
//
//	ARGUMENTS	:	value - true if the feature set is available, false to reset
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setIsHmacAndSaAvailable(value) {

    isHmacAndSaAvail = value
    isAzureConfigAvail = value
    isSASTokenAvail = value
    if (value == false) {
        // Use proper object construction
        cloudProviderCache = {};
        cloudProviderCache.Amazon = {
            AccessKey: "",
            SecretKey: "",
            Region: "",
            Bucket: ""
        };
        cloudProviderCache.Google = {
            AccessKey: "",
            SecretKey: "",
            Region: "",
            Bucket: ""
        };

        TokenCache = {};
        TokenCache.AzureSAS = {
            AccountName: "",
            ContainerName: "",
            FileName: ""
        };
        TokenCache.AzureSharedKey = {
            AccountName: "",
            ContainerName: "",
            FileName: ""
        };
    }
    isOEMVariant = false;
    wifiProperty = [];
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSharedKeyJsonFileName(fileName)
//
//  PURPOSE		:	To store the uploaded key file name in TokenCache for the checked
//					Azure radio (AzureSharedKey/AzureSAS) under Server Configuration >
//					Cloud and refresh its account/container/file-name text boxes.
//
//	ARGUMENTS	:	fileName - name of the selected shared key / SAS json file
//
//	RETURN		:	array - { id, text } entries for the text fields that were updated
///////////////////////////////////////////////////////////////////////////
function updateSharedKeyJsonFileName(fileName) {
    var changedFields = [];  // Track changes

    const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
    if (!deviceConfig) {
        return changedFields;
    }

    const serverConfig = deviceConfig.children.find(c => c.label === "Server Configuration");
    if (!serverConfig) {
        return changedFields;
    }

    const cloudMode = serverConfig.children.find(c => c.label === "Cloud");
    if (!cloudMode) {
        return changedFields;
    }

    for (const radio of cloudMode.children) {
        if (radio.checked === true) {
            if (radio.id === "AzureSharedKey" || radio.id === "AzureSAS") {
                // Update TokenCache
                TokenCache[radio.id].FileName = fileName;
                const tokenData = TokenCache[radio.id];

                // Update children and track changes
                for (const child of radio.children) {
                    var textValue = "";

                    if (child.id === "accountName_sharedKey" || child.id === "accountName_sas") {
                        textValue = tokenData.AccountName || "";
                    } else if (child.id === "containerName_sharedKey" || child.id === "containerName_sas") {
                        textValue = tokenData.ContainerName || "";
                    } else if (child.id === "fileName_sharedKey" || child.id === "fileName_sas") {
                        textValue = tokenData.FileName || "";
                    }

                    if (textValue !== "") {
                        child.text = textValue;
                        changedFields.push({
                            id: child.id,
                            text: textValue
                        });
                    }
                }
            }
        }
    }

    return changedFields;
}
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleWiFiModeSelection(selectedId)
//
//  PURPOSE		:	To check the given radio button in the "WiFiMode" group and show
//					only its children, hiding the children of the other radio buttons.
//					Looks the group up in a global jsonData (not defined in this file).
//
//	ARGUMENTS	:	selectedId - id of the WiFi mode radio button to select
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleWiFiModeSelection(selectedId) {
    const wifiGroup = findGroupById(jsonData, "WiFiMode");
    if (!wifiGroup) return;

    wifiGroup.children.forEach(child => {
        if (child.value === "radioButton") {
            child.checked = (child.id === selectedId);
            if (child.children) {
                child.children.forEach(grandchild => {
                    grandchild.visible = child.checked;
                });
            }
        }
    });
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleServerModeSelection(selectedId)
//
//  PURPOSE		:	To check the given radio button in the "ServerMode" group and show
//					only its children, hiding the children of the other radio buttons.
//					Looks the group up in a global jsonData (not defined in this file).
//
//	ARGUMENTS	:	selectedId - id of the server mode radio button to select
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleServerModeSelection(selectedId) {
    const serverGroup = findGroupById(jsonData, "ServerMode");
    if (!serverGroup) return;

    serverGroup.children.forEach(child => {
        if (child.value === "radioButton") {
            child.checked = (child.id === selectedId);
            if (child.children) {
                child.children.forEach(grandchild => {
                    grandchild.visible = child.checked;
                });
            }
        }
    });
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	findGroupById(node, id)
//
//  PURPOSE		:	To depth-first search a node and its children for the node with the
//					given id.
//
//	ARGUMENTS	:	node - root node to start the search from
//					id - id of the node to find
//
//	RETURN		:	object - matching node, or null if not found
///////////////////////////////////////////////////////////////////////////
// Utility function to search deeply in the JSON structure
function findGroupById(node, id) {
    if (node.id === id) return node;
    if (node.children) {
        for (const child of node.children) {
            const result = findGroupById(child, id);
            if (result) return result;
        }
    }
    return null;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getAPConfig(configData)
//
//  PURPOSE		:	To rebuild the children of the AP Mode radio (id "mode1") under
//					Device Configuration > WiFi Configuration with SSID, password,
//					security type, band, channel list and the Update button.
//
//	ARGUMENTS	:	configData - AP config read from the device { SSID, password,
//					securityMode, band (0 = 2.4 GHz, 1 = 5 GHz), channel }
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getAPConfig(configData) {
    for (let i = 0; i < wifiProperty.length; i++) {
        let item = wifiProperty[i];
        if (item.label === "Device Configuration") {
            for (let j = 0; j < item.children.length; j++) {
                let subItem = item.children[j];
                if (subItem.label === "WiFi Configuration") {
                    for (let k = 0; k < subItem.children.length; k++) {
                        let child = subItem.children[k];
                        if (child.id === "mode1") { // AP Mode
                            let apChildren = [
                                { label: "SSID", value: "textBox", text: configData.SSID, id: "AP_SSID", visible: true, enabled: true, visible : true },
                                { label: "Password", value: "textBox", text: configData.password, id: "AP_Password", visible: true, enabled: true, visible: true },
                                {
                                    label: "Security Type",
                                    value: "dropBox",
                                    id: "AP_SecurityType",
                                    selected: configData.securityMode,
                                    visible: true,
                                    enabled: true,
                                    children_drop: [
                                        { label1: "WPA2", selected: configData.securityMode === "WPA2" },
                                        { label1: "WPA3", selected: configData.securityMode === "WPA3" }
                                    ]
                                },
                                {
                                    label: "WiFi Band",
                                    value: "dropBox",
                                    id: "AP_WifiBand",
                                    selected: configData.band === 0 ? "2.4 GHz" : "5 GHz",
                                    visible: true,
                                    enabled: true,
                                    children_drop: [
                                        { label1: "2.4 GHz", selected: configData.band === 0 },
                                        { label1: "5 GHz", selected: configData.band === 1 }
                                    ]
                                },
                                {
                                    label: "Channel",
                                    value: "dropBox",
                                    id: "AP_Channel",
                                    selected: configData.channel.toString(),
                                    visible: true,
                                    enabled: true,
                                    children_drop: configData.band === 0
                                        ? [{ label1: "1" }, { label1: "6" }]
                                        : [{ label1: "36" }, { label1: "40" }, { label1: "44" }, { label1: "48" }, { label1: "149" }, { label1: "153" }, { label1: "157" }, { label1: "161" }]
                                },
                                {
                                    id : "updateApConfig",
                                    value: "button",
                                    name: "Update",
                                    enabled: true,
                                    visible: true
                                }
                            ];
                            child.children = apChildren;
                        }
                    }
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSTAConfig(staConfigData)
//
//  PURPOSE		:	To rebuild the children of the STA Mode radio (id "mode2") under
//					Device Configuration > WiFi Configuration with SSID, password, IP
//					mode and IP/subnet/gateway/DNS boxes (disabled when DHCP).
//
//	ARGUMENTS	:	staConfigData - STA config read from the device { SSID, password,
//					ipConfig, ipAddress, subnetMask, gateway, primaryDNS }
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getSTAConfig(staConfigData) {
    for (let i = 0; i < wifiProperty.length; i++) {
        let item = wifiProperty[i];
        if (item.label === "Device Configuration") {
            for (let j = 0; j < item.children.length; j++) {
                let subItem = item.children[j];
                if (subItem.label === "WiFi Configuration") {
                    for (let k = 0; k < subItem.children.length; k++) {
                        let child = subItem.children[k];
                        if (child.id === "mode2") { // STA Mode
                            let isDynamic = staConfigData.ipConfig === "DHCP";
                            let staChildren = [
                                { label: "SSID", value: "textBox", text: staConfigData.SSID, id: "STA_SSID", visible: true, enabled: true },
                                { label: "Password", value: "textBox", text: staConfigData.password, id: "STA_Password", visible: true, enabled : true },
                                {
                                    label: "IP Mode",
                                    value: "dropBox",
                                    selected: staConfigData.ipConfig.toUpperCase() === "STATIC"? "STATIC" : "DHCP", 
                                    id: "STA_IPMode",
                                    enabled: true,
                                    visible: true,
                                    children_drop: [
                                        { label1: "STATIC", selected: staConfigData.ipConfig.toUpperCase() === "STATIC" },
                                        { label1: "DHCP", selected: staConfigData.ipConfig.toUpperCase() === "DHCP" }
                                    ]
                                },
                                { label: "IP Address", value: "textBox", text: staConfigData.ipAddress, id: "STA_IPAddress", visible: true, enabled: !isDynamic },
                                { label: "Subnet Mask", value: "textBox", text: staConfigData.subnetMask, id: "STA_Subnet", visible: true, enabled: !isDynamic },
                                { label: "Gateway", value: "textBox", text: staConfigData.gateway, id: "STA_Gateway", visible: true, enabled: !isDynamic },
                                { label: "DNS", value: "textBox", text: staConfigData.primaryDNS, id: "STA_DNS", visible: true, enabled: !isDynamic },
                                {
                                    id : "updateStaConfig",
                                    value: "button",
                                    name: "Update",
                                    enabled: true,
                                    visible: true
                                }
                            ];
                            child.children = staChildren;
                        }
                    }
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getServerConfig(serverConfigData, isHmacAndSaAvailable, isAzureConfigAvailable, isSASTokenAvailable)
//
//  PURPOSE		:	To store the feature availability flags, cache cloud credentials
//					(cloudProviderCache / TokenCache / shared key / SAS token) and rebuild
//					the Local and Cloud children of Server Configuration. The Cloud layout
//					depends on the flags: HMAC/SA, Azure-only or plain key fields.
//
//	ARGUMENTS	:	serverConfigData - server config { localConfig, cloudConfig } from the device
//					isHmacAndSaAvailable - true if HMAC/SA account types are supported
//					isAzureConfigAvailable - true if the Azure provider is supported
//					isSASTokenAvailable - true if the Azure SAS token is supported
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getServerConfig(serverConfigData, isHmacAndSaAvailable, isAzureConfigAvailable, isSASTokenAvailable) {

    isHmacAndSaAvail = isHmacAndSaAvailable
    isAzureConfigAvail = isAzureConfigAvailable
    isSASTokenAvail = isSASTokenAvailable
    const updatedChildren = [];

    for (let i = 0; i < wifiProperty.length; i++) {
        const item = wifiProperty[i];

        if (item.label === "Device Configuration") {
            const deviceChildren = [];

            for (let j = 0; j < item.children.length; j++) {
                const subItem = item.children[j];

                if (subItem.label === "Server Configuration" && Array.isArray(subItem.children)) {
                    for (let k = 0; k < subItem.children.length; k++) {
                        const mode = subItem.children[k];

                        // Local Server
                        if (mode.label === "Local") {
                            const local = serverConfigData.localConfig;

                            const localChildren = [
                                { id: "local_IPAddress", label: "IP Address", value: "textBox", text: local.IP, enabled: true, visible: true },
                                { id: "local_Port", label: "Port", value: "textBox", text: local.Port, enabled: true, visible: true },
                                {
                                    id : "updateLocalConfig",
                                    value: "button",
                                    name: "Update",
                                    enabled: true,
                                    visible: true
                                }
                            ];

                            mode.children = localChildren;
                        }

                        // Cloud Server
                        if (mode.label === "Cloud") {
                            const cloud = serverConfigData.cloudConfig;
                             // Populate the cache
                             if(cloud.Provider === "Custom"){
                                cloud.Provider = "Amazon"
                             }
                            const provider = cloud.Provider;
                            if (provider === "Amazon" || provider === "Google") {
                                cloudProviderCache[provider] = {
                                    AccessKey: cloud.AccessKey? cloud.AccessKey : "" ,
                                    SecretKey: cloud.SecretKey? cloud.SecretKey : "",
                                    Region: cloud.Region ? cloud.Region : "",
                                    Bucket: cloud.BucketNameHMAC ? cloud.BucketNameHMAC : "" 
                                };
                                if (isSASTokenAvail) {
                                    isSAS = true;
                                }
                            } 
                            const accountType = cloud.AccountType
                            if (accountType == "AzureSAS" || accountType == "AzureSharedKey") {
                                TokenCache[accountType] = {
                                    AccountName: cloud.AzureAccountName,
                                    ContainerName: cloud.AzureContainerName,
                                    FileName: cloud.Provider === "Azure" ? (isSASTokenAvailable ? "sasKey.json" : "sharedKey.json") : "No files selected"
                                }
                                if (accountType == "AzureSAS") {
                                    isSAS = true
                                    sasToken  = cloud.AzureAccountKey
                                } else {
                                    isSAS = false
                                    sharedKey = cloud.AzureAccountKey
                                }

                            }
                            cloudProvider = cloud.Provider
                            if (isHmacAndSaAvail || (isAzureConfigAvail && (provider === "Amazon" || provider === "Google"))) {
                                const providerDropOptions = [
                                    { label1: "Amazon", selected: cloud.Provider === "Amazon" },
                                    { label1: "Google", selected: cloud.Provider === "Google" }
                                ];

                                // Conditionally push Azure option
                                if (isAzureConfigAvail) {
                                    providerDropOptions.push({ label1: "Azure", selected: cloud.Provider === "Azure" });
                                }

                                const cloudChildren = [
                                    {
                                        id: "cloud_Provider",
                                        label: "Provider",
                                        value: "dropBox",
                                        selected: cloud.Provider,
                                        visible: true,
                                        enabled: true,
                                        children_drop: providerDropOptions
                                    },

                                    {
                                        id: "cloudAccessKey",
                                        label: "Access Key",
                                        value: "textBox",
                                        text: "",//cloud.AccessKey,
                                        enabled: true,
                                        visible: false
                                    },
                                    {
                                        id: "cloudSecretKey",
                                        label: "Secret Key",
                                        value: "textBox",
                                        text: "",//cloud.SecretKey,
                                        enabled: true,
                                        visible: false
                                    },
                                    {
                                        id: "cloudRegion",
                                        label: "Region",
                                        value: "textBox",
                                        text: "",// cloud.Region,
                                        enabled: true,
                                        visible: false
                                    },
                                    {
                                        id: "cloudBucket",
                                        label: "Bucket",
                                        value: "textBox",
                                        text: "",//cloud.BucketName,
                                        enabled: true,
                                        visible: false
                                    },
                                    {
                                        id : "updateCloudConfig",
                                        value: "button",
                                        name: "Update",
                                        enabled: false,
                                        visible: false
                                    },
                                    {
                                        label: "HMAC",
                                        value: "radioButton",
                                        id: "hmacMode",
                                        enabled: true,
                                        checked: (cloud.AccountType === "HMAC" || cloud.Provider !== "Google"),
                                        identification: "accountType",
                                        visible: true,
                                        expanded: (cloud.AccountType === "HMAC" || cloud.Provider !== "Google"),
                                        children: [
                                            { id: "cloud_AccessKey", label: "Access Key", value: "textBox", text: (cloud.AccessKey? cloud.AccessKey : ""), enabled: true, visible: true },
                                            { id: "cloud_SecretKey", label: "Secret Key", value: "textBox", text: (cloud.SecretKey? cloud.SecretKey : ""), enabled: true, visible: true },
                                            { id: "cloud_Region", label: "Region", value: "textBox", text: (cloud.Region? cloud.Region : ""), enabled: true, visible: true },
                                            { id: "cloud_Bucket", label: "Bucket", value: "textBox", text: (cloud.BucketNameHMAC ? cloud.BucketNameHMAC : ""), enabled: true, visible: true },
                                            {
                                                id : "updateHMACConfig",
                                                value: "button",
                                                name: "Update",
                                                enabled: true,
                                                visible: true
                                            }
                                        ]
                                    },
                                    {
                                        label: "SA",
                                        value: "radioButton",
                                        id: "saMode",
                                        checked: cloud.AccountType === "SA",
                                        identification: "accountType",
                                        enabled: (cloud.Provider === "Google"),
                                        visible: true,
                                        expanded: cloud.AccountType === "SA",
                                        children: [
                                            { id: "bucketNameSA", label: "Bucket Name:", value: "textBox", text: cloud.BucketNameSA, enabled: true, visible: true },
                                            { id: "file", label: "File: ", value: "button", text: "Upload File", name: "Upload file", enabled: true, visible: true },
                                            { id: "fileName", label: "File name:", value: "textBox", text: cloud.ServiceAccountJsonFileName, enabled: false, visible: true },
                                            {
                                                id: "updateSAConfig",
                                                value: "button",
                                                name: "Update",
                                                enabled: true,
                                                visible: true
                                            }
                                        ]
                                    },
                                    {
                                        label: "SAS Token Server Config",
                                        value: "radioButton",
                                        id: "AzureSAS",
                                        checked: cloud.AccountType === "AzureSAS",
                                        identification: "accountType1",
                                        enabled: (cloud.Provider === "Azure"),
                                        visible: false,
                                        expanded: cloud.AccountType === "AzureSAS",
                                        children: [
                                            { id: "accountName_sas", label: "Account Name:", value: "textBox", text: cloud.AzureAccountName, enabled: true, visible: false },
                                            { id: "containerName_sas", label: "Container Name:", value: "textBox", text: cloud.AzureContainerName, enabled: true, visible: false },
                                            { id: "storageKey_sas", label: "File: ", value: "button", text: "Upload File", name: "Upload file", enabled: true, visible: false },
                                            { id: "fileName_sas", label: "File name:", value: "textBox", text: cloud.Provider === "Azure" ? (isSASTokenAvailable ? "sasKey.json" : "sharedKey.json") : "No files selected", enabled: false, visible: false },
                                            { id: "downloadSasKeyConfig", value: "button", name: "Download key", enabled: true, visible: false },
                                            { id: "updateSASConfig", value: "button", name: "Update", enabled: true, visible: false }
                                        ]
                                    },
                                    {
                                        label: "Shared Key Server Config",
                                        value: "radioButton",
                                        id: "AzureSharedKey",
                                        checked: cloud.AccountType === "AzureSharedKey",
                                        identification: "accountType1",
                                        enabled: (cloud.Provider === "Azure"),
                                        visible: false,
                                        expanded: cloud.AccountType === "AzureSharedKey",
                                        children: [
                                            { id: "accountName_sharedKey", label: "Account Name:", value: "textBox", text: cloud.AzureAccountName, enabled: true, visible: false },
                                            { id: "containerName_sharedKey", label: "Container Name:", value: "textBox", text: cloud.AzureContainerName, enabled: true, visible: false },
                                            { id: "storageKey_sharedKey", label: "File: ", value: "button", text: "Upload File", name: "Upload file", enabled: true, visible: false },
                                            { id: "fileName_sharedKey", label: "File name:", value: "textBox", text: cloud.Provider === "Azure" ? (isSASTokenAvailable ? "sasKey.json" : "sharedKey.json") : "No files selected", enabled: false, visible: false },
                                            { id: "downloadSharedKeyConfig", value: "button", name: "Download key", enabled: true, visible: false },
                                            { id: "updateSharedKeyConfig", value: "button", name: "Update", enabled: true, visible: false }
                                        ]
                                    }
                                ];

                                mode.children = cloudChildren;
                            }
                            else if (isAzureConfigAvail) {
                                const cloudChildren = [
                                    {
                                        id: "cloud_Provider",
                                        label: "Provider",
                                        value: "dropBox",
                                        selected: cloud.Provider,
                                        visible: true,
                                        enabled: true,
                                        children_drop: [
                                            { label1: "Amazon", selected: cloud.Provider === "Amazon" },
                                            { label1: "Google", selected: cloud.Provider === "Google" },
                                            { label1: "Azure", selected: cloud.Provider === "Azure" }
                                        ]
                                    },

                                    {
                                        id: "cloudAccessKey",
                                        label: "Access Key",
                                        value: "textBox",
                                        text: "",//cloud.AccessKey,
                                        enabled: true,
                                        visible: false
                                    },
                                    {
                                        id: "cloudSecretKey",
                                        label: "Secret Key",
                                        value: "textBox",
                                        text: "",//cloud.SecretKey,
                                        enabled: true,
                                        visible: false
                                    },
                                    {
                                        id: "cloudRegion",
                                        label: "Region",
                                        value: "textBox",
                                        text: "",// cloud.Region,
                                        enabled: true,
                                        visible: false
                                    },
                                    {
                                        id: "cloudBucket",
                                        label: "Bucket",
                                        value: "textBox",
                                        text: "",//cloud.BucketName,
                                        enabled: true,
                                        visible: false
                                    },
                                    {
                                        id: "updateCloudConfig",
                                        value: "button",
                                        name: "Update",
                                        enabled: false,
                                        visible: false
                                    },
                                    {
                                        label: "HMAC",
                                        value: "radioButton",
                                        id: "hmacMode",
                                        enabled: true,
                                        checked: (cloud.AccountType === "HMAC" || cloud.Provider !== "Google"),
                                        identification: "accountType",
                                        visible: false,
                                        expanded: (cloud.AccountType === "HMAC" || cloud.Provider !== "Google"),
                                        children: [
                                            { id: "cloud_AccessKey", label: "Access Key", value: "textBox", text: cloud.AccessKey, enabled: false, visible: false },
                                            { id: "cloud_SecretKey", label: "Secret Key", value: "textBox", text: cloud.SecretKey, enabled: false, visible: false },
                                            { id: "cloud_Region", label: "Region", value: "textBox", text: cloud.Region, enabled: false, visible: false },
                                            { id: "cloud_Bucket", label: "Bucket", value: "textBox", text: cloud.BucketNameHMAC, enabled: false, visible: false },
                                            {
                                                id: "updateHMACConfig",
                                                value: "button",
                                                name: "Update",
                                                enabled: false,
                                                visible: false
                                            }
                                        ]
                                    },
                                    {
                                        label: "SA",
                                        value: "radioButton",
                                        id: "saMode",
                                        checked: cloud.AccountType === "SA",
                                        identification: "accountType",
                                        enabled: (cloud.Provider === "Google"),
                                        visible: false,
                                        expanded: cloud.AccountType === "SA",
                                        children: [
                                            { id: "bucketNameSA", label: "Bucket Name:", value: "textBox", text: cloud.BucketNameSA, enabled: false, visible: false },
                                            { id: "file", label: "File: ", value: "button", text: "Upload File", name: "Upload file", enabled: false, visible: false },
                                            { id: "fileName", label: "File name:", value: "textBox", text: cloud.ServiceAccountJsonFileName, enabled: false, visible: false },
                                            {
                                                id: "updateSAConfig",
                                                value: "button",
                                                name: "Update",
                                                enabled: false,
                                                visible: false
                                            }
                                        ]
                                    },
                                    {
                                        label: "SAS Token Server Config",
                                        value: "radioButton",
                                        id: "AzureSAS",
                                        checked: cloud.AccountType === "AzureSAS",
                                        identification: "accountType1",
                                        enabled: (cloud.Provider === "Azure"),
                                        visible: true,
                                        expanded: cloud.AccountType === "AzureSAS",
                                        children: [
                                            { id: "accountName_sas", label: "Account Name:", value: "textBox", text: cloud.AzureAccountName, enabled: true, visible: true },
                                            { id: "containerName_sas", label: "Container Name:", value: "textBox", text: cloud.AzureContainerName, enabled: true, visible: true },
                                            { id: "storageKey_sas", label: "File: ", value: "button", text: "Upload File", name: "Upload file", enabled: true, visible: true },
                                            { id: "fileName_sas", label: "File name:", value: "textBox", text: cloud.Provider === "Azure" ? (isSASTokenAvailable ? "sasKey.json" : "sharedKey.json") : "No files selected", enabled: false, visible: true },
                                            { id: "downloadSasKeyConfig", value: "button", name: "Download key", enabled: true, visible: true },
                                            { id: "updateSASConfig", value: "button", name: "Update", enabled: true, visible: true }
                                        ]
                                    },
                                    {
                                        label: "Shared Key Server Config",
                                        value: "radioButton",
                                        id: "AzureSharedKey",
                                        checked: cloud.AccountType === "AzureSharedKey",
                                        identification: "accountType1",
                                        enabled: (cloud.Provider === "Azure"),
                                        visible: true,
                                        expanded: cloud.AccountType === "AzureSharedKey",
                                        children: [
                                            { id: "accountName_sharedKey", label: "Account Name:", value: "textBox", text: cloud.AzureAccountName, enabled: true, visible: true },
                                            { id: "containerName_sharedKey", label: "Container Name:", value: "textBox", text: cloud.AzureContainerName, enabled: true, visible: true },
                                            { id: "storageKey_sharedKey", label: "File: ", value: "button", text: "Upload File", name: "Upload file", enabled: true, visible: true },
                                            { id: "fileName_sharedKey", label: "File name:", value: "textBox", text: cloud.Provider === "Azure" ? (isSASTokenAvailable ? "sharedKey.json" : "sharedKey.json") : "No files selected", enabled: false, visible: true },
                                            { id: "downloadSharedKeyConfig", value: "button", name: "Download key", enabled: true, visible: true },
                                            { id: "updateSharedKeyConfig", value: "button", name: "Update", enabled: true, visible: true }
                                        ]
                                    }
                                ];

                                mode.children = cloudChildren;
                            }
                            else {
                                    const cloudChildren = [
                                        {
                                            id: "cloud_Provider",
                                            label: "Provider",
                                            value: "dropBox",
                                            selected: cloud.Provider,
                                            visible: true,
                                            enabled: true,
                                            children_drop: [
                                                { label1: "Amazon", selected: cloud.Provider === "Amazon" },
                                                { label1: "Google", selected: cloud.Provider === "Google" }
                                            ]
                                        },
                                        {
                                            id: "cloudAccessKey",
                                            label: "Access Key",
                                            value: "textBox",
                                            text: cloud.AccessKey,
                                            enabled: true,
                                            visible: true
                                        },
                                        {
                                            id: "cloudSecretKey",
                                            label: "Secret Key",
                                            value: "textBox",
                                            text: cloud.SecretKey,
                                            enabled: true,
                                            visible: true
                                        },
                                        {
                                            id: "cloudRegion",
                                            label: "Region",
                                            value: "textBox",
                                            text: cloud.Region,
                                            enabled: true,
                                            visible: true
                                        },
                                        {
                                            id: "cloudBucket",
                                            label: "Bucket",
                                            value: "textBox",
                                            text: cloud.BucketName,
                                            enabled: true,
                                            visible: true
                                        },
                                        {
                                            id : "updateCloudConfig",
                                            value: "button",
                                            name: "Update",
                                            enabled: true,
                                            visible: true
                                        },
                                        {
                                            label: "HMAC",
                                            value: "radioButton",
                                            id: "hmacMode",
                                            enabled: false,
                                            checked: false,//(cloud.AccountType === "HMAC" || cloud.Provider !== "Google"),
                                            identification: "accountType",
                                            visible: false,
                                            expanded: false,// (cloud.AccountType === "HMAC" || cloud.Provider !== "Google"),
                                            children: [
                                                { id: "cloud_AccessKey", label: "Access Key", value: "textBox", text:"", enabled: true, visible: false },
                                                { id: "cloud_SecretKey", label: "Secret Key", value: "textBox", text: "", enabled: true, visible: false },
                                                { id: "cloud_Region", label: "Region", value: "textBox", text:"", enabled: true, visible: false },
                                                { id: "cloud_Bucket", label: "Bucket", value: "textBox", text: "", enabled: true, visible: false },
                                                {
                                                    id : "updateHMACConfig",
                                                    value: "button",
                                                    name: "Update",
                                                    enabled: true,
                                                    visible: false
                                                }
                                            ]
                                        },
                                        {
                                            label: "SA",
                                            value: "radioButton",
                                            id: "saMode",
                                            checked: cloud.AccountType === "SA",
                                            identification: "accountType",
                                            enabled: (cloud.Provider === "Google"),
                                            visible: false,
                                            expanded: cloud.AccountType === "SA",
                                            children: [
                                                { id: "bucketNameSA", label: "Bucket Name:", value: "textBox", text: "", enabled: true, visible: false },
                                                { id: "file", label: "File: ", value: "button", text: "Upload File", name: "Upload file", enabled: true, visible: false },
                                                { id: "fileName", label: "File name:", value: "textBox", text: "", enabled: false, visible: false },
                                                {
                                                    id: "updateSAConfig",
                                                    value: "button",
                                                    name: "Update",
                                                    enabled: true,
                                                    visible: false
                                                }
                                            ]
                                        }
                                    ];

                                mode.children = cloudChildren;
                            }
                        }
                    }

                    subItem.children = subItem.children;  // not necessary but retained
                }

                deviceChildren.push(subItem);
            }

            item.children = deviceChildren;
        }

        updatedChildren.push(item);
    }

    wifiProperty = updatedChildren;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getDeviceInformation(configData)
//
//  PURPOSE		:	To fill the Manufacturer, Model, Firmware Version, Serial Number and
//					Hardware ID text fields of the Device Information section.
//
//	ARGUMENTS	:	configData - device info { manufacturer, model, firmwareVersion,
//					serialNumber, hardwareId }
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getDeviceInformation(configData) {
    var updatedChildren = [];

    for (var i = 0; i < wifiProperty.length; i++) {
        var item = wifiProperty[i];

        if (item.label === "Device Information") {
            var deviceInfoChildren = [];

            for (var j = 0; j < item.children.length; j++) {
                var child = item.children[j];

                if (child.label === "Manufacturer: ") {
                    child.text = configData.manufacturer || "";
                }
                if (child.label === "Model: ") {
                    child.text = configData.model || "";
                }
                if (child.label === "Firmware Version: ") {
                    child.text = configData.firmwareVersion || "";
                }
                if (child.label === "Serial Number: ") {
                    child.text = configData.serialNumber || "";
                }
                if (child.label === "Hardware ID: ") {
                    child.text = configData.hardwareId || "";
                }

                deviceInfoChildren.push(child);
            }

            item.children = deviceInfoChildren;
        }

        updatedChildren.push(item);
    }

    wifiProperty = updatedChildren;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getBatteryStatus(batteryStatData)
//
//  PURPOSE		:	To fill the Battery Status and Charging Status fields of the Device
//					Information section and show them (and the Read Battery Status
//					button) only if capabilities.BatteryStatus.
//
//	ARGUMENTS	:	batteryStatData - { batteryStatus, chargingStatus } from the device
//
//	RETURN		:	Array of { id, text, visible } for the fields that were updated
///////////////////////////////////////////////////////////////////////////
function getBatteryStatus(batteryStatData) {
    var updatedChildren = [];
    var changedFields = [];

    for (var i = 0; i < wifiProperty.length; i++) {
        var item = wifiProperty[i];

        if (item.label === "Device Information") {
            var batteryStatChild = [];

            for (var j = 0; j < item.children.length; j++) {
                var child = item.children[j];

                if (child.label === "Battery Status: ") {
                    child.text = batteryStatData.batteryStatus || "";
                    child.visible = capabilities.BatteryStatus
                    changedFields.push({ id: child.id, text: child.text, visible: child.visible });
                }
                if (child.label === "Charging Status: ") {
                    child.text = batteryStatData.chargingStatus || "";
                    child.visible = capabilities.BatteryStatus
                    changedFields.push({ id: child.id, text: child.text, visible: child.visible });
                }
                if (child.id === "readBatteryStatusBtn") {
                    child.visible = capabilities.BatteryStatus
                    changedFields.push({ id: child.id, visible: child.visible });
                }

                batteryStatChild.push(child);
            }

            item.children = batteryStatChild;
        }

        updatedChildren.push(item);
    }

    wifiProperty = updatedChildren;
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateTextBoxField(label, id, newText)
//
//  PURPOSE		:	To store edited text into the matching textBox of the AP/STA mode,
//					Local/Cloud server config or video recording timer config, and update
//					cloudProviderCache / TokenCache for cloud credential fields.
//
//	ARGUMENTS	:	label - label of the text box
//					id - id of the text box
//					newText - text entered by the user
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateTextBoxField(label, id, newText) {
    const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
    if (!deviceConfig) {
        return;
    }
    const wifiConfig = deviceConfig.children.find(c => c.label === "WiFi Configuration");
    const serverConfig = deviceConfig.children.find(c => c.label === "Server Configuration");

    const vidRecConfig = wifiProperty.find(c => c.id === "vidRecTimerConfig");
    // WiFi Mode
    if (!wifiConfig || !wifiConfig.children) {
        return;
    }

    // Iterate over modes: "AP Mode" and "STA Mode"
    for (const modeLabel of ["AP Mode", "STA Mode"]) {
        const mode = wifiConfig.children.find(m => m.label === modeLabel);
        if (mode && Array.isArray(mode.children)) {
            const field = mode.children.find(f =>
                f.label === label && f.id === id && f.value === "textBox"
            );
            if (field) {
                field.text = newText;
                return;
            }
        }
    }

    // Server Mode
    if (serverConfig && serverConfig.children) {
        for (const serverModeLabel of ["Local", "Cloud"]) {
            const serverMode = serverConfig.children.find(m => m.label === serverModeLabel);
            if (!serverMode || !serverMode.children) continue;

            // Handle "Local" directly
            if (serverModeLabel === "Local") {
                const field = serverMode.children.find(f =>
                    f.label === label && f.id === id && f.value === "textBox"
                );
                if (field) {
                    field.text = newText;
                    return;
                }
            }

            if (serverModeLabel === "Cloud") {
                // Determine selected provider from dropBox
                const providerDrop = serverMode.children.find(f =>
                    f.id === "cloud_Provider" && f.value === "dropBox"
                );
                const selectedProvider = providerDrop.selected;

                if (isHmacAndSaAvail || (isAzureConfigAvail && (cloudProvider == "Amazon" || cloudProvider == "Google"))) {
                    for (const accountTypeLabel of ["HMAC", "SA"]) {
                        const accountType = serverMode.children.find(a => a.label === accountTypeLabel);
                        if (!accountType || !accountType.children) continue;

                        const field = accountType.children.find(f =>
                            f.label === label && f.id === id && f.value === "textBox"
                        );
                        if (field) {
                            field.text = newText;

                            //Update cache only for HMAC & if valid provider
                            if (accountTypeLabel === "HMAC" && (selectedProvider === "Amazon" || selectedProvider === "Google")) {
                                switch (id) {
                                    case "cloud_AccessKey":
                                        cloudProviderCache[selectedProvider].AccessKey = newText;
                                        break;
                                    case "cloud_SecretKey":
                                        cloudProviderCache[selectedProvider].SecretKey = newText;
                                        break;
                                    case "cloud_Region":
                                        cloudProviderCache[selectedProvider].Region = newText;
                                        break;
                                    case "cloud_Bucket":
                                        cloudProviderCache[selectedProvider].Bucket = newText;
                                        break;
                                }
                            }
                            return;
                        }
                    }
                }
                else if (isAzureConfigAvail) {
                    for (const accountTypeLabel of ["AzureSAS", "AzureSharedKey"]) {
                        const accountType = serverMode.children.find(a => a.id === accountTypeLabel);
                        if (!accountType || !accountType.children) continue;

                        const field = accountType.children.find(f =>
                            f.label === label && f.id === id && f.value === "textBox"
                        );
                        if (field) {
                            field.text = newText;

                            //Update cache only for AzureSAS or AZureSharedKey & if valid provider
                            if ((accountTypeLabel === "AzureSAS" || accountTypeLabel === "AzureSharedKey") && (selectedProvider === "Azure")) {
                                switch (id) {
                                    case "accountName_sas" : {
                                        if (accountType.checked) {
                                            TokenCache[accountTypeLabel].AccountName = newText;
                                        }
                                        break;
                                    } case"accountName_sharedKey": {
                                        if (accountType.checked) {
                                            TokenCache[accountTypeLabel].AccountName = newText;
                                        }
                                        break;
                                    }
                                    case "containerName_sas" : {
                                        if (accountType.checked) {
                                            TokenCache[accountTypeLabel].ContainerName = newText;
                                        }
                                        break;
                                    }
                                    case "containerName_sharedKey": {
                                        if (accountType.checked) {
                                            TokenCache[accountTypeLabel].ContainerName = newText;
                                        }
                                        break;
                                    }
                                }
                            }
                            return;
                        }
                    }
                }else {
                    const field = serverMode.children.find(f =>
                        f.id === id && f.value === "textBox"
                    );
                    if (field) {
                        field.text = newText;
                        //Update cache only for HMAC & if valid provider
                        if (selectedProvider === "Amazon" || selectedProvider === "Google") {
                            switch (id) {
                                case "cloudAccessKey":
                                    cloudProviderCache[selectedProvider].AccessKey = newText;
                                    break;
                                case "cloudSecretKey":
                                    cloudProviderCache[selectedProvider].SecretKey = newText;
                                    break;
                                case "cloudRegion":
                                    cloudProviderCache[selectedProvider].Region = newText;
                                    break;
                                case "cloudBucket":
                                    cloudProviderCache[selectedProvider].Bucket = newText;
                                    break;
                            }
                        }
                        return;
                    }
                }
            } 
                
        }
    }

    if (vidRecConfig && vidRecConfig.children) {
        const field = vidRecConfig.children.find(f =>
            f.label === label && f.id === id && f.value === "textBox"
        );
        if (field) {
            field.text = newText;
            return;
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateDurationTextBoxField(label, newText, id)
//
//  PURPOSE		:	To set the given time property (e.g. startHour, endMin, sec) of the
//					labelled item in Image Capture Timer Configuration.
//
//	ARGUMENTS	:	label - label of the timer item (Start Time, End Time, Duration...)
//					newText - new value to store
//					id - name of the time property to update
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateDurationTextBoxField(label, newText, id) {

    const timerConfig = wifiProperty.find(item => item.label === "Image Capture Timer Configuration");
    if (!timerConfig || !timerConfig.children) {
        return;
    }

    const targetItem = timerConfig.children.find(child => child.label === label);
    if (!targetItem) {
        return;
    }

    // Update based on ID (e.g., startHour, endMin, hour, min, sec)
    if (id && id.length > 0) {
        if (targetItem.hasOwnProperty(id)) {
            targetItem[id] = newText;
        }
    } 
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getChannelOptions(band)
//
//  PURPOSE		:	To return the AP channel drop-down options for the chosen WiFi band.
//
//	ARGUMENTS	:	band - "2.4 GHz" gives channels 1/6, anything else the 5 GHz list
//
//	RETURN		:	array - list of { label1 } channel options
///////////////////////////////////////////////////////////////////////////
function getChannelOptions(band) {
    if (band === "2.4 GHz") {
        return [{ label1: "1" }, { label1: "6" }];
    } else {
        return [
            { label1: "36" }, { label1: "40" }, { label1: "44" }, { label1: "48" },
            { label1: "149" }, { label1: "153" }, { label1: "157" }, { label1: "161" }
        ];
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleDropBoxValChanged(label, id, newSelection)
//
//  PURPOSE		:	To apply a drop-down selection to the model and handle its side
//					effects: exposure/WB mode (wifiOnvifController.setCamConfig), white
//					balance (setWhiteBalance), AP band -> channel list, STA DHCP/static,
//					cloud provider switch and event recording pre/post duration visibility.
//
//	ARGUMENTS	:	label - label of the drop-down
//					id - id of the drop-down
//					newSelection - newly selected option text
//
//	RETURN		:	array - change objects ({ id, selected/enabled/visible/... }) for the UI
///////////////////////////////////////////////////////////////////////////
function handleDropBoxValChanged(label, id, newSelection) {
    var changedFields = [];  // Track what actually changed

    // Update cloud provider global if applicable
    if (newSelection === "Amazon" || newSelection === "Google" || newSelection === "Azure") {
        cloudProvider = newSelection;
    }

    // --- Update the selected value in the model ---
    updateSelectedValueInModel(label, id, newSelection);

    const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
    const camSettingConfig = wifiProperty.find(item => item.label === "Camera Setting Configuration");
    const imageCapTimerConfig = wifiProperty.find(item => item.label === "Image Capture Timer Configuration");
    const vidPropertiesConfig = wifiProperty.find(item => item.id === "vidProperties");
    const vidRecTimerConfig = wifiProperty.find(item => item.id === "vidRecTimerConfig");

    // --- Handle Camera Setting Configuration ---
    if (camSettingConfig && camSettingConfig.children) {
        const dropBoxField = camSettingConfig.children.find(f =>
            f.label === label && f.id === id && f.value === "dropBox"
        );
        if (dropBoxField) {
            changedFields.push({
                id: id,
                selected: newSelection
            });

            if (id === "exposureMode" || id === "wbMode") {
                var value = (newSelection === "AUTO") ? 0 : 1;
                wifiOnvifController.setCamConfig(id, value);

                if (id === "exposureMode") {
                    isExposureAuto = newSelection === "AUTO";
                    const fieldsToToggle = ["exposure", "gain"];

                    fieldsToToggle.forEach(fieldId => {
                        const field = camSettingConfig.children.find(f => f.id === fieldId);
                        if (field) {
                            field.enabled = !isExposureAuto;
                            changedFields.push({
                                id: fieldId,
                                enabled: !isExposureAuto
                            });
                        }
                    });

                } else if (id === "wbMode") {
                    isWbAuto = newSelection === "AUTO";
                    const field = camSettingConfig.children.find(f => f.id === "whiteBalance");
                    if (field) {
                        field.enabled = !isWbAuto;
                        changedFields.push({
                            id: "whiteBalance",
                            enabled: !isWbAuto
                        });
                    }
                }
            }
            if (id == "whiteBalance") {
                wifiOnvifController.setWhiteBalance(newSelection)
            }

            return changedFields;
        }
    }
    
    // --- Handle WiFi Configuration ---
    if (deviceConfig) {
        const wifiConfig = deviceConfig.children.find(c => c.label === "WiFi Configuration");
        
        if (wifiConfig && wifiConfig.children) {
            for (const mode of ["AP Mode", "STA Mode"]) {
                const modeObj = wifiConfig.children.find(m => m.label === mode);
                if (modeObj && modeObj.children) {
                    const dropBoxField = modeObj.children.find(f =>
                        f.label === label && f.id === id && f.value === "dropBox"
                    );
                    
                    if (dropBoxField) {
                        // WiFi Band -> Channel update (AP Mode only)
                        if (label === "WiFi Band" && mode === "AP Mode") {
                            const bandField = modeObj.children.find(f => f.id === "AP_WifiBand");
                            const channelField = modeObj.children.find(f => f.id === "AP_Channel");

                            if (bandField && channelField) {
                                const band = bandField.selected || "2.4 GHz";
                                const newChannelOptions = getChannelOptions(band);
                                
                                // Store the channel the combo box will show (the new band's first one);
                                // leaving it null sent channel 0 to the SDK unless the user re-picked it.
                                const defaultChannel = newChannelOptions.length > 0 ? newChannelOptions[0].label1 : null;
                                channelField.children_drop = newChannelOptions;
                                channelField.selected = defaultChannel;
                                
                                changedFields.push({
                                    id: "AP_Channel",
                                    options: newChannelOptions,
                                    selected: defaultChannel
                                });
                            }
                        }

                        // STA Mode: DHCP/Static IP handling
                        if (id === "STA_IPMode" && mode == "STA Mode") {
                            const isStatic = newSelection.toUpperCase() === "STATIC";
                            const idsToUpdate = ["STA_IPAddress", "STA_Subnet", "STA_Gateway", "STA_DNS"];
                            
                            modeObj.children.forEach(childField => {
                                if (idsToUpdate.includes(childField.id)) {
                                    childField.enabled = isStatic;
                                    if (!isStatic) {
                                        childField.text = "";
                                    }
                                    changedFields.push({
                                        id: childField.id,
                                        enabled: isStatic,
                                        text: isStatic ? childField.text : ""
                                    });
                                }
                            });
                        }

                        // Add parent dropdown change
                        changedFields.push({
                            id: id,
                            selected: newSelection
                        });
                        
                        return changedFields;
                    }
                }
            }
        }

        // --- Handle Server Configuration ---
        const serverConfig = deviceConfig.children.find(c => c.label === "Server Configuration");
        
        if (serverConfig && serverConfig.children) {
            for (const mode of ["Local", "Cloud"]) {
                const modeObj = serverConfig.children.find(m => m.label === mode);
                if (modeObj && modeObj.children) {
                    const dropBoxField = modeObj.children.find(
                        f => f.label === label && f.id === id && f.value === "dropBox"
                    );

                    if (dropBoxField) {
                        // Cloud Provider selection changes
                        if (label === "Provider" || id === "cloud_Provider") {
                            handleCloudProviderChange(modeObj, newSelection, changedFields);
                        }

                        // Add parent dropdown change
                        changedFields.push({
                            id: id,
                            selected: newSelection
                        });
                        
                        return changedFields;
                    }
                }
            }
        }
    }

    // --- Handle Image Capture Timer Configuration ---
    if (imageCapTimerConfig && imageCapTimerConfig.children) {
        const dropBoxField = imageCapTimerConfig.children.find(f =>
            f.label === label && f.id === id && f.value === "dropBox"
        );
        if (dropBoxField) {
            changedFields.push({
                id: id,
                selected: newSelection
            });
            return changedFields;
        }
    }
    
    // --- HandleVideo Properties Configuration ---
    if (vidPropertiesConfig && vidPropertiesConfig.children) {
        const dropBoxField = vidPropertiesConfig.children.find(f =>
            f.label === label && f.id === id && f.value === "dropBox"
        );
        if (dropBoxField) {
            changedFields.push({
                id: id,
                selected: newSelection
            });
            return changedFields;
        }
    }

    // --- Handle Video Properties Configuration ---
    if (vidRecTimerConfig && vidRecTimerConfig.children) {
        const dropBoxField = vidRecTimerConfig.children.find(f =>
            f.label === label && f.id === id && f.value === "dropBox"
        );

        if (dropBoxField) {
            changedFields.push({
                id: id,
                selected: newSelection
            });

            // --- Handle Event Recording special logic ---
            if (id === "eventRecording") {
                const isEnabled = newSelection === "Enable";


                if (vidRecTimerConfig && vidRecTimerConfig.children) {
                    // Update preEventDuration visibility
                    const preEventField = vidRecTimerConfig.children.find(
                        f => f.id === "preEventDuration"
                    );
                    if (preEventField) {
                        preEventField.visible = isEnabled;
                        changedFields.push({
                            id: "preEventDuration",
                            visible: isEnabled
                        });
                    }

                    // Update postEventDuration visibility
                    const postEventField = vidRecTimerConfig.children.find(
                        f => f.id === "postEventDuration"
                    );
                    if (postEventField) {
                        postEventField.visible = isEnabled;
                        changedFields.push({
                            id: "postEventDuration",
                            visible: isEnabled
                        });
                    }
                }
            }

            return changedFields;
        }
    }

    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSelectedValueInModel(label, id, newSelection)
//
//  PURPOSE		:	To set the selected value (and children_drop selected flags) of the
//					drop-down matching label and id in the device, camera, timer, video
//					recording timer and video properties sections.
//
//	ARGUMENTS	:	label - label of the drop-down
//					id - id of the drop-down
//					newSelection - option text to mark as selected
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// Helper function to update selected value in model
function updateSelectedValueInModel(label, id, newSelection) {
    const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
    const camSettingConfig = wifiProperty.find(item => item.label === "Camera Setting Configuration");
    const imageCapTimerConfig = wifiProperty.find(item => item.label === "Image Capture Timer Configuration");
    const vidRecTimerConfig = wifiProperty.find(item => item.id === "vidRecTimerConfig");
    const vidPropConfig = wifiProperty.find(item => item.id === "vidProperties");

    ///////////////////////////////////////////////////////////////////////////
    //  FUNCTION	:	updateInChildren(children)
    //
    //  PURPOSE		:	To recursively search the children for the node matching id and label
    //					and set its selected value and option flags.
    //
    //	ARGUMENTS	:	children - array of child nodes to search
    //
    //	RETURN		:	bool - true if the node was found and updated
    ///////////////////////////////////////////////////////////////////////////
    // Recursively search and update
    function updateInChildren(children) {
        if (!children) return false;
        
        for (const child of children) {
            if (child.id === id && child.label === label) {
                child.selected = newSelection;
                if (Array.isArray(child.children_drop)) {
                    child.children_drop.forEach(option => {
                        option.selected = (option.label1 === newSelection);
                    });
                }
                return true;
            }
            if (child.children && updateInChildren(child.children)) {
                return true;
            }
        }
        return false;
    }

    if (deviceConfig) updateInChildren(deviceConfig.children);
    if (camSettingConfig) updateInChildren(camSettingConfig.children);
    if (imageCapTimerConfig) updateInChildren(imageCapTimerConfig.children);
    if (vidRecTimerConfig) updateInChildren(vidRecTimerConfig.children);
    if (vidPropConfig) updateInChildren(vidPropConfig.children);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleCloudProviderChange(modeObj, newSelection, changedFields)
//
//  PURPOSE		:	To update the Cloud fields when the provider changes: restore HMAC
//					fields from cloudProviderCache and enable SA only for Google, delegate
//					to handleAzureConfiguration, or restore the plain key fields.
//
//	ARGUMENTS	:	modeObj - Cloud server mode node
//					newSelection - selected provider (Amazon/Google/Azure)
//					changedFields - array that change objects are appended to
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// Helper function to handle cloud provider changes
function handleCloudProviderChange(modeObj, newSelection, changedFields) {
    if (isHmacAndSaAvail) {
        const hmacMode = modeObj.children.find(c => c.id === "hmacMode");
        const saMode = modeObj.children.find(c => c.id === "saMode");

        // Update HMAC fields from cache
        const cached = cloudProviderCache[newSelection];
        if (hmacMode && cached && Array.isArray(hmacMode.children)) {
            const fieldMap = {
                "cloud_AccessKey": cached.AccessKey,
                "cloud_SecretKey": cached.SecretKey,
                "cloud_Region": cached.Region,
                "cloud_Bucket": cached.Bucket
            };

            hmacMode.children.forEach(field => {
                if (field.value === "textBox" && field.id in fieldMap) {
                    field.text = fieldMap[field.id];
                    changedFields.push({
                        id: field.id,
                        text: fieldMap[field.id]
                    });
                }
            });
        }

        // Handle SA mode for Google
        if (saMode && hmacMode) {
            const isGoogle = newSelection === "Google";

            saMode.enabled = isGoogle;
            changedFields.push({
                id: "saMode",
                enabled: isGoogle
            });

            if (isGoogle) {
                if (Array.isArray(saMode.children)) {
                    saMode.children.forEach(child => {
                        const shouldEnable = child.id !== "fileName";
                        child.enabled = shouldEnable;
                        changedFields.push({
                            id: child.id,
                            enabled: shouldEnable
                        });
                    });
                }
            } else {
                saMode.checked = false;
                saMode.expanded = false;
                hmacMode.checked = true;
                hmacMode.expanded = true;
                
                changedFields.push({
                    id: "saMode",
                    checked: false,
                    expanded: false
                });
                changedFields.push({
                    id: "hmacMode",
                    checked: true,
                    expanded: true
                });
            }
        }
    } 
    else if (isAzureConfigAvail) {
        handleAzureConfiguration(modeObj, newSelection, changedFields);
    } 
    else {
        // Simple cloud provider (no HMAC/SA)
        const cached = cloudProviderCache[newSelection];
        if (cached) {
            const fieldMap = {
                "cloudAccessKey": cached.AccessKey,
                "cloudSecretKey": cached.SecretKey,
                "cloudRegion": cached.Region,
                "cloudBucket": cached.Bucket
            };

            modeObj.children.forEach(field => {
                if (field.value === "textBox" && field.id in fieldMap) {
                    field.text = fieldMap[field.id];
                    changedFields.push({
                        id: field.id,
                        text: fieldMap[field.id]
                    });
                }
            });
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleAzureConfiguration(modeObj, newSelection, changedFields)
//
//  PURPOSE		:	To switch the Cloud section between Azure and Amazon/Google: hide the
//					Azure SAS/Shared Key radios (restoring TokenCache text) and show HMAC
//					/SA with cached keys, or hide HMAC/SA and show/expand the Azure radios.
//
//	ARGUMENTS	:	modeObj - Cloud server mode node
//					newSelection - selected provider (Amazon/Google/Azure)
//					changedFields - array that change objects are appended to
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
// Helper function for Azure configuration
function handleAzureConfiguration(modeObj, newSelection, changedFields) {
    const hmacMode = modeObj.children.find(c => c.id === "hmacMode");
    const saMode = modeObj.children.find(c => c.id === "saMode");
    const AzureSAS = modeObj.children.find(c => c.id === "AzureSAS");
    const AzureSharedKey = modeObj.children.find(c => c.id === "AzureSharedKey");

    if (newSelection === "Amazon" || newSelection === "Google") {

        // Hide Azure modes
        [AzureSAS, AzureSharedKey].forEach(mode => {
            if (mode) {
                mode.enabled = false;
                mode.visible = false;
                mode.checked = false;

                changedFields.push({
                    id: mode.id,
                    enabled: false,
                    visible: false,
                    checked: false
                });
                if (mode.children) {
                    mode.children.forEach(field => {
                        field.visible = false;
                        field.enabled = false;

                        var changeObj = {
                            id: field.id,
                            visible: false,
                            enabled: false
                        };

                        // Update text from TokenCache for textBox fields
                        if (field.value === "textBox") {
                            const tokenData = TokenCache[mode.id];

                            if (tokenData) {
                                var textValue = null;

                                if (field.id === "accountName_sharedKey" || field.id === "accountName_sas") {
                                    textValue = tokenData.AccountName || "";
                                } else if (field.id === "containerName_sharedKey" || field.id === "containerName_sas") {
                                    textValue = tokenData.ContainerName || "";
                                } else if (field.id === "fileName_sharedKey" || field.id === "fileName_sas") {
                                    textValue = tokenData.FileName || "";
                                }

                                if (textValue) {
                                    field.text = textValue;
                                    changeObj.text = textValue;
                                }
                            }
                        }

                        changedFields.push(changeObj);
                    });
                }
            }
        });

        // Show HMAC/SA
        [hmacMode, saMode].forEach(mode => {
            if (mode) {
                mode.enabled = true;
                mode.visible = true;
                changedFields.push({
                    id: mode.id,
                    enabled: true,
                    visible: true,
                    checked: mode.checked
                });
            }
        });
        if (newSelection === "Google" && saMode) {
            saMode.enabled = true;
            if (saMode.checked) {
                saMode.expanded = true;
                changedFields.push({
                    id: "saMode",
                    expanded: true
                });
            }
        } else if (newSelection === "Amazon") {
            if (saMode) {
                saMode.checked = false;
                saMode.enabled = false;
                saMode.expanded = false;
                changedFields.push({
                    id: "saMode",
                    checked: false,
                    enabled: false,
                    expanded: false
                });
            }
            if (hmacMode) {
                hmacMode.checked = true;
                hmacMode.expanded = true;
                changedFields.push({
                    id: "hmacMode",
                    checked: true,
                    expanded: true
                });
            }
        }

        // Update HMAC fields from cache
        const cached = cloudProviderCache[newSelection];
        if (hmacMode && cached && Array.isArray(hmacMode.children)) {
            const fieldMap = {
                "cloud_AccessKey": cached.AccessKey,
                "cloud_SecretKey": cached.SecretKey,
                "cloud_Region": cached.Region,
                "cloud_Bucket": cached.Bucket
            };

            hmacMode.children.forEach(field => {
                if (field.value === "textBox" && field.id in fieldMap) {
                    field.text = fieldMap[field.id];
                    field.visible = true;
                    field.enabled = true;
                    changedFields.push({
                        id: field.id,
                        text: fieldMap[field.id],
                        visible: true,
                        enabled: true
                    });
                }
            });
        }

    }
    else {

        // Azure selected - hide HMAC/SA, show Azure
        [hmacMode, saMode].forEach(mode => {
            if (mode) {
                mode.enabled = false;
                mode.visible = false;
                changedFields.push({
                    id: mode.id,
                    enabled: false,
                    visible: false,
                    checked : false
                });
                if (mode.children) {
                    mode.children.forEach(field => {
                        field.visible = false;
                        field.enabled = false;
                        changedFields.push({
                            id: field.id,
                            visible: false,
                            enabled: false
                        });
                    });
                }
            }
        });

        // Show Azure modes
        [AzureSAS, AzureSharedKey].forEach(mode => {
            if (mode) {
                mode.enabled = true;
                mode.visible = true;
                changedFields.push({
                    id: mode.id,
                    enabled: true,
                    visible: true, 
                    checked: mode.checked
                });
            }
        });

        // Expand the checked Azure mode
        if (AzureSharedKey && AzureSharedKey.checked) {
            AzureSharedKey.expanded = true;
            changedFields.push({
                id: "AzureSharedKey",
                expanded: true
            });
            if (AzureSharedKey.children) {
                AzureSharedKey.children.forEach(field => {
                    field.visible = true;
                    field.enabled = !["fileName", "fileName_sharedKey", "fileName_sas"].includes(field.id);
                    changedFields.push({
                        id: field.id,
                        visible: true,
                        enabled: field.enabled
                    });
                });
            }
        }
        else if (AzureSAS) {
            isSAS = true
            AzureSAS.checked = true;
            AzureSAS.expanded = true;
            changedFields.push({
                id: "AzureSAS",
                checked: true,
                expanded: true
            });
            if (AzureSAS.children) {
                AzureSAS.children.forEach(field => {
                    field.visible = true;
                    field.enabled = !["fileName", "fileName_sharedKey", "fileName_sas"].includes(field.id);
                    changedFields.push({
                        id: field.id,
                        visible: true,
                        enabled: field.enabled
                    });
                });
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSliderVal(label, id, newValue)
//
//  PURPOSE		:	To store a slider value in Camera Setting Configuration; for zoom,
//					disables pan and tilt when zoom is 1.
//
//	ARGUMENTS	:	label - label of the slider
//					id - id of the slider
//					newValue - new slider value
//
//	RETURN		:	array - change objects for the UI (undefined if the slider is not found)
///////////////////////////////////////////////////////////////////////////
function updateSliderVal(label, id, newValue) {
    const changedFields = [];
    const camSettingConfig = wifiProperty.find(item => item.label === "Camera Setting Configuration");
    if (camSettingConfig) {
        if (camSettingConfig.children) {
            const sliderField = camSettingConfig.children.find(f =>
                f.label === label && f.id === id && f.value === "slider"
            );
            if (sliderField) {
                sliderField.currentValue = newValue;
                changedFields.push({
                    id: id,
                    currentValue: newValue
                });

                if (id === "zoom") {
                    const isZoomOne = (newValue == 1);

                    camSettingConfig.children.forEach(f => {
                        if (f.id === "pan" || f.id === "tilt") {
                            f.enabled = !isZoomOne;
                            changedFields.push({
                                id: f.id,
                                enabled: !isZoomOne
                            });
                        }
                    });
                }

                return changedFields;
            }
        }
    } else {
        return changedFields;
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateRadioButton(mode, label, checked)
//
//  PURPOSE		:	To handle a radio button click for WiFi mode (AP/STA), server mode
//					(Local/Cloud), cloud account type (HMAC/SA, restored from cache) or
//					Azure auth type (SAS/Shared Key, saved to/restored from TokenCache):
//					sets checked/expanded/visible state of the radios and their children.
//
//	ARGUMENTS	:	mode - radio group: WiFiMode, ServerMode, accountType or accountType1
//					label - label of the clicked radio button
//					checked - new checked state
//
//	RETURN		:	array - change objects for the UI
///////////////////////////////////////////////////////////////////////////
function updateRadioButton(mode, label, checked) {
    var changedFields = [];

    const deviceConfig = wifiProperty.find(item => item.label === "Device Configuration");
    if (!deviceConfig) {
        return changedFields;
    }
    
    const wifiConfig = deviceConfig.children.find(c => c.label === "WiFi Configuration");
    const serverConfig = deviceConfig.children.find(c => c.label === "Server Configuration");

    // ============================================
    // For WiFi Mode (AP mode / STA mode)
    // ============================================
    if (mode === "WiFiMode" && wifiConfig && wifiConfig.children) {
        for (const radio of wifiConfig.children) {
            if (radio.label === label) {
                // ========== SELECTED RADIO BUTTON ==========
                radio.checked = checked;
                radio.visible = true;

                if (radio.checked) {
                    radio.expanded = true;
                    logController.expandedItem(radio.id);
                } else {
                    radio.expanded = false;
                }

                changedFields.push({
                    id: radio.id,
                    checked: checked,
                    expanded: radio.expanded,
                    visible: true
                });

                // Show/hide children based on checked state
                if (radio.children && Array.isArray(radio.children)) {
                    radio.children.forEach(child => {
                        child.visible = checked;

                        // ✅ Create change object with text if it's a textBox
                        var childChange = {
                            id: child.id,
                            visible: checked
                        };

                        if (child.value === "textBox" && child.text !== undefined) {
                            childChange.text = child.text;
                        }

                        if (child.value === "dropBox") {
                            childChange.selected = child.selected;
                            childChange.children_drop = child.children_drop
                        }

                        changedFields.push(childChange);
                    });
                }
            }
            else if (["AP Mode", "STA Mode"].includes(radio.label)) {
                // ========== UNCHECKED RADIO BUTTONS ==========
                radio.checked = false;
                radio.expanded = false;
                radio.visible = true;

                changedFields.push({
                    id: radio.id,
                    checked: false,
                    expanded: false,
                    visible: true
                });

                // Hide children of unchecked radio
                if (radio.children && Array.isArray(radio.children)) {
                    radio.children.forEach(child => {
                        child.visible = false;

                        // ✅ Create change object with text if it's a textBox (even when hidden)
                        var childChange = {
                            id: child.id,
                            visible: false
                        };

                        if (child.value === "textBox" && child.text !== undefined) {
                            childChange.text = child.text;
                        }

                        if (child.value === "dropBox") {
                            childChange.selected = child.selected;
                            childChange.children_drop = child.children_drop
                        }

                        changedFields.push(childChange);
                    });
                }
            }
        }

        return changedFields;
    }

    // ============================================
    // For Server Mode (Local/Cloud)
    // ============================================
    if (mode === "ServerMode" && serverConfig && serverConfig.children) {
        const updateChildVisibility = (item, parentChecked) => {
            // Update current child visibility/enabled
            item.visible = parentChecked;
            item.enabled = parentChecked;

            // Special case for Amazon provider
            if (cloudProvider === "Amazon" && item.id === "saMode") {
                item.enabled = false;
            }

            // Build change object
            const childChange = {
                id: item.id,
                visible: item.visible,
                enabled: item.enabled
            };

            // Add text value if it’s a textBox
            if (item.value === "textBox" && item.text !== undefined) {
                childChange.text = item.text;
            }

            changedFields.push(childChange);

            // 🔁 Recursively handle grandchildren
            if (item.children && Array.isArray(item.children)) {
                item.children.forEach(grandchild => {
                    updateChildVisibility(grandchild, parentChecked);
                });
            }
        };

        for (const radio of serverConfig.children) {
            if (radio.label === label) {
                // Selected radio button
                radio.checked = checked;
                radio.visible = true;
                radio.expanded = checked;

                if (checked) {
                    logController.expandedItem(radio.id);
                }

                changedFields.push({
                    id: radio.id,
                    checked: radio.checked,
                    expanded: radio.expanded,
                    visible: true
                });

                //  Recursively handle children (and grandchildren)
                if (radio.children && Array.isArray(radio.children)) {
                    radio.children.forEach(child => updateChildVisibility(child, checked));
                }

            }
            else if (radio.label === "Local" || radio.label === "Cloud") {
                // Unchecked radio buttons
                radio.checked = false;
                radio.expanded = false;
                radio.visible = true;

                changedFields.push({
                    id: radio.id,
                    checked: false,
                    expanded: false,
                    visible: true
                });

                //  Recursively disable all descendants
                if (radio.children && Array.isArray(radio.children)) {
                    radio.children.forEach(child => updateChildVisibility(child, false));
                }
            }
        }
        return changedFields;
    }

    // ============================================
    // Handle HMAC/SA selection (nested under Cloud)
    // ============================================

    if (isHmacAndSaAvail || (isAzureConfigAvail && (cloudProvider == "Amazon" || cloudProvider == "Google"))) {
        if (mode === "accountType" && serverConfig && serverConfig.children) {
            const cloudMode = serverConfig.children.find(c => c.label === "Cloud");

            if (!cloudMode) {
                return changedFields;
            }

            // ✅ Get cached values for current cloud provider
            const cached = cloudProviderCache[cloudProvider];

            for (const radio of cloudMode.children) {
                if (radio.label === label) {
                    // ========== CLICKED RADIO BUTTON ==========
                    radio.checked = checked;

                    if (radio.checked) {
                        // CHECKED: Show and populate fields
                        radio.expanded = true;
                        radio.visible = true;

                        changedFields.push({
                            id: radio.id,
                            checked: true,
                            expanded: true,
                            visible: true
                        });

                        // Show and enable children with cached values
                        radio.children.forEach(field => {
                            field.visible = true;
                            field.enabled = !["fileName", "fileName_sharedKey", "fileName_sas"].includes(field.id);

                            // Update text fields with cached values
                            if (field.value === "textBox" && cached) {
                                const fieldMapping = {
                                    "cloud_AccessKey": "AccessKey",
                                    "cloud_SecretKey": "SecretKey",
                                    "cloud_Region": "Region",
                                    "cloud_Bucket": "Bucket"
                                };

                                if (field.id in fieldMapping) {
                                    const cacheKey = fieldMapping[field.id];
                                    if (cached[cacheKey]) {
                                        field.text = cached[cacheKey];

                                        changedFields.push({
                                            id: field.id,
                                            visible: true,
                                            enabled: field.enabled,
                                            text: cached[cacheKey]  // ✅ Text from cache
                                        });
                                    } else {
                                        changedFields.push({
                                            id: field.id,
                                            visible: true,
                                            enabled: field.enabled
                                        });
                                    }
                                } else {
                                    changedFields.push({
                                        id: field.id,
                                        visible: true,
                                        enabled: field.enabled
                                    });
                                }
                            } else {
                                changedFields.push({
                                    id: field.id,
                                    visible: true,
                                    enabled: field.enabled
                                });
                            }
                        });

                        logController.expandedItem("serverCloud");

                    }
                    else {
                        // UNCHECKED: Collapse but update cache
                        radio.expanded = false;
                        radio.visible = true;

                        changedFields.push({
                            id: radio.id,
                            checked: false,
                            expanded: false,
                            visible: true
                        });

                        // Hide children BUT update their text values from cache
                        radio.children.forEach(field => {
                            field.visible = false;
                            field.enabled = !["fileName", "fileName_sharedKey", "fileName_sas"].includes(field.id);

                            // ✅ Update text even when hiding
                            if (field.value === "textBox" && cached) {
                                const fieldMapping = {
                                    "cloud_AccessKey": "AccessKey",
                                    "cloud_SecretKey": "SecretKey",
                                    "cloud_Region": "Region",
                                    "cloud_Bucket": "Bucket"
                                };

                                if (field.id in fieldMapping) {
                                    const cacheKey = fieldMapping[field.id];
                                    if (cached[cacheKey]) {
                                        field.text = cached[cacheKey];

                                        changedFields.push({
                                            id: field.id,
                                            visible: false,
                                            enabled: field.enabled,
                                            text: cached[cacheKey]  // ✅ Text from cache even when hidden
                                        });
                                    } else {
                                        changedFields.push({
                                            id: field.id,
                                            visible: false,
                                            enabled: field.enabled
                                        });
                                    }
                                }
                                else {
                                    changedFields.push({
                                        id: field.id,
                                        visible: false,
                                        enabled: field.enabled
                                    });
                                }
                            }
                            else {
                                changedFields.push({
                                    id: field.id,
                                    visible: false,
                                    enabled: field.enabled
                                });
                            }
                        });
                    }
                }
                else if (["HMAC", "SA"].includes(radio.label)) {
                    // ========== OTHER UNCHECKED RADIO BUTTONS ==========
                    // Keep visible but collapsed, AND UPDATE CACHE
                    radio.checked = false;
                    radio.expanded = false;
                    radio.visible = true;

                    changedFields.push({
                        id: radio.id,
                        checked: false,
                        expanded: false,
                        visible: true
                    });

                    // ✅ CRITICAL: Hide children BUT update text from cache
                    if (radio.children && Array.isArray(radio.children)) {
                        radio.children.forEach(field => {
                            field.visible = false;
                            field.enabled = !["fileName", "fileName_sharedKey", "fileName_sas"].includes(field.id);

                            // ✅ Update text from cache even for other unchecked radios
                            if (field.value === "textBox" && cached) {
                                const fieldMapping = {
                                    "cloud_AccessKey": "AccessKey",
                                    "cloud_SecretKey": "SecretKey",
                                    "cloud_Region": "Region",
                                    "cloud_Bucket": "Bucket"
                                };


                                if (field.id in fieldMapping) {
                                    
                                    const cacheKey = fieldMapping[field.id];
                                    if (cached[cacheKey]) {
                                        field.text = cached[cacheKey];

                                        changedFields.push({
                                            id: field.id,
                                            visible: false,
                                            text: cached[cacheKey]  // ✅ Include text from cache
                                        });
                                    } else {
                                        changedFields.push({
                                            id: field.id,
                                            visible: false
                                        });
                                    }
                                } else {
                                    changedFields.push({
                                        id: field.id,
                                        visible: false
                                    });
                                }
                            } else {
                                changedFields.push({
                                    id: field.id,
                                    visible: false
                                });
                            }
                        });
                    }
                }
            }

            return changedFields;
        }
    }

    // ============================================
    // For SAS / Shared Key in Azure
    // ============================================
    else if (isAzureConfigAvail) {
        if (mode === "accountType1" && serverConfig && serverConfig.children) {
            const cloudMode = serverConfig.children.find(c => c.label === "Cloud");

            if (!cloudMode) {
                return changedFields;
            }

            // === STEP 1: Save current values to TokenCache before switching ===
            for (const radio of cloudMode.children) {
                if (radio.checked === true && radio.label !== label) {
                    // Save the currently checked radio's data before switching
                    if (["AzureSharedKey", "AzureSAS"].includes(radio.id)) {
                        // Ensure TokenCache exists for this radio
                        if (!TokenCache[radio.id]) {
                            TokenCache[radio.id] = {
                                AccountName: "",
                                ContainerName: "",
                                FileName: ""
                            };
                        }

                        // Save current field values to cache
                        radio.children.forEach(field => {
                            if (field.id === "accountName_sharedKey" || field.id === "accountName_sas") {
                                TokenCache[radio.id].AccountName = field.text || "";
                            } else if (field.id === "containerName_sharedKey" || field.id === "containerName_sas") {
                                TokenCache[radio.id].ContainerName = field.text || "";
                            } else if (field.id === "fileName_sharedKey" || field.id === "fileName_sas") {
                                TokenCache[radio.id].FileName = field.text || "";
                            }
                        });
                    }
                }
            }

            // === STEP 2: Update all radio buttons ===
            for (const radio of cloudMode.children) {
                if (radio.label === label && checked) {
                    // === SELECTED RADIO BUTTON ===
                    radio.checked = true;
                    radio.expanded = true;
                    radio.visible = true;

                    changedFields.push({
                        id: radio.id,
                        checked: true,
                        expanded: true,
                        visible: true
                    });

                    // Show and enable children with cached values
                    if (radio.children && Array.isArray(radio.children)) {
                        radio.children.forEach(field => {
                            field.visible = true;
                            field.enabled = !["fileName", "fileName_sharedKey", "fileName_sas"].includes(field.id);
                            var changeObj = {
                                id: field.id,
                                visible: true,
                                enabled: field.enabled
                            };

                            // Restore text from TokenCache if available
                            if (field.value === "textBox" && ["AzureSharedKey", "AzureSAS"].includes(radio.id)) {
                                const tokenData = TokenCache[radio.id];
                                if (tokenData) {

                                    var textValue = null;

                                    if (field.id === "accountName_sharedKey" || field.id === "accountName_sas") {
                                        textValue = tokenData.AccountName || "";
                                    } else if (field.id === "containerName_sharedKey" || field.id === "containerName_sas") {
                                        textValue = tokenData.ContainerName || "";
                                    } else if (field.id === "fileName_sharedKey" || field.id === "fileName_sas") {
                                        textValue = tokenData.FileName || "";
                                    }

                                    field.text = textValue;
                                    changeObj.text = textValue;
                                }
                            }

                            changedFields.push(changeObj);
                        });
                    }

                    logController.expandedItem("serverCloud");
                }
                else if (["AzureSharedKey", "AzureSAS"].includes(radio.id)) {
                    // === UNSELECTED AZURE AUTH TYPES ===
                    radio.checked = false;
                    radio.expanded = false;
                    radio.visible = true;

                    changedFields.push({
                        id: radio.id,
                        checked: false,
                        expanded: false,
                        visible: true
                    });

                    // Hide children
                    if (radio.children && Array.isArray(radio.children)) {
                        radio.children.forEach(field => {
                            field.visible = false;

                            changedFields.push({
                                id: field.id,
                                visible: false
                            });
                        });
                    }
                }
            }

            return changedFields;
        }
    }
    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSpinValueField(label, text, id)
//
//  PURPOSE		:	To set the given time property (e.g. startHour, endMin, sec) of the
//					labelled item in Image Capture Timer Configuration from a spin box.
//
//	ARGUMENTS	:	label - label of the timer item
//					text - new spin box value
//					id - name of the time property to update
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSpinValueField(label, text, id) {
    // Find the Timer Configuration block
    const timerConfig = wifiProperty.find(item => item.label === "Image Capture Timer Configuration");
    if (!timerConfig || !timerConfig.children) {
        return;
    }

    // Find the specific item under Timer Configuration (e.g., Start Time, End Time, Duration)
    const targetItem = timerConfig.children.find(child => child.label === label);
    if (!targetItem) {
        return;
    }

    // Update based on ID (e.g., startHour, endMin, hour, min, sec)
    if (id && id.length > 0) {
        if (targetItem.hasOwnProperty(id)) {
            targetItem[id] = text;
        } 
    } 
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	timerdata(configData)
//
//  PURPOSE		:	To copy start/end time, duration and selected values from the device
//					timer config into the matching items of Image Capture Timer
//					Configuration.
//
//	ARGUMENTS	:	configData - timer config object whose children carry the values
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function timerdata(configData) {

    for (var i = 0; i < wifiProperty.length; i++) {
        if (wifiProperty[i].label === "Image Capture Timer Configuration") {

            if (configData.children && configData.children.length > 0) {
                for (var c = 0; c < configData.children.length; c++) {
                    var childData = configData.children[c];

                    if (childData.children_drop) {
                        for (var d = 0; d < childData.children_drop.length; d++) {
                            var subChild = childData.children_drop[d];
                        }
                    }

                    // Now find the corresponding child inside wifiProperty[i].children
                    for (var j = 0; j < wifiProperty[i].children.length; j++) {
                        var targetChild = wifiProperty[i].children[j];

                        if (targetChild.label === childData.label) {
                            if (childData.startHour !== undefined) {
                                targetChild.startHour = childData.startHour;
                                targetChild.startMin = childData.startMin;
                                targetChild.startSec = childData.startSec;
                            }

                            if (childData.endHour !== undefined) {
                                targetChild.endHour = childData.endHour;
                                targetChild.endMin = childData.endMin;
                                targetChild.endSec = childData.endSec;
                            }

                            if (childData.hour !== undefined) {
                                targetChild.hour = childData.hour;
                                targetChild.min = childData.min;
                                targetChild.sec = childData.sec;
                            }

                            if (childData.selected !== undefined) {
                                targetChild.selected = childData.selected;
                            }
                        }
                    }
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getSharedKeys()
//
//  PURPOSE		:	To return the cached Azure shared key, SAS token and whether SAS is
//					the active account type.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	object - { sharedKey, sasToken, isSAS }
///////////////////////////////////////////////////////////////////////////
function getSharedKeys() {
    return {
        sharedKey: sharedKey,
        sasToken: sasToken,
        isSAS: isSAS
    };
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setIsOEM(isOEM)
//
//  PURPOSE		:	To store whether the connected camera is the OEM variant.
//
//	ARGUMENTS	:	isOEM - true for the OEM variant
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setIsOEM(isOEM) {
    isOEMVariant = isOEM;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setOEMPropertiesVisibility()
//
//  PURPOSE		:	To show the OEM-only sections (power off, snapshot, video properties,
//					recording, recording timer, SD card) and set camera setting control
//					visibility from capabilities, when the camera is the OEM variant.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setOEMPropertiesVisibility() {
    if (isOEMVariant) {
        for (let i = 0; i < wifiProperty.length; i++) {
            if (wifiProperty[i].id === "powerOff") {
                wifiProperty[i].visible = true;
                continue;
            }
            if (wifiProperty[i].id === "snapshot") {
                wifiProperty[i].visible = true;
                continue
            }
            if (wifiProperty[i].id === "camSettingsConfig") {
                for (let j = 0; j < wifiProperty[i].children.length; j++) {
                    const item = wifiProperty[i].children[j].id;
                    if (item === "brightness") wifiProperty[i].children[j].visible = capabilities.Brightness;
                    if (item === "contrast") wifiProperty[i].children[j].visible = capabilities.Contrast;
                    if (item === "saturation") wifiProperty[i].children[j].visible = capabilities.Saturation;
                    if (item === "sharpness") wifiProperty[i].children[j].visible = capabilities.Sharpness;
                    if (item === "frameRate") wifiProperty[i].children[j].visible = capabilities.FPS;
                    if (item === "exposureMode") wifiProperty[i].children[j].visible = capabilities.ExposureMode;
                    if (item === "exposure") wifiProperty[i].children[j].visible = capabilities.ExposureMode;
                    if (item === "gain") wifiProperty[i].children[j].visible = capabilities.ExposureMode;
                    if (item === "wbMode") wifiProperty[i].children[j].visible = capabilities.wbMode;
                    if (item === "whiteBalance") wifiProperty[i].children[j].visible = capabilities.wbMode;
                    if (item === "pan") wifiProperty[i].children[j].visible = capabilities.Pan && capabilities.Zoom;
                    if (item === "tilt") wifiProperty[i].children[j].visible = capabilities.Tilt && capabilities.Zoom;
                    if (item === "zoom") wifiProperty[i].children[j].visible = capabilities.Zoom;
                    if (item === "setCameraConfigDefault") wifiProperty[i].children[j].visible = isOEMVariant;
                }
            }
            if (wifiProperty[i].id == "vidProperties") {
                wifiProperty[i].visible = true
                continue;
            }
            if (wifiProperty[i].id == "vidRecording") {
                wifiProperty[i].visible = true
                continue;
            }
            if (wifiProperty[i].id == "vidRecTimerConfig") {
                wifiProperty[i].visible = true
                continue;
            }
            if (wifiProperty[i].id == "sdCard") {
                wifiProperty[i].visible = true
                continue;
            }
        }
    }
}
///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCameraConfig(configData)
//
//  PURPOSE		:	To fill Camera Setting Configuration from the device config: anti-
//					banding and quantization always; for OEM also exposure/WB modes, white
//					balance and brightness/contrast/fps/saturation/sharpness/pan/tilt/zoom/
//					exposure/gain ranges, with enable and capability-based visibility.
//
//	ARGUMENTS	:	configData - camera config read from the device
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function getCameraConfig(configData) {
    var updatedChildren = [];
    for (let i = 0; i < wifiProperty.length; i++) {
        let item = wifiProperty[i];
        if (item.label === "Camera Setting Configuration") {
            var camConfigChild = [];
            for (let j = 0; j < item.children.length; j++) {
                let child = item.children[j];

                // --- DropBox fields ---
                if (child.id === "Anti-Banding") {
                    child.selected = configData.antiBanding;
                }
                if (isOEMVariant) {
                    if (child.id === "exposureMode") {
                        child.selected = configData.exposureMode.current === 1 ? "MANUAL" : "AUTO";
                        isExposureAuto = (configData.exposureMode.current !== 1);
                        child.visible = capabilities.ExposureMode
                    }
                    if (child.id === "wbMode") {
                        child.selected = configData.wbMode.current === 1 ? "MANUAL" : "AUTO";
                        isWbAuto = (configData.wbMode.current !== 1);
                        child.visible = capabilities.wbMode
                    }
                    if (child.id === "whiteBalance") {
                        child.selected = configData.whiteBalance;
                        child.enabled = !isWbAuto;
                        child.visible = capabilities.wbMode
                    }
                }

                // --- Slider fields ---
                if (child.id === "Quantization") {
                    child.currentValue = configData.qFactor.current;
                    child.min = configData.qFactor.min;
                    child.max = configData.qFactor.max;
                }
                if (isOEMVariant) {
                    if (child.id === "brightness") {
                        child.currentValue = configData.brightness.current;
                        child.min = configData.brightness.min;
                        child.max = configData.brightness.max;
                        child.visible = capabilities.Brightness
                    }
                    if (child.id === "contrast") {
                        child.currentValue = configData.contrast.current;
                        child.min = configData.contrast.min;
                        child.max = configData.contrast.max;
                        child.visible = capabilities.Contrast
                    }
                    if (child.id === "frameRate") {
                        child.currentValue = configData.frameRate.current;
                        child.min = configData.frameRate.min;
                        child.max = configData.frameRate.max;
                        child.visible = capabilities.FPS
                    }
                    if (child.id === "saturation") {
                        child.currentValue = configData.saturation.current;
                        child.min = configData.saturation.min;
                        child.max = configData.saturation.max;
                        child.visible = capabilities.Saturation
                    }
                    if (child.id === "sharpness") {
                        child.currentValue = configData.sharpness.current;
                        child.min = configData.sharpness.min;
                        child.max = configData.sharpness.max;
                        child.visible = capabilities.Sharpness
                    }
                    if (child.id === "pan") {
                        child.enabled = configData.zoom.current !== 1;
                        child.visible = capabilities.Pan && capabilities.Zoom
                    }
                    if (child.id === "tilt") {
                        child.enabled = configData.zoom.current !== 1;
                        child.visible = capabilities.Tilt && capabilities.Zoom
                    }
                    if (child.id === "zoom") {
                        child.currentValue = configData.zoom.current;
                        child.min = configData.zoom.min;
                        child.max = configData.zoom.max;
                        child.visible = capabilities.Zoom
                    }
                    if (child.id === "exposure") {
                        child.currentValue = configData.exposure.current;
                        child.min = configData.exposure.min;
                        child.max = configData.exposure.max;
                        child.enabled = !isExposureAuto;
                        child.visible = capabilities.ExposureMode
                    }
                    if (child.id === "gain") {
                        child.currentValue = configData.Gain.current;
                        child.min = configData.Gain.min;
                        child.max = configData.Gain.max;
                        child.enabled = !isExposureAuto;
                        child.visible = capabilities.ExposureMode
                    }
                }

                camConfigChild.push(child);
            }
            item.children = camConfigChild;
        }
        updatedChildren.push(item);
    }
    wifiProperty = updatedChildren;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateWBValue(wbValue)
//
//  PURPOSE		:	To set the selected white balance value in Camera Setting
//					Configuration and enable it only when WB mode is manual.
//
//	ARGUMENTS	:	wbValue - white balance option to select
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateWBValue(wbValue) {
    for (let i = 0; i < wifiProperty.length; i++) {
        let item = wifiProperty[i];
        if (item.label === "Camera Setting Configuration") {
            for (let j = 0; j < item.children.length; j++) {
                let child = item.children[j];
                if (child.id === "whiteBalance") {
                    child.selected = wbValue;
                    child.enabled = !isWbAuto
                    break;
                }
            }
            break;
        }
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateAvailableResolutions(list)
//
//  PURPOSE		:	To set the children_drop list of the vidProperties node to the given
//					resolutions.
//
//	ARGUMENTS	:	list - array of resolution strings ("WxH")
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateAvailableResolutions(list) {
    for (let i = 0; i < wifiProperty.length; i++) {
        if (wifiProperty[i].id === "vidProperties") {
            // create a new array of objects { label1: "WxH" }
            let arr = [];
            for (let j = 0; j < list.length; j++) {
                arr.push({ "label1": list[j] });
            }

            // assign the new array to children_drop
            wifiProperty[i].children_drop = arr;
        }
    }
}


///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCurrentResolution(currentResolution)
//
//  PURPOSE		:	To set the selected value of the first child (resolution) of the
//					vidProperties node.
//
//	ARGUMENTS	:	currentResolution - resolution string to select
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCurrentResolution(currentResolution) {
    for (let i = 0; i < wifiProperty.length; i++) {
        if (wifiProperty[i].id == "vidProperties") {
            wifiProperty[i].children[0].selected = currentResolution
        }
    }
}


///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSDCardInfo(info)
//
//  PURPOSE		:	To fill the SD card total/used/free GB and status message fields,
//					hiding the size fields whose value is empty.
//
//	ARGUMENTS	:	info - { totalGb, usedGb, freeGb, message } from the device
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateSDCardInfo(info) {
    var updatedChildren = [];
    for (var i = 0; i < wifiProperty.length; i++) {
        var item = wifiProperty[i];

        if (item.id === "sdCard") {
            var sdCardInfoChildren = [];

            for (var j = 0; j < item.children.length; j++) {
                var child = item.children[j];

                if (child.id === "totalGb") {
                    child.text = (info.totalGb + " GB") || "";
                    if (info.totalGb == "") {
                        child.visible = false
                    }
                }
                if (child.id === "usedGb") {
                    child.text = (info.usedGb + " GB") || "";
                    if (info.usedGb == "") {
                        child.visible = false
                    }
                }
                if (child.id === "freeGb") {
                    child.text = (info.freeGb + " GB") || "";
                    if (info.freeGb == "") {
                        child.visible = false
                    }
                }
                if (child.id === "statusMsg") {
                    child.text = info.message || "";
                }

                sdCardInfoChildren.push(child);
            }

            item.children = sdCardInfoChildren;
        }

        updatedChildren.push(item);
    }

    wifiProperty = updatedChildren;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateVidRecConfig(vidRecConfigData)
//
//  PURPOSE		:	To fill the video recording timer fields (duration, pre/post event
//					duration, circular and event recording); pre/post event are shown only
//					when event recording is enabled and capabilities.Trigger is set.
//
//	ARGUMENTS	:	vidRecConfigData - video recording config read from the device
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateVidRecConfig(vidRecConfigData) {
    var updatedChildren = [];
    for (var i = 0; i < wifiProperty.length; i++) {
        var item = wifiProperty[i];

        if (item.id === "vidRecTimerConfig") {
            var vidRecConfigChildren = [];

            for (var j = 0; j < item.children.length; j++) {
                var child = item.children[j];        
                if (child.id === "vidRecDuration") {
                    child.text = vidRecConfigData.vidRecDuration || "";
                }
                if (child.id === "preEventDuration") {
                    child.selected = vidRecConfigData.preEventDuration || "";
                    if (vidRecConfigData.eventRecording == "Disable"){
                        child.visible = false
                    } else if (vidRecConfigData.eventRecording == "Enable"){
                        child.visible = true
                    }
                    child.visible =  child.visible && capabilities.Trigger

                }
                if (child.id === "postEventDuration") {
                    child.selected = vidRecConfigData.postEventDuration || "";
                    if (vidRecConfigData.eventRecording == "Disable"){
                        child.visible = false
                    } else if (vidRecConfigData.eventRecording == "Enable") {
                        child.visible = true
                    }
                    child.visible = child.visible && capabilities.Trigger
                }
                if (child.id === "circularRecording") {
                    child.selected = vidRecConfigData.circularRecording || "";
                }
                if (child.id === "eventRecording" ) {
                    child.selected = vidRecConfigData.eventRecording || "";
                    child.visible = capabilities.Trigger
                }

                vidRecConfigChildren.push(child);
            }

            item.children = vidRecConfigChildren;
        }

        updatedChildren.push(item);
    }

    wifiProperty = updatedChildren;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setDefaultResolution(resolution)
//
//  PURPOSE		:	To set the selected value of the resolution drop-down in the
//					vidProperties section.
//
//	ARGUMENTS	:	resolution - resolution string to select
//
//	RETURN		:	array - change object with the resolution and its options
///////////////////////////////////////////////////////////////////////////
function setDefaultResolution(resolution) {
    var changedFields = [];
    const vidPropertiesConfig = wifiProperty.find(item => item.id === "vidProperties");
    if (vidPropertiesConfig && vidPropertiesConfig.children) {
        const dropBoxField = vidPropertiesConfig.children.find(f =>
            f.id === "resolution" && f.value === "dropBox"
        );
        if (dropBoxField) {
            dropBoxField.selected = resolution

            changedFields.push({
                id: "resolution",
                selected: resolution, 
                options: dropBoxField.children_drop
            });
            return changedFields;
        }
    }

    return changedFields;
}


///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	buildCameraIndex(cameraNode)
//
//  PURPOSE		:	To recursively add a node and its children to cameraUiIndex keyed by
//					id.
//
//	ARGUMENTS	:	cameraNode - property node to index
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function buildCameraIndex(cameraNode) {
    if (!cameraNode || typeof cameraNode !== "object")
        return;

    if (cameraNode.id)
        cameraUiIndex[cameraNode.id] = cameraNode;

    if (cameraNode.children) {
        cameraNode.children.forEach(buildCameraIndex);
    }
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	findCameraSettingsRoot()
//
//  PURPOSE		:	To find the camSettingsConfig node in wifiProperty.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	object - the camera settings node, or null if not found
///////////////////////////////////////////////////////////////////////////
/* 🔹 Find cameraSettings root */
function findCameraSettingsRoot() {
    if (!Array.isArray(wifiProperty))
        return null;

    for (var i = 0; i < wifiProperty.length; i++) {
        if (wifiProperty[i].id === "camSettingsConfig")
            return wifiProperty[i];
    }
    return null;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	buildCameraUiIndex(node)
//
//  PURPOSE		:	To recursively add a node and its children to cameraUiIndex keyed by
//					id, defaulting slider currentValue to min and checkbox to false.
//
//	ARGUMENTS	:	node - property node to index
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
/* 🔹 Build id → node map */
function buildCameraUiIndex(node) {
    if (!node || typeof node !== "object")
        return;

    if (node.id) {
        if (node.value === "slider" && node.currentValue === undefined)
            node.currentValue = node.min ;

        if (node.value === "checkbox" && node.currentValue === undefined)
            node.currentValue = false;

        if (node.value === "dropBox")
            node.selected = node.selected;

        cameraUiIndex[node.id] = node;
    }

    if (node.children)
        node.children.forEach(buildCameraUiIndex);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	initCameraUiIndex()
//
//  PURPOSE		:	To locate the camera settings node and rebuild cameraUiIndex from it;
//					logs an error if the node is missing.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
/* 🔹 Initialize */
function initCameraUiIndex() {
    cameraConfigNode = findCameraSettingsRoot();

    if (!cameraConfigNode) {
        console.error("cameraSettings node not found");
        return;
    }

    cameraUiIndex = {};
    buildCameraUiIndex(cameraConfigNode);
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setUiDefaultValues(values)
//
//  PURPOSE		:	To apply default camera values to the indexed slider/drop-down nodes,
//					enabling pan/tilt by zoom and exposure/gain/white balance by the
//					manual exposure/WB mode.
//
//	ARGUMENTS	:	values - object mapping control id to its default value
//
//	RETURN		:	array - change objects for the UI
///////////////////////////////////////////////////////////////////////////
function setUiDefaultValues(values) {
    initCameraUiIndex();
    var changedFields = [];
    if (!values || !cameraConfigNode)
        return changedFields;

    Object.keys(values).forEach(function (id) {
        var node = cameraUiIndex[id];
        if (!node)
            return;
        var newValue = values[id];
        var changed = { id: id };

        /* ---------- SLIDER ---------- */
        if (node.value === "slider") {
            if (node.currentValue !== newValue) {
                node.currentValue = newValue;
                changed.value = newValue;
                changed.currentValue = newValue;
            }


            if (id === "zoom") {
                var isZoomOne = (newValue == 1);
                var panNode = cameraUiIndex["pan"];
                if (panNode) {
                    panNode.enabled = !isZoomOne;
                    changedFields.push({ id: "pan", enabled: !isZoomOne });
                }
                var tiltNode = cameraUiIndex["tilt"];
                if (tiltNode) {
                    tiltNode.enabled = !isZoomOne;
                    changedFields.push({ id: "tilt", enabled: !isZoomOne });
                }

            }
        }

        /* ---------- DROPBOX ---------- */
        else if (node.value === "dropBox" && node.children_drop) {
            var selectedIndex = -1;
            for (var i = 0; i < node.children_drop.length; i++) {
                if (node.children_drop[i].label1 === newValue) {
                    selectedIndex = i;
                    break;
                }
            }
            if (selectedIndex !== -1 && node.selected !== selectedIndex) {
                node.selected = selectedIndex;
                node.currentValue = newValue;
                changed.options = node.children_drop;
                changed.selected = newValue;
            }

            /* --- ExposureMode: disable/enable Exposure and Gain --- */
            if (id === "exposureMode") {
                var isManual = (newValue === "MANUAL");

                var exposureNode = cameraUiIndex["exposure"];
                var gainNode = cameraUiIndex["gain"];

                if (exposureNode) {
                    exposureNode.enabled = isManual;
                    changedFields.push({ id: "exposure", enabled: isManual });
                }
                if (gainNode) {
                    gainNode.enabled = isManual;
                    changedFields.push({ id: "gain", enabled: isManual });
                }
            }

            /* --- WBMode: disable/enable White Balance --- */
            if (id === "wbMode") {
                var isManual = (newValue === "MANUAL");

                var whiteBalanceNode = cameraUiIndex["whiteBalance"];

                if (whiteBalanceNode) {
                    whiteBalanceNode.enabled = isManual;
                    changedFields.push({ id: "whiteBalance", enabled: isManual });
                }
            }
        }

        if (Object.keys(changed).length > 1)
            changedFields.push(changed);
    });

    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	sdCardEjected()
//
//  PURPOSE		:	To hide the SD card free/used/total GB fields after the card is
//					ejected.
//
//	ARGUMENTS	:	None
//
//	RETURN		:	array - change objects for the fields that were hidden
///////////////////////////////////////////////////////////////////////////
function sdCardEjected() {
    const sdCardInfoConfig = wifiProperty.find(item => item.id === "sdCard");
    const changedFields = [];

    if (sdCardInfoConfig && sdCardInfoConfig.children) {
        const idsToHide = ["freeGb", "usedGb", "totalGb"];

        sdCardInfoConfig.children.forEach(child => {
            if (idsToHide.includes(child.id) && child.visible === true) {
                child.visible = false;
                changedFields.push({
                    id: child.id,
                    visible: false
                });
            }
        });
    }

    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateSDCardinfo(message)
//
//  PURPOSE		:	To set the SD card status message text field.
//
//	ARGUMENTS	:	message - status message to display
//
//	RETURN		:	array - change object for statusMsg
///////////////////////////////////////////////////////////////////////////
function updateSDCardinfo(message) {
    const sdCardInfoConfig = wifiProperty.find(item => item.id === "sdCard");
    const changedFields = [];

    if (sdCardInfoConfig && sdCardInfoConfig.children) {

        sdCardInfoConfig.children.forEach(child => {
            if (child.id == "statusMsg") {
                child.text = message;
                changedFields.push({
                    id: child.id,
                    text: message
                });
            }
        });
    }

    return changedFields;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setCapabilities(capability)
//
//  PURPOSE		:	To store the camera capability flags used to decide control
//					visibility.
//
//	ARGUMENTS	:	capability - capability object (Brightness, Zoom, Trigger ...)
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setCapabilities(capability) {
    capabilities = capability
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	handleVidRecStatus(vidRecStatus)
//
//  PURPOSE		:	To handle the video recording status from the view; currently a
//					placeholder with no implementation.
//
//	ARGUMENTS	:	vidRecStatus - video recording status
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function handleVidRecStatus(vidRecStatus) {

}