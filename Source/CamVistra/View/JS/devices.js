var modelData = [];

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To replace the cached device list (modelData) with the device
//					JSON array supplied by the caller.
//
//	ARGUMENTS	:	jsonArray - array of device objects to store as the current
//					  device model
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    modelData = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getModelDevices()
//
//  PURPOSE		:	To return the device list most recently stored by
//					updateModelData().
//
//	ARGUMENTS	:	None
//
//	RETURN		:	Array - the cached device model data
///////////////////////////////////////////////////////////////////////////
// Export the model data
function getModelDevices() {
    return modelData;
}
