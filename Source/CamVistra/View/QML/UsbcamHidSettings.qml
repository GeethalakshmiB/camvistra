import QtQuick 2.12
import QtQuick.Controls 2.12
import See3CAM130E 1.0
import See3CAM1318_TC 1.0
import See3CAMCU31 1.0
import See3CAMCU83 1.0
import See3CAM27CUG 1.0
import See3CAM37CUG 1.0
import See3CAMCU130 1.0
import See3CAMCU135M_H01R1 1.0
import See3CAMCU135 1.0
import See3CAMCU200M 1.0
import See3CAMCU200 1.0
import See3CAM24CUG 1.0
import See3CAMCU81 1.0
import See3CAMCU58 1.0
import See3CAMCU55 1.0
import See3CAMCU55MH 1.0
import See3CAMCU27 1.0
import See3CAM160 1.0
import See3CAMCU84 1.0
import See3CAMCU512M 1.0
import DensiCAM 1.0
import DeviceEnums 1.0
import "../JS/Usb_Hid.js" as UsbcamExtensionModelData
import "../JS/Usb.js" as UscambModelData
import "../JS/See3CAM_130E.js" as See3CAM130EModelData
import "../JS/See3CAM_1318_TC.js" as See3CAM1318_TCModelData
import "../JS/See3CAM_CU31.js" as See3CAMCU31ModelData
import "../JS/See3CAM_CU83.js" as See3CAMCU83ModelData
import "../JS/See3CAM_27CUG.js" as See3CAM27CUGModelData
import "../JS/See3CAM_37CUG.js" as See3CAM37CUGModelData
import "../JS/See3CAM_CU130.js" as See3CAMCU130ModelData
import "../JS/See3CAM_CU135M_H01R1.js" as See3CAMCU135M_H01R1ModelData
import "../JS/See3CAM_CU135.js" as See3CAMCU135ModelData
import "../JS/See3CAM_CU200M.js" as See3CAMCU200MModelData
import "../JS/See3CAM_CU200.js" as See3CAMCU200ModelData
import "../JS/See3CAM_24CUG.js" as See3CAM24CUGModelData
import "../JS/See3CAM_CU81.js" as See3CAMCU81ModelData
import "../JS/See3CAM_CU27.js" as See3CAMCU27ModelData
import "../JS/See3CAM_160.js" as See3CAM160ModelData
import "../JS/See3CAM_CU84.js" as See3CAMCU84ModelData
import "../JS/See3CAM_CU512M.js" as See3CAMCU512MModelData
import "../JS/See3CAM_CU58.js" as See3CAMCU58ModelData
import "../JS/See3CAM_CU55.js" as See3CAMCU55ModelData
import "../JS/See3CAM_CU55MH.js" as See3CAMCU55MHModelData
import "../JS/DensiCAM.js" as DensiCAMModelData

UsbcamHidAccordion {
    id: usbcamHidAcc
    anchors.margins: 10
    width: usbcamRect.width - 20
	height : implicitHeight
	visible: true
    property var usbcamHidProperty  
    // True when the camera has no extension controls and only the message entry is shown
    readonly property bool showsNoExtensionMessage: !!usbcamHidProperty && usbcamHidProperty.length === 1
        && !!usbcamHidProperty[0] && usbcamHidProperty[0].id === "noHid"
	property var result
	property var hidScrollHeight : 0
	usbcamHidProperty: UsbcamExtensionModelData.getUsbcamExtensionModelData()
	
	property int heightVal : propertyCount * 0.052 * screenHeight
	model: usbcamHidProperty

	Timer {
        id:       delayedControlsTimer
        interval: 500
        repeat:   false
		onTriggered: {
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					See3CAM130EModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_1318_TC:
					See3CAM1318_TCModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU31:
					See3CAMCU31ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU83:
					See3CAMCU83ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_27CUG:
					See3CAM27CUGModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_37CUG:
					See3CAM37CUGModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU130:
					See3CAMCU130ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU135M_H01R1:
					See3CAMCU135M_H01R1ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU135:
					See3CAMCU135ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU200M:
					See3CAMCU200MModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU200:
					See3CAMCU200ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_24CUG:
					See3CAM24CUGModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU81:
					See3CAMCU81ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU512M:
					See3CAMCU512MModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU84:
					See3CAMCU84ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU27:
					See3CAMCU27ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_160:
					See3CAM160ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU58:
				case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
					See3CAMCU58ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU55:
					See3CAMCU55ModelData.getDelayedCameraControls(); break
				case DeviceEnums.See3CAM_CU55_MH:
					See3CAMCU55MHModelData.getDelayedCameraControls(); break
				case DeviceEnums.DensiCAM:
					DensiCAMModelData.getDelayedCameraControls(); break
				default: break
			}
		}
    }

	Timer {
		id : getAutoFocusControlValues
		interval: 500
        repeat:   false
		onTriggered: {
			//const DeviceEnums = DeviceEnums
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					See3CAM130EModelData.getAutoFocusControls(); break
				case DeviceEnums.See3CAM_1318_TC:
					See3CAM1318_TCModelData.getAutoFocusControls(); break
				default: break
			}
		}
	}

	Timer {
		id : getexposureCompFrameRateCtrlTimer
		repeat:   false
		interval: 500
		onTriggered: {
			//const DeviceEnums = DeviceEnums
			const devType = currentDevType()
			switch(devType) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					See3CAM130EModelData.getexposureCompFrameRateCtrl(); break
				case DeviceEnums.See3CAM_1318_TC:
					See3CAM1318_TCModelData.getexposureCompFrameRateCtrl(); break
				case DeviceEnums.See3CAM_CU58:
				case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
					See3CAMCU58ModelData.getexposureCompFrameRateCtrl(); break
				case DeviceEnums.See3CAM_CU55:
					See3CAMCU55ModelData.getexposureCompFrameRateCtrl(); break
				default: break
			}
		}
	}

	Timer {
		id : getAutoExposureControlValues
		interval: 500
        repeat:   false
		onTriggered: {
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					See3CAM130EModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_1318_TC:
					See3CAM1318_TCModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU130:
					See3CAMCU130ModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU135M_H01R1:
					See3CAMCU135M_H01R1ModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU135:
					See3CAMCU135ModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_24CUG:
					See3CAM24CUGModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU81:
					See3CAMCU81ModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_160:
					See3CAM160ModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU84:
					See3CAMCU84ModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU27:
					See3CAMCU27ModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU512M:
					See3CAMCU512MModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU58:
				case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
					See3CAMCU58ModelData.getAutoExposureControls(); break
				case DeviceEnums.See3CAM_CU55:
					See3CAMCU55ModelData.getAutoExposureControls(); break
				default: break
			}
		}
	}

	Connections{
		target: prevController
		// Handles prevController.extensionJsonArrayRead signal: for the selected device only,
		// stores the extension-control JSON as the accordion model and forwards it to the
		// generic and camera-specific JS model (updateModelData) for the current device type.
		function onExtensionJsonArrayRead(jsonArray) {
			if (index !== usbcamRect.selectedIndex) return;
			usbcamHidProperty = jsonArray;
			UsbcamExtensionModelData.updateModelData(jsonArray);
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					See3CAM130EModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_1318_TC:
					See3CAM1318_TCModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU31:
					See3CAMCU31ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU83:
					See3CAMCU83ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_27CUG:
					See3CAM27CUGModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_37CUG:
					See3CAM37CUGModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU130:
					See3CAMCU130ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU135M_H01R1:
					See3CAMCU135M_H01R1ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU135:
					See3CAMCU135ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU200M:
					See3CAMCU200MModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU200:
					See3CAMCU200ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_24CUG:
					See3CAM24CUGModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU81:
					See3CAMCU81ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU84:
					See3CAMCU84ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU27:
					See3CAMCU27ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU512M:
					See3CAMCU512MModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_160:
					See3CAM160ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU58:
				case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
					See3CAMCU58ModelData.updateModelData(jsonArray); break
				case DeviceEnums.See3CAM_CU55_MH:
					See3CAMCU55MHModelData.updateModelData(jsonArray); break
				case DeviceEnums.DensiCAM:
					DensiCAMModelData.updateModelData(jsonArray); break
				default: break
			}
		}

		// Handles prevController.cameraClosed signal: calls clearData() on the JS model of
		// the current device type to reset its cached control state.
		function onCameraClosed(){
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					See3CAM130EModelData.clearData(); break
				case DeviceEnums.See3CAM_1318_TC:
					See3CAM1318_TCModelData.clearData(); break
				case DeviceEnums.See3CAM_CU31:
					See3CAMCU31ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU83:
					See3CAMCU83ModelData.clearData(); break
				case DeviceEnums.See3CAM_27CUG:
					See3CAM27CUGModelData.clearData(); break
				case DeviceEnums.See3CAM_37CUG:
					See3CAM37CUGModelData.clearData(); break
				case DeviceEnums.See3CAM_CU130:
					See3CAMCU130ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU135M_H01R1:
					See3CAMCU135M_H01R1ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU135:
					See3CAMCU135ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU200M:
					See3CAMCU200MModelData.clearData(); break
				case DeviceEnums.See3CAM_CU200:
					See3CAMCU200ModelData.clearData(); break
				case DeviceEnums.See3CAM_24CUG:
					See3CAM24CUGModelData.clearData(); break
				case DeviceEnums.See3CAM_CU81:
					See3CAMCU81ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU84:
					See3CAMCU84ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU27:
					See3CAMCU27ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU512M:
					See3CAMCU512MModelData.clearData(); break
				case DeviceEnums.See3CAM_160:
					See3CAM160ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU58:
				case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
					See3CAMCU58ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU55:
					See3CAMCU55ModelData.clearData(); break
				case DeviceEnums.See3CAM_CU55_MH:
					See3CAMCU55MHModelData.clearData(); break
				case DeviceEnums.DensiCAM:
					DensiCAMModelData.clearData(); break
				default: break
			}
		}
		// Handles prevController.currentImagePropChanged signal: when the selected device is a
		// 130E/130E_H02R1/CU58/CU55_CHLCW_H21R1/1318_TC, starts the delayed timer that re-reads
		// exposure compensation and frame-rate control (resolution/format change).
		function onCurrentImagePropChanged(index) {
			if(index == selectedIndex){
				const devType = currentDevType()
				if (devType === DeviceEnums.See3CAM_130E || devType === DeviceEnums.See3CAM_130E_H02R1 ||
					devType === DeviceEnums.See3CAM_CU58 || devType === DeviceEnums.See3CAM_CU55_CHLCW_H21R1 ||  devType === DeviceEnums.See3CAM_1318_TC) {
					getexposureCompFrameRateCtrl()
				}
			}
		}


	}

	Connections {
		target : usbcamRect
		// Handles usbcamRect.setExposureMode signal (UVC auto/manual exposure switch): lets the
		// device JS model enable/disable dependent HID controls (default: exposure compensation)
		// and emits fieldChanged/fieldOptionsChanged for each returned change.
		function onSetExposureMode(mode){
			var changedFields
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					changedFields = See3CAM130EModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_1318_TC:
					changedFields = See3CAM1318_TCModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU130:
					changedFields = See3CAMCU130ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU135M_H01R1:
					changedFields = See3CAMCU135M_H01R1ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU135:
					changedFields = See3CAMCU135ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_24CUG:
					changedFields = See3CAM24CUGModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU81:
					changedFields = See3CAMCU81ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_160:
					changedFields = See3CAM160ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU84:
					changedFields = See3CAMCU84ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU58:
				case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
					changedFields = See3CAMCU58ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU55:
					changedFields = See3CAMCU55ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU135:
					changedFields = See3CAMCU135ModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU200M:
					changedFields = See3CAMCU200MModelData.setExposureMode(mode); break
				case DeviceEnums.See3CAM_CU200:
					changedFields = See3CAMCU200ModelData.setExposureMode(mode); break
				default:
					changedFields = UsbcamExtensionModelData.enableOrDisableExposureComp(mode); break
			}
			if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i];
					
					if (change.hasOwnProperty('enabled')) {
						// Notify specific field about enabled state change
						usbcamHidAcc.fieldChanged(change.id, change.enabled);
					}
					
					if (change.hasOwnProperty('options')) {
						// Notify specific field about options change
						usbcamHidAcc.fieldOptionsChanged(change.id, change.selected);
					}

					if (change.hasOwnProperty('selected')) {
						// Notify about value change for label update
						usbcamHidAcc.fieldOptionsChanged(change.id, change.selected);
					}
				}
			}
		}

		// Handles usbcamRect.setFocusMode signal (UVC auto/manual focus switch): for 130E/1318_TC
		// updates the dependent HID focus controls and emits fieldChanged/fieldOptionsChanged.
		function onSetFocusMode(mode){
			var changedFields
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					changedFields = See3CAM130EModelData.setFocusMode(mode); break
				case DeviceEnums.See3CAM_1318_TC:
					changedFields = See3CAM1318_TCModelData.setFocusMode(mode); break
				default: break
			}
			if (changedFields && changedFields.length > 0) {
				for (var i = 0; i < changedFields.length; i++) {
					var change = changedFields[i];
					
					if (change.hasOwnProperty('enabled')) {
						// Notify specific field about enabled state change
						usbcamHidAcc.fieldChanged(change.id, change.enabled);
					}

					if (change.hasOwnProperty('selected')) {
						// Notify about value change for label update
						usbcamHidAcc.fieldOptionsChanged(change.id, change.selected);
					}
				}
			}
		}

		// Handles usbcamRect.setUvcAntiFlicker signal: syncs the HID anti-flicker selection with
		// the UVC power-line value for 24CUG/CU81/CU27 and refreshes the changed fields.
		function onSetUvcAntiFlicker(value){
			var changedFields
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_24CUG:
					changedFields = See3CAM24CUGModelData.setUvcAntiFlickerMode(value); break
				case DeviceEnums.See3CAM_CU81:
					changedFields = See3CAMCU81ModelData.setUvcAntiFlickerMode(value); break
				case DeviceEnums.See3CAM_CU27:
					changedFields = See3CAMCU27ModelData.setUvcAntiFlickerMode(value); break
				default: break
			}
			triggerUpdateSignal(changedFields)
		}
		// Handles usbcamRect.setUvcGainValue signal: for CU135M_H01R1 passes the UVC gain to
		// the JS model (setUvcGainValue) and refreshes the changed fields.
		function onSetUvcGainValue(value){
			var changedFields
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_CU135M_H01R1:
					changedFields = See3CAMCU135M_H01R1ModelData.setUvcGainValue(value); break
				default: break
			}
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3cam27cugController
		// Helper for the See3CAM_27CUG handlers below: pushes the changed-field list to the UI
		// via triggerUpdateSignal().
		function a27(c){triggerUpdateSignal(c)}
		function onStreamModeReceived(v){a27(See3CAM27CUGModelData.updateStream(v))}
		function onStrobeModeReceived(v){a27(See3CAM27CUGModelData.updateStrobe(v))}
		function onCameraModeReceived(v){a27(See3CAM27CUGModelData.updateCamera(v))}
		function onOrientationReceived(v){a27(See3CAM27CUGModelData.updateOrientation(v))}
		function onBrightnessReceived(v){a27(See3CAM27CUGModelData.slider("brightnessSlider",v))}
		function onContrastReceived(v){a27(See3CAM27CUGModelData.slider("contrastSlider",v))}
		function onGainReceived(v){a27(See3CAM27CUGModelData.slider("gainSlider",v))}
		function onMinimumExposureReceived(v){a27(See3CAM27CUGModelData.text("minExpTextField",v))}
		function onMaximumExposureReceived(v){a27(See3CAM27CUGModelData.text("maxExpTextField",v))}
		function onSerialNumberReceived(v){a27(See3CAM27CUGModelData.text("serialNumber",v))}
	}
	Connections {
		target: see3cam37cugController
		// Helper for the See3CAM_37CUG handlers below: pushes the changed-field list to
		// the UI via triggerUpdateSignal().
		function apply37CUG(changes) { triggerUpdateSignal(changes) }
		function onCameraModeReceived(value) { apply37CUG(See3CAM37CUGModelData.updateCameraMode(value)) }
		function onOrientationReceived(value) { apply37CUG(See3CAM37CUGModelData.updateOrientation(value)) }
		function onGainPropertiesReceived(mode, feature, minimum, maximum, current, step) { apply37CUG(See3CAM37CUGModelData.updateGain(mode, feature, minimum, maximum, current, step)) }
		function onStrobeModeReceived(value) { apply37CUG(See3CAM37CUGModelData.updateStrobe(value)) }
		function onBurstLengthReceived(value) { apply37CUG(See3CAM37CUGModelData.updateBurst(value)) }
		function onExposurePropertiesReceived(mode, feature, seconds, milliSeconds, microSeconds) { apply37CUG(See3CAM37CUGModelData.updateExposure(mode, feature, seconds, milliSeconds, microSeconds)) }
		function onTargetBrightnessReceived(minimum, maximum, step, current) { apply37CUG(See3CAM37CUGModelData.updateTargetBrightness(minimum, maximum, step, current)) }
		function onAntiFlickerModeReceived(value) { apply37CUG(See3CAM37CUGModelData.updateAntiFlicker(value)) }
		function onStatisticsReceived(seconds, milliSeconds, microSeconds, gain) { apply37CUG(See3CAM37CUGModelData.updateStatistics(seconds, milliSeconds, microSeconds, gain)) }
		function onTemperatureReceived(value) { apply37CUG(See3CAM37CUGModelData.updateTemperature(value)) }
		function onFastAutoExposureReceived(value) { apply37CUG(See3CAM37CUGModelData.updateFastAutoExposure(value)) }
		function onExposureCompensationReceived(seconds, milliSeconds, microSeconds) { apply37CUG(See3CAM37CUGModelData.updateExposureCompensation(seconds, milliSeconds, microSeconds)) }
		function onFaeTargetBrightnessReceived(minimum, maximum, step, current) { apply37CUG(See3CAM37CUGModelData.updateFAETargetBrightness(minimum, maximum, step, current)) }
		function onFaeExecutionFramesReceived(value) { apply37CUG(See3CAM37CUGModelData.updateFAEExecutionFrames(value)) }
		function onIspFirmwareVersionReceived(value) { apply37CUG(See3CAM37CUGModelData.updateISPFirmwareVersion(value)) }
	}
	Connections {
		target: see3camcu83Controller
		// Helper for the See3CAM_CU83 handlers below: pushes the changed-field list to
		// the UI via triggerUpdateSignal().
		function applyCU83(c) { triggerUpdateSignal(c) }
		function onSpecialModeReceived(v){applyCU83(See3CAMCU83ModelData.updateSpecial(v))}
		function onDenoiseValueReceived(v){applyCU83(See3CAMCU83ModelData.updateDenoise(v))}
		function onRoiAutoExpReceived(m,s){applyCU83(See3CAMCU83ModelData.updateROI(m,s))}
		function onOrientationReceived(v){applyCU83(See3CAMCU83ModelData.updateOrientation(v))}
		function onExposureCompensationReceived(v){applyCU83(See3CAMCU83ModelData.updateExposure(v))}
		function onFrameRateReceived(v,min,max){applyCU83(See3CAMCU83ModelData.updateFrameRate(v,min,max))}
		function onBurstLengthReceived(v){applyCU83(See3CAMCU83ModelData.updateBurst(v))}
		function onAntiFlickerReceived(v){applyCU83(See3CAMCU83ModelData.updateFlicker(v))}
		function onWakeOnMotionReceived(v){applyCU83(See3CAMCU83ModelData.updateWake(v))}
		function onFaceDetectionReceived(e,o,d){applyCU83(See3CAMCU83ModelData.updateFace(e,o,d))}
		function onStreamModeReceived(v){applyCU83(See3CAMCU83ModelData.updateStream(v))}
		function onFlashModeReceived(v){applyCU83(See3CAMCU83ModelData.updateFlash(v))}
	}

	Connections {
		target: see3camcu31Controller
		// Helper for the See3CAM_CU31 handlers below: pushes the changed-field list to
		// the UI via triggerUpdateSignal().
		function applyCU31(changes) { triggerUpdateSignal(changes) }
		function onOrientationReceived(value) { applyCU31(See3CAMCU31ModelData.updateOrientation(value)) }
		function onRawNoiseReductionReceived(value) { applyCU31(See3CAMCU31ModelData.updateRNR(value)) }
		function onTriggerModeReceived(value) { applyCU31(See3CAMCU31ModelData.updateTrigger(value)) }
		function onAeConvergenceSpeedReceived(value) { applyCU31(See3CAMCU31ModelData.updateAESpeed(value)) }
		function onAutoExposureStatusReceived(value) { applyCU31(See3CAMCU31ModelData.updateAEStatus(value)) }
		function onAwbStatusReceived(value) { applyCU31(See3CAMCU31ModelData.updateAWBStatus(value)) }
		function onTemperatureReceived(value) { applyCU31(See3CAMCU31ModelData.setText("readTempTextField", value)) }
		function onAntiFlickerModeReceived(value) { applyCU31(See3CAMCU31ModelData.updateFlicker(value)) }
		function onCameraModeReceived(value) { applyCU31(See3CAMCU31ModelData.updateCameraMode(value)) }
		function onAeWindowOverlayReceived(value) { applyCU31(See3CAMCU31ModelData.updateOverlay("AEWindow", value)) }
		function onAeWindowDimensionsReceived(w,h,x,y) { applyCU31(See3CAMCU31ModelData.updateAEWindow(w,h,x,y)) }
		function onAeMaskOverlayReceived(value) { applyCU31(See3CAMCU31ModelData.updateOverlay("AEMask", value)) }
		function onAeMaskDimensionsReceived(includeId,id,state,w,h,x,y) { applyCU31(See3CAMCU31ModelData.updateAEMask(includeId,id,state,w,h,x,y)) }
		function onAwbWindowOverlayReceived(value) { applyCU31(See3CAMCU31ModelData.updateOverlay("AWBWindow", value)) }
		function onAwbWindowDimensionsReceived(w,h,x,y) { applyCU31(See3CAMCU31ModelData.updateAWBWindow(w,h,x,y)) }
		function onAwbMaskOverlayReceived(value) { applyCU31(See3CAMCU31ModelData.updateOverlay("AWBMask", value)) }
		function onAwbMaskDimensionsReceived(includeId,id,state,w,h,x,y) { applyCU31(See3CAMCU31ModelData.updateAWBMask(includeId,id,state,w,h,x,y)) }
		function onPresetPropertiesReceived(mode, operation) { applyCU31(See3CAMCU31ModelData.updatePreset(mode)) }
		function onSerialNumberReceived(value) { applyCU31(See3CAMCU31ModelData.setText("serial_no_selected", value)) }
		function onIspFirmwareVersionReceived(value) { applyCU31(See3CAMCU31ModelData.setText("ispFirmwareVersion", value)) }
	}

	Connections {
		target : ecam212usbUvcextController
		function onFirmwareVersionReceived(firmwareVer){
			UsbcamExtensionModelData.updateFirmwareVersioninUI(firmwareVer)
		}
		// Handles ecam212usbUvcextController.hdrModeReceived signal: updates the HDR mode in the
		// generic extension model and reloads usbcamHidProperty so the accordion re-renders.
		function onHdrModeReceived(value){
			UsbcamExtensionModelData.updateHDRMode(value)
			usbcamHidProperty = UsbcamExtensionModelData.getUsbcamExtensionModelData()
		}
		function onAeModeReceived(value){
			UsbcamExtensionModelData.updateAEMode(value)
		}
		function onExpCompMaxReceived(min, max, value){
			UsbcamExtensionModelData.updateExpCompMaxRange(min, max, value)
		}
		function onExpCompMinReceived(min, max, value){
			UsbcamExtensionModelData.updateExpCompMinRange(min, max, value)
		}
		function onHorizontalFlipReceived(value){
			UsbcamExtensionModelData.updateHorizontalFlip(value)
		}
		function onVerticalFlipReceived(value){
			UsbcamExtensionModelData.updateVerticalFlip(value)
		}
	}

	Connections {
		target: see3camcu200mController
		// Handles see3camcu200mController.streamModeReceived signal: passes the value(s) to
		// See3CAMCU200MModelData.updateStreamMode() (only when the selected device is
		// See3CAM_CU200M) and refreshes the changed fields.
		function onStreamModeReceived(streamMode) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu200mController.flashModeReceived signal: passes the value(s) to
		// See3CAMCU200MModelData.updateFlashMode() (only when the selected device is
		// See3CAM_CU200M) and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu200mController.orientationReceived signal: passes the value(s) to
		// See3CAMCU200MModelData.updateOrientation() (only when the selected device is
		// See3CAM_CU200M) and refreshes the changed fields.
		function onOrientationReceived(flipMode) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateOrientation(flipMode)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu200mController.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU200MModelData.updateSerialNumber() (only when the selected device is
		// See3CAM_CU200M) and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu200mController.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU200MModelData.updateFirmwareVersioninUI() (only when the selected device is
		// See3CAM_CU200M) and refreshes the changed fields.
		function onFirmwareVersionReceived(firmwareVersion) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu200Controller
		// Helper for the See3CAM_CU200 handlers below: pushes the changed-field list to the
		// UI via triggerUpdateSignal() only when the selected device is a See3CAM_CU200.
		function cu200(c){ if (currentDevType() === DeviceEnums.See3CAM_CU200) triggerUpdateSignal(c) }
		function onBrightnessReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateBrightness(min,max,step,current))}
		function onContrastReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateContrast(min,max,step,current))}
		function onSaturationReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateSaturation(min,max,step,current))}
		function onGammaReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateGamma(min,max,step,current))}
		function onSharpnessReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateSharpness(min,max,step,current))}
		function onBlackLevelReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateBlackLevel(min,max,step,current))}
		function onTargetBrightnessReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateTargetBrightness(min,max,step,current))}
		function onColorTemperatureReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateColorTemperature(min,max,step,current))}
		function onRGainReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateRGain(min,max,step,current))}
		function onBGainReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateBGain(min,max,step,current))}
		function onColorCorrectionMatrixReceived(Rr,Rg,Rb,Gr,Gg,Gb,Br,Bg,Bb){cu200(See3CAMCU200ModelData.updateColorCorrectionMatrix(Rr,Rg,Rb,Gr,Gg,Gb,Br,Bg,Bb))}
		function onExposureReceived(mode,autoFeature,manualValue){cu200(See3CAMCU200ModelData.updateExposure(mode,autoFeature,manualValue))}
		function onExposureCompensationReceived(value){cu200(See3CAMCU200ModelData.updateExposureCompensation(value))}
		function onAutoGainUpperLimitReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateAutoGainUpperLimit(min,max,step,current))}
		function onAutoExpROIReceived(roiMode,winSize){cu200(See3CAMCU200ModelData.updateAutoExpROI(roiMode,winSize))}
		function onCameraModeReceived(cameraMode){cu200(See3CAMCU200ModelData.updateCameraMode(cameraMode))}
		function onStrobeModeReceived(strobeMode){cu200(See3CAMCU200ModelData.updateStrobeMode(strobeMode))}
		function onOrientationReceived(flipMode){cu200(See3CAMCU200ModelData.updateOrientation(flipMode))}
		function onAntiFlickerModeReceived(antiFlicker){cu200(See3CAMCU200ModelData.updateAntiFlickerMode(antiFlicker))}
		function onWhiteBalanceReceived(mode,autoFeature,manualFeature){cu200(See3CAMCU200ModelData.updateWhiteBalance(mode,autoFeature,manualFeature))}
		function onWhiteBalancePresetReceived(presetMode){cu200(See3CAMCU200ModelData.updateWhiteBalancePreset(presetMode))}
		function onDenoiseFlagReceived(flag){cu200(See3CAMCU200ModelData.updateDenoiseFlag(flag))}
		function onDenoiseStrengthReceived(min,max,step,current){cu200(See3CAMCU200ModelData.updateDenoiseStrength(min,max,step,current))}
		function onStatisticsReceived(exposure,autoGain,rGain,bGain,Rr,Rg,Rb,Gr,Gg,Gb,Br,Bg,Bb){cu200(See3CAMCU200ModelData.updateStatistics(exposure,autoGain,rGain,bGain,Rr,Rg,Rb,Gr,Gg,Gb,Br,Bg,Bb))}
		function onIspFirmwareVersionReceived(firmwareVersion){cu200(See3CAMCU200ModelData.updateIspFirmwareVersion(firmwareVersion))}
		
		// Handles see3camcu200Controller.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU200ModelData.updateSerialNumber() (only when the selected device is
		// See3CAM_CU200) and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200) return
			var changedFields = See3CAMCU200ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu200Controller.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU200ModelData.updateFirmwareVersioninUI() (only when the selected device is
		// See3CAM_CU200) and refreshes the changed fields.
		function onFirmwareVersionReceived(firmwareVersion) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200) return
			var changedFields = See3CAMCU200ModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu55mhController
		// Handles see3camcu55mhController.streamModeReceived signal: passes the value(s) to
		// See3CAMCU55MHModelData.updateStreamMode() (only when the selected device is
		// See3CAM_CU55_MH) and refreshes the changed fields.
		function onStreamModeReceived(streamMode) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu55mhController.flashModeReceived signal: passes the value(s) to
		// See3CAMCU55MHModelData.updateFlashMode() (only when the selected device is
		// See3CAM_CU55_MH) and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu55mhController.orientationReceived signal: passes the value(s) to
		// See3CAMCU55MHModelData.updateOrientation() (only when the selected device is
		// See3CAM_CU55_MH) and refreshes the changed fields.
		function onOrientationReceived(flipMode) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateOrientation(flipMode)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu55mhController.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU55MHModelData.updateSerialNumber() (only when the selected device is
		// See3CAM_CU55_MH) and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}
		// Handles see3camcu55mhController.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU55MHModelData.updateFirmwareVersioninUI() (only when the selected device is
		// See3CAM_CU55_MH) and refreshes the changed fields.
		function onFirmwareVersionReceived(firmwareVersion) {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3cam130eController

		// Firmware
		// Handles see3cam130eController.firmwareVersionReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
		// calls See3CAM130EModelData.callSupportFunctions() to apply dependent control states.
		function onFirmwareVersionReceived(firmwareVer) {
			var changedFields = See3CAM130EModelData.updateFirmwareVersioninUI(firmwareVer)
			triggerUpdateSignal(changedFields)
			See3CAM130EModelData.callSupportFunctions() 
		}

		// Handles see3cam130eController.serialNumberReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAM130EModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Scene / Effect / Denoise
		// Handles see3cam130eController.sceneModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateSceneMode() and refreshes the changed fields.
		function onSceneModeReceived(sceneMode) {
			var changedFields = See3CAM130EModelData.updateSceneMode(sceneMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.effectModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateEffectMode() and refreshes the changed fields.
		function onEffectModeReceived(effectMode) {
			var changedFields = See3CAM130EModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.denoiseValueReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateDenoiseValue() and refreshes the changed fields.
		function onDenoiseValueReceived(denoiseValue) {
			var changedFields = See3CAM130EModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Focus
		// Handles see3cam130eController.afModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateAFMode() and refreshes the changed fields.
		function onAfModeReceived(afMode) {
			var changedFields = See3CAM130EModelData.updateAFMode(afMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.roiAfModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateRoiAFMode() and refreshes the changed fields.
		function onRoiAfModeReceived(roiMode, winSize) {
			var changedFields = See3CAM130EModelData.updateRoiAFMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.afRectModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateAFRectMode() and refreshes the changed fields.
		function onAfRectModeReceived(afRectMode) {
			var changedFields = See3CAM130EModelData.updateAFRectMode(afRectMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.afPositionReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateAFPosition() and refreshes the changed fields.
		function onAfPositionReceived(afPosition) {
			var changedFields = See3CAM130EModelData.updateAFPosition(afPosition)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		// Handles see3cam130eController.roiAutoExpModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateRoiAEMode() and refreshes the changed fields.
		function onRoiAutoExpModeReceived(roiMode, winSize) {
			var changedFields = See3CAM130EModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.autoExposureReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateAutoExposure() and refreshes the changed fields.
		function onAutoExposureReceived(autoExposure) {
			var changedFields = See3CAM130EModelData.updateAutoExposure(autoExposure)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.exposureCompReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateExposureComp() and refreshes the changed fields.
		function onExposureCompReceived(expComp) {
			var changedFields = See3CAM130EModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// HDR
		// Handles see3cam130eController.hdrModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateHDRMode() and refreshes the changed fields.
		function onHdrModeReceived(hdrMode, hdrValue) {
			var changedFields = See3CAM130EModelData.updateHDRMode(hdrMode, hdrValue)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		// Handles see3cam130eController.burstLengthReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthReceived(burstLength) {
			var changedFields = See3CAM130EModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.qFactorReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorReceived(qFactor) {
			var changedFields = See3CAM130EModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.frameRateReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateFrameRate() and refreshes the changed fields.
		function onFrameRateReceived(frameRate) {
			var changedFields = See3CAM130EModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Stream / Flip / AntiFlicker
		// Handles see3cam130eController.streamModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateStreamMode() and refreshes the changed fields.
		function onStreamModeReceived(streamMode) {
			var changedFields = See3CAM130EModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.flipModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateFlipMode() and refreshes the changed fields.
		function onFlipModeReceived(flipMode) {
			var changedFields = See3CAM130EModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.antiFlickerModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onAntiFlickerModeReceived(flickerMode) {
			var changedFields = See3CAM130EModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		// Handles see3cam130eController.faceDetectModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateFaceDetectMode() and refreshes the changed fields.
		function onFaceDetectModeReceived(mode, embedData, overlayRect) {
			var changedFields = See3CAM130EModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// White Balance / Flash
		// Handles see3cam130eController.autoWhiteBalanceReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateAWB() and refreshes the changed fields.
		function onAutoWhiteBalanceReceived(awbValue) {
			var changedFields = See3CAM130EModelData.updateAWB(awbValue)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.flashModeReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateFlashMode() and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			var changedFields = See3CAM130EModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// RGB Gains
		// Handles see3cam130eController.redGainReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateRedGain() and refreshes the changed fields.
		function onRedGainReceived(minVal, maxVal, currentVal) {
			var changedFields = See3CAM130EModelData.updateRedGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.blueGainReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateBlueGain() and refreshes the changed fields.
		function onBlueGainReceived(minVal, maxVal, currentVal) {
			var changedFields = See3CAM130EModelData.updateBlueGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam130eController.greenGainReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateGreenGain() and refreshes the changed fields.
		function onGreenGainReceived(minVal, maxVal, currentVal) {
			var changedFields = See3CAM130EModelData.updateGreenGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		// Auto Save Config
		// Handles see3cam130eController.autoSaveConfigReceived signal: passes the value(s) to
		// See3CAM130EModelData.updateAutoSaveConfig() and refreshes the changed fields.
		function onAutoSaveConfigReceived(autoSaveMode){
			var changedFields = See3CAM130EModelData.updateAutoSaveConfig(autoSaveMode)
			triggerUpdateSignal(changedFields)			
		}
	}

	
	Connections {
		target: see3cam1318tcController

		// Firmware
		// Handles see3cam1318tcController.firmwareVersionReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
		// calls See3CAM1318_TCModelData.callSupportFunctions() to apply dependent control states.
		function onFirmwareVersionReceived(firmwareVer) {
			var changedFields = See3CAM1318_TCModelData.updateFirmwareVersioninUI(firmwareVer)
			triggerUpdateSignal(changedFields)
			See3CAM1318_TCModelData.callSupportFunctions() 
		}

		// Handles see3cam1318tcController.serialNumberReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAM1318_TCModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Scene / Effect / Denoise
		// Handles see3cam1318tcController.sceneModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateSceneMode() and refreshes the changed fields.
		function onSceneModeReceived(sceneMode) {
			var changedFields = See3CAM1318_TCModelData.updateSceneMode(sceneMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.effectModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateEffectMode() and refreshes the changed fields.
		function onEffectModeReceived(effectMode) {
			var changedFields = See3CAM1318_TCModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.denoiseValueReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateDenoiseValue() and refreshes the changed fields.
		function onDenoiseValueReceived(denoiseValue) {
			var changedFields = See3CAM1318_TCModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Focus
		// Handles see3cam1318tcController.afModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateAFMode() and refreshes the changed fields.
		function onAfModeReceived(afMode) {
			var changedFields = See3CAM1318_TCModelData.updateAFMode(afMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.roiAfModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateRoiAFMode() and refreshes the changed fields.
		function onRoiAfModeReceived(roiMode, winSize) {
			var changedFields = See3CAM1318_TCModelData.updateRoiAFMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.afRectModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateAFRectMode() and refreshes the changed fields.
		function onAfRectModeReceived(afRectMode) {
			var changedFields = See3CAM1318_TCModelData.updateAFRectMode(afRectMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.afPositionReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateAFPosition() and refreshes the changed fields.
		function onAfPositionReceived(afPosition) {
			var changedFields = See3CAM1318_TCModelData.updateAFPosition(afPosition)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		// Handles see3cam1318tcController.roiAutoExpModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateRoiAEMode() and refreshes the changed fields.
		function onRoiAutoExpModeReceived(roiMode, winSize) {
			var changedFields = See3CAM1318_TCModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.autoExposureReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateAutoExposure() and refreshes the changed fields.
		function onAutoExposureReceived(autoExposure) {
			var changedFields = See3CAM1318_TCModelData.updateAutoExposure(autoExposure)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.exposureCompReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateExposureComp() and refreshes the changed fields.
		function onExposureCompReceived(expComp) {
			var changedFields = See3CAM1318_TCModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// HDR
		// Handles see3cam1318tcController.hdrModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateHDRMode() and refreshes the changed fields.
		function onHdrModeReceived(hdrMode, hdrValue) {
			var changedFields = See3CAM1318_TCModelData.updateHDRMode(hdrMode, hdrValue)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		// Handles see3cam1318tcController.burstLengthReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthReceived(burstLength) {
			var changedFields = See3CAM1318_TCModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.qFactorReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorReceived(qFactor) {
			var changedFields = See3CAM1318_TCModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.frameRateReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateFrameRate() and refreshes the changed fields.
		function onFrameRateReceived(frameRate) {
			var changedFields = See3CAM1318_TCModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Stream / Flip / AntiFlicker
		// Handles see3cam1318tcController.streamModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateStreamMode() and refreshes the changed fields.
		function onStreamModeReceived(streamMode) {
			var changedFields = See3CAM1318_TCModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.flipModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateFlipMode() and refreshes the changed fields.
		function onFlipModeReceived(flipMode) {
			var changedFields = See3CAM1318_TCModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.antiFlickerModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onAntiFlickerModeReceived(flickerMode) {
			var changedFields = See3CAM1318_TCModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		// Handles see3cam1318tcController.faceDetectModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateFaceDetectMode() and refreshes the changed fields.
		function onFaceDetectModeReceived(mode, embedData, overlayRect) {
			var changedFields = See3CAM1318_TCModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// White Balance / Flash
		// Handles see3cam1318tcController.autoWhiteBalanceReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateAWB() and refreshes the changed fields.
		function onAutoWhiteBalanceReceived(awbValue) {
			var changedFields = See3CAM1318_TCModelData.updateAWB(awbValue)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.flashModeReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateFlashMode() and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			var changedFields = See3CAM1318_TCModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// RGB Gains
		// Handles see3cam1318tcController.redGainReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateRedGain() and refreshes the changed fields.
		function onRedGainReceived(minVal, maxVal, currentVal) {
			var changedFields = See3CAM1318_TCModelData.updateRedGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.blueGainReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateBlueGain() and refreshes the changed fields.
		function onBlueGainReceived(minVal, maxVal, currentVal) {
			var changedFields = See3CAM1318_TCModelData.updateBlueGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam1318tcController.greenGainReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateGreenGain() and refreshes the changed fields.
		function onGreenGainReceived(minVal, maxVal, currentVal) {
			var changedFields = See3CAM1318_TCModelData.updateGreenGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		// Auto Save Config
		// Handles see3cam1318tcController.autoSaveConfigReceived signal: passes the value(s) to
		// See3CAM1318_TCModelData.updateAutoSaveConfig() and refreshes the changed fields.
		function onAutoSaveConfigReceived(autoSaveMode){
			var changedFields = See3CAM1318_TCModelData.updateAutoSaveConfig(autoSaveMode)
			triggerUpdateSignal(changedFields)			
		}
	}

	Connections {
		target: see3camcu130Controller

		// Firmware
		// Handles see3camcu130Controller.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
		// reloads usbcamHidProperty from See3CAMCU130ModelData.getSee3CAMHidModelData() and calls
		// See3CAMCU130ModelData.callSupportFunctions() to apply dependent control states.
		function onFirmwareVersionReceived(firmwareVer) {
			var changedFields = See3CAMCU130ModelData.updateFirmwareVersioninUI(firmwareVer)
			usbcamHidProperty = See3CAMCU130ModelData.getSee3CAMHidModelData()
			triggerUpdateSignal(changedFields)
			See3CAMCU130ModelData.callSupportFunctions() 
		}

		// Handles see3camcu130Controller.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAMCU130ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Scene / Effect / Denoise
		// Handles see3camcu130Controller.sceneModeReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateSceneMode() and refreshes the changed fields.
		function onSceneModeReceived(sceneMode) {
			var changedFields = See3CAMCU130ModelData.updateSceneMode(sceneMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu130Controller.effectModeReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateEffectMode() and refreshes the changed fields.
		function onEffectModeReceived(effectMode) {
			var changedFields = See3CAMCU130ModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu130Controller.denoiseValueReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateDenoiseValue() and refreshes the changed fields.
		function onDenoiseValueReceived(denoiseValue) {
			var changedFields = See3CAMCU130ModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		// Handles see3camcu130Controller.roiAutoExpModeReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateRoiAEMode() and refreshes the changed fields.
		function onRoiAutoExpModeReceived(roiMode, winSize) {
			var changedFields = See3CAMCU130ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu130Controller.exposureCompReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateExposureComp() and refreshes the changed fields.
		function onExposureCompReceived(expComp) {
			var changedFields = See3CAMCU130ModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		// Handles see3camcu130Controller.burstLengthReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthReceived(burstLength) {
			var changedFields = See3CAMCU130ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu130Controller.qFactorReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorReceived(qFactor) {
			var changedFields = See3CAMCU130ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu130Controller.frameRateReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateFrameRate() and refreshes the changed fields.
		function onFrameRateReceived(frameRate) {
			var changedFields = See3CAMCU130ModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Flip / AntiFlicker
		// Handles see3camcu130Controller.flipModeReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateFlipMode() and refreshes the changed fields.
		function onFlipModeReceived(flipMode) {
			var changedFields = See3CAMCU130ModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu130Controller.antiFlickerModeReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onAntiFlickerModeReceived(flickerMode) {
			var changedFields = See3CAMCU130ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		// Handles see3camcu130Controller.faceDetectModeReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateFaceDetectMode() and refreshes the changed fields.
		function onFaceDetectModeReceived(mode, embedData, overlayRect) {
			var changedFields = See3CAMCU130ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu130Controller.smileDetectModeReceived signal: passes the value(s) to
		// See3CAMCU130ModelData.updateSmileDetectMode() and refreshes the changed fields.
		function onSmileDetectModeReceived(mode, embedData){
			var changedFields = See3CAMCU130ModelData.updateSmileDetectMode(mode, embedData)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu135mh01r1Controller

		// Firmware
		// Handles see3camcu135mh01r1Controller.firmwareVersionReceived signal: passes the value(s)
		// to See3CAMCU135M_H01R1ModelData.updateFirmwareVersioninUI(), refreshes the changed
		// fields, and reloads usbcamHidProperty from
		// See3CAMCU135M_H01R1ModelData.getSee3CAMHidModelData() and calls
		// See3CAMCU135M_H01R1ModelData.callSupportFunctions() to apply dependent control states.
		function onFirmwareVersionReceived(firmwareVersion) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateFirmwareVersioninUI(firmwareVersion)
			usbcamHidProperty = See3CAMCU135M_H01R1ModelData.getSee3CAMHidModelData()
			triggerUpdateSignal(changedFields)
			See3CAMCU135M_H01R1ModelData.callSupportFunctions()
		}

		// Handles see3camcu135mh01r1Controller.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU135M_H01R1ModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Flash Control
		// Handles see3camcu135mh01r1Controller.flashModeReceived signal: passes the value(s) to
		// See3CAMCU135M_H01R1ModelData.updateFlashMode() and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// Stream Mode
		// Handles see3camcu135mh01r1Controller.streamModeReceived signal: passes the value(s) to
		// See3CAMCU135M_H01R1ModelData.updateStreamMode() and refreshes the changed fields.
		function onStreamModeReceived(streamMode) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// Flip Control
		// Handles see3camcu135mh01r1Controller.flipModeReceived signal: passes the value(s) to
		// See3CAMCU135M_H01R1ModelData.updateFlipMode() and refreshes the changed fields.
		function onFlipModeReceived(flipValue) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateFlipMode(flipValue)
			triggerUpdateSignal(changedFields)
		}

		// ROI Auto Exposure
		// Handles see3camcu135mh01r1Controller.roiAutoExpModeReceived signal: passes the value(s)
		// to See3CAMCU135M_H01R1ModelData.updateRoiAEMode() and refreshes the changed fields.
		function onRoiAutoExpModeReceived(roiMode, winSize) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Black Level Adjustment
		// Handles see3camcu135mh01r1Controller.blackLevelAdjustmentReceived signal: passes the
		// value(s) to See3CAMCU135M_H01R1ModelData.updateBlackLevelAdjustment() and refreshes the
		// changed fields.
		function onBlackLevelAdjustmentReceived(blacklevel) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateBlackLevelAdjustment(blacklevel)
			triggerUpdateSignal(changedFields)
		}

		// Target Brightness
		// Handles see3camcu135mh01r1Controller.targetBrightnessReceived signal: passes the
		// value(s) to See3CAMCU135M_H01R1ModelData.updateTargetBrightness() and refreshes the
		// changed fields.
		function onTargetBrightnessReceived(brightness) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateTargetBrightness(brightness)
			triggerUpdateSignal(changedFields)
		}

		// Anti-Flicker
		// Handles see3camcu135mh01r1Controller.antiFlickerModeReceived signal: passes the value(s)
		// to See3CAMCU135M_H01R1ModelData.updateAntiFlickerMode() and refreshes the changed
		// fields.
		function onAntiFlickerModeReceived(antiFlicker) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateAntiFlickerMode(antiFlicker)
			triggerUpdateSignal(changedFields)
		}

		// Gain
		// Handles see3camcu135mh01r1Controller.gainModeReceived signal: passes the value(s) to
		// See3CAMCU135M_H01R1ModelData.updateGainMode() and refreshes the changed fields.
		function onGainModeReceived(gainMode, autoGainMode, gainValue) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateGainMode(gainMode, autoGainMode, gainValue)
			triggerUpdateSignal(changedFields)
		}

		// Exposure Mode
		// Handles see3camcu135mh01r1Controller.exposureModeReceived signal: passes the value(s) to
		// See3CAMCU135M_H01R1ModelData.updateExposureMode() and refreshes the changed fields.
		function onExposureModeReceived(exposureMode) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateExposureMode(exposureMode)
			triggerUpdateSignal(changedFields)
		}

		// Gain / Exposure Limits
		// Handles see3camcu135mh01r1Controller.lowerLimitGainReceived signal: passes the value(s)
		// to See3CAMCU135M_H01R1ModelData.updateGainLowerLimit() and refreshes the changed fields.
		function onLowerLimitGainReceived(lowerLimit) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateGainLowerLimit(lowerLimit)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu135mh01r1Controller.upperLimitGainReceived signal: passes the value(s)
		// to See3CAMCU135M_H01R1ModelData.updateGainUpperLimit() and refreshes the changed fields.
		function onUpperLimitGainReceived(upperLimit) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateGainUpperLimit(upperLimit)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu135mh01r1Controller.exposureLowerLimitReceived signal: passes the
		// value(s) to See3CAMCU135M_H01R1ModelData.updateExposureLowerLimit() and refreshes the
		// changed fields.
		function onExposureLowerLimitReceived(lowerLimit) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateExposureLowerLimit(lowerLimit)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu135mh01r1Controller.exposureUpperLimitReceived signal: passes the
		// value(s) to See3CAMCU135M_H01R1ModelData.updateExposureUpperLimit() and refreshes the
		// changed fields.
		function onExposureUpperLimitReceived(upperLimit) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateExposureUpperLimit(upperLimit)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu135mh01r1Controller.statisticsReceived signal: passes the value(s) to
		// See3CAMCU135M_H01R1ModelData.updateStatistics() and refreshes the changed fields.
		function onStatisticsReceived(exposureUs, gainValue) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateStatistics(exposureUs, gainValue)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu135mh01r1Controller.crossStillPropertiesSet signal: passes the value(s)
		// to See3CAMCU135M_H01R1ModelData.updateCrossStill() and refreshes the changed fields.
		function onCrossStillPropertiesSet(success) {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateCrossStill(success)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu135Controller

		// Scene / Effect / Denoise
		// Handles see3camcu135Controller.sceneModeValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateSceneMode() and refreshes the changed fields.
		function onSceneModeValue(sceneMode) {
			var changedFields = See3CAMCU135ModelData.updateSceneMode(sceneMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu135Controller.effectModeValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateEffectMode() and refreshes the changed fields.
		function onEffectModeValue(effectMode) {
			var changedFields = See3CAMCU135ModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu135Controller.denoiseValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateDenoiseValue() and refreshes the changed fields.
		function onDenoiseValue(denoiseVal) {
			var changedFields = See3CAMCU135ModelData.updateDenoiseValue(denoiseVal)
			triggerUpdateSignal(changedFields)
		}

		// iHDR Mode
		// Handles see3camcu135Controller.hdrModeValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateHDRMode() and refreshes the changed fields.
		function onHdrModeValue(hdrMode, hdrValue) {
			var changedFields = See3CAMCU135ModelData.updateHDRMode(hdrMode, hdrValue)
			triggerUpdateSignal(changedFields)
		}

		// Q Factor
		// Handles see3camcu135Controller.qFactorValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorValue(qFactor) {
			var changedFields = See3CAMCU135ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Stream Mode
		// Handles see3camcu135Controller.streamModeValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateStreamMode() and refreshes the changed fields.
		function onStreamModeValue(streamMode) {
			var changedFields = See3CAMCU135ModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// Flip / Mirror Mode
		// Handles see3camcu135Controller.flipMirrorModeChanged signal: passes the value(s) to
		// See3CAMCU135ModelData.updateFlipMode() and refreshes the changed fields.
		function onFlipMirrorModeChanged(flipMirrorMode) {
			var changedFields = See3CAMCU135ModelData.updateFlipMode(flipMirrorMode)
			triggerUpdateSignal(changedFields)
		}

		// Burst Length
		// Handles see3camcu135Controller.burstLengthValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthValue(burstLength) {
			var changedFields = See3CAMCU135ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// ROI Auto Exposure
		// Handles see3camcu135Controller.roiAutoExpMode signal: passes the value(s) to
		// See3CAMCU135ModelData.updateRoiAEMode() and refreshes the changed fields.
		function onRoiAutoExpMode(roiMode, winSize) {
			var changedFields = See3CAMCU135ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Exposure Compensation
		// Handles see3camcu135Controller.exposureCompValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateExposureComp() and refreshes the changed fields.
		function onExposureCompValue(exposureCompensation) {
			var changedFields = See3CAMCU135ModelData.updateExposureComp(exposureCompensation)
			triggerUpdateSignal(changedFields)
		}

		// Frame Rate
		// Handles see3camcu135Controller.frameRateCtrlValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateFrameRate() and refreshes the changed fields.
		function onFrameRateCtrlValue(frameRateVal) {
			var changedFields = See3CAMCU135ModelData.updateFrameRate(frameRateVal)
			triggerUpdateSignal(changedFields)
		}

		// Anti-Flicker Mode
		// Handles see3camcu135Controller.flickerDetectionMode signal: passes the value(s) to
		// See3CAMCU135ModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onFlickerDetectionMode(flickerMode) {
			var changedFields = See3CAMCU135ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		// Handles see3camcu135Controller.faceDetectModeValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateFaceDetectMode() and refreshes the changed fields.
		function onFaceDetectModeValue(faceDetectMode, faceDetectEmbedDataValue, faceDetectOverlayRect) {
			var changedFields = See3CAMCU135ModelData.updateFaceDetectMode(faceDetectMode, faceDetectEmbedDataValue, faceDetectOverlayRect)
			triggerUpdateSignal(changedFields)
		}

		// Smile Detection
		// Handles see3camcu135Controller.smileDetectModeValue signal: passes the value(s) to
		// See3CAMCU135ModelData.updateSmileDetectMode() and refreshes the changed fields.
		function onSmileDetectModeValue(smileDetectMode, smileDetectEmbedDataValue) {
			var changedFields = See3CAMCU135ModelData.updateSmileDetectMode(smileDetectMode, smileDetectEmbedDataValue)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target : ecam16usbController
		// Handles ecam16usbController.firmwareVersionReceived signal: shows the firmware version
		// via UsbcamExtensionModelData.updateFirmwareVersioninUI(), then reloads usbcamHidProperty
		// from UsbcamExtensionModelData.getUsbcamExtensionModelData().
		function onFirmwareVersionReceived(firmwareVer){
			UsbcamExtensionModelData.updateFirmwareVersioninUI(firmwareVer)
			usbcamHidProperty = UsbcamExtensionModelData.getUsbcamExtensionModelData()
		}
	}

	Connections {
		target : ecam82usbController
		// Handles ecam82usbController.firmwareVersionReceived signal: shows the firmware version
		// via UsbcamExtensionModelData.updateFirmwareVersioninUI(), then reloads usbcamHidProperty
		// from UsbcamExtensionModelData.getUsbcamExtensionModelData().
		function onFirmwareVersionReceived(firmwareVer){
			UsbcamExtensionModelData.updateFirmwareVersioninUI(firmwareVer)
			usbcamHidProperty = UsbcamExtensionModelData.getUsbcamExtensionModelData()
		}
	}

     Connections {
          target: see3cam24cugController

          // Handles see3cam24cugController.sendEffectMode signal: passes the value(s) to
          // See3CAM24CUGModelData.updateEffectMode() and refreshes the changed fields.
          function onSendEffectMode(effectMode) {
               var changedFields = See3CAM24CUGModelData.updateEffectMode(effectMode)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.sendDenoiseValue signal: passes the value(s) to
          // See3CAM24CUGModelData.updateDenoiseValue() and refreshes the changed fields.
          function onSendDenoiseValue(denoiseValue) {
               var changedFields = See3CAM24CUGModelData.updateDenoiseValue(denoiseValue)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.roiAutoExpModeValue signal: passes the value(s) to
          // See3CAM24CUGModelData.updateRoiAEMode() and refreshes the changed fields.
          function onRoiAutoExpModeValue(roiMode, winSize) {
               var changedFields = See3CAM24CUGModelData.updateRoiAEMode(roiMode, winSize)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.burstLengthValue signal: passes the value(s) to
          // See3CAM24CUGModelData.updateBurstLength() and refreshes the changed fields.
          function onBurstLengthValue(burstLength) {
               var changedFields = See3CAM24CUGModelData.updateBurstLength(burstLength)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.qFactorValue signal: passes the value(s) to
          // See3CAM24CUGModelData.updateQFactor() and refreshes the changed fields.
          function onQFactorValue(qFactor) {
               var changedFields = See3CAM24CUGModelData.updateQFactor(qFactor)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.flipMirrorModeChanged signal: passes the value(s) to
          // See3CAM24CUGModelData.updateFlipMode() and refreshes the changed fields.
          function onFlipMirrorModeChanged(flipMirrorMode) {
               var changedFields = See3CAM24CUGModelData.updateFlipMode(flipMirrorMode)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.frameRateCtrlValueReceived signal: passes the value(s) to
          // See3CAM24CUGModelData.updateFrameRate() and refreshes the changed fields.
          function onFrameRateCtrlValueReceived(frameRateCtrlValue) {
               var changedFields = See3CAM24CUGModelData.updateFrameRate(frameRateCtrlValue)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.exposureCompValueReceived signal: passes the value(s) to
          // See3CAM24CUGModelData.updateExposureComp() and refreshes the changed fields.
          function onExposureCompValueReceived(exposureCompensation) {
               var changedFields = See3CAM24CUGModelData.updateExposureComp(exposureCompensation)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.faceDetectModeValue signal: passes the value(s) to
          // See3CAM24CUGModelData.updateFaceDetectMode() and refreshes the changed fields.
          function onFaceDetectModeValue(faceDetectMode, faceDetectEmbedDataValue, faceDetectOverlayRect) {
               var changedFields = See3CAM24CUGModelData.updateFaceDetectMode(faceDetectMode, faceDetectEmbedDataValue, faceDetectOverlayRect)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.flashModeValue signal: passes the value(s) to
          // See3CAM24CUGModelData.updateFlashMode() and refreshes the changed fields.
          function onFlashModeValue(flashMode) {
               var changedFields = See3CAM24CUGModelData.updateFlashMode(flashMode)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.flickerDetectionMode signal: passes the value(s) to
          // See3CAM24CUGModelData.updateAntiFlickerMode() and refreshes the changed fields.
          function onFlickerDetectionMode(flickerMode) {
               var changedFields = See3CAM24CUGModelData.updateAntiFlickerMode(flickerMode)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.streamModeValue signal: passes the value(s) to
          // See3CAM24CUGModelData.updateStreamMode() and refreshes the changed fields.
          function onStreamModeValue(streamMode, autoFunctionLock) {
               var changedFields = See3CAM24CUGModelData.updateStreamMode(streamMode, autoFunctionLock)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.serialNumberReceived signal: passes the value(s) to
          // See3CAM24CUGModelData.updateSerialNumber() and refreshes the changed fields.
          function onSerialNumberReceived(serialNum) {
               var changedFields = See3CAM24CUGModelData.updateSerialNumber(serialNum)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam24cugController.firmwareVersionReceived signal: passes the value(s) to
          // See3CAM24CUGModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
          // calls See3CAM24CUGModelData.callSupportFunctions() to apply dependent control states and
          // reloads usbcamHidProperty from See3CAM24CUGModelData.getSee3CAMHidModelData().
          function onFirmwareVersionReceived(firmwareVersion) {
               var changedFields = See3CAM24CUGModelData.updateFirmwareVersioninUI(firmwareVersion)
               triggerUpdateSignal(changedFields)
			   
				See3CAM24CUGModelData.callSupportFunctions()
			   usbcamHidProperty = See3CAM24CUGModelData.getSee3CAMHidModelData()
          }
     }

     Connections {
          target: see3camcu81Controller

          // Handles see3camcu81Controller.cameraModeReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateCameraMode() and refreshes the changed fields.
          function onCameraModeReceived(cameraMode) {
               var changedFields = See3CAMCU81ModelData.updateCameraMode(cameraMode)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.effectModeReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateEffectMode() and refreshes the changed fields.
          function onEffectModeReceived(effectMode) {
               var changedFields = See3CAMCU81ModelData.updateEffectMode(effectMode)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.denoiseValueReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateDenoiseValue() and refreshes the changed fields.
          function onDenoiseValueReceived(denoiseValue) {
               var changedFields = See3CAMCU81ModelData.updateDenoiseValue(denoiseValue)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.roiAutoExpModeReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateRoiAEMode() and refreshes the changed fields.
          function onRoiAutoExpModeReceived(roiMode, winSize) {
               var changedFields = See3CAMCU81ModelData.updateRoiAEMode(roiMode, winSize)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.autoExposureReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateAutoExposure() and refreshes the changed fields.
          function onAutoExposureReceived(autoExposure) {
               var changedFields = See3CAMCU81ModelData.updateAutoExposure(autoExposure)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.exposureCompReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateExposureComp() and refreshes the changed fields.
          function onExposureCompReceived(expComp) {
               var changedFields = See3CAMCU81ModelData.updateExposureComp(expComp)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.burstLengthReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateBurstLength() and refreshes the changed fields.
          function onBurstLengthReceived(burstLength) {
               var changedFields = See3CAMCU81ModelData.updateBurstLength(burstLength)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.qFactorReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateQFactor() and refreshes the changed fields.
          function onQFactorReceived(qFactor) {
               var changedFields = See3CAMCU81ModelData.updateQFactor(qFactor)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.frameRateReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateFrameRate() and refreshes the changed fields.
          function onFrameRateReceived(frameRate) {
               var changedFields = See3CAMCU81ModelData.updateFrameRate(frameRate)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.flipModeReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateFlipMode() and refreshes the changed fields.
          function onFlipModeReceived(flipMode) {
               var changedFields = See3CAMCU81ModelData.updateFlipMode(flipMode)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.antiFlickerModeReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateAntiFlickerMode() and refreshes the changed fields.
          function onAntiFlickerModeReceived(flickerMode) {
               var changedFields = See3CAMCU81ModelData.updateAntiFlickerMode(flickerMode)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.faceDetectModeReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateFaceDetectMode() and refreshes the changed fields.
          function onFaceDetectModeReceived(mode, embedData, overlayRect) {
               var changedFields = See3CAMCU81ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.autoWhiteBalanceReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateAWB() and refreshes the changed fields.
          function onAutoWhiteBalanceReceived(awbValue) {
               var changedFields = See3CAMCU81ModelData.updateAWB(awbValue)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.serialNumberReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateSerialNumber() and refreshes the changed fields.
          function onSerialNumberReceived(serialNum) {
               var changedFields = See3CAMCU81ModelData.updateSerialNumber(serialNum)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3camcu81Controller.firmwareVersionReceived signal: passes the value(s) to
          // See3CAMCU81ModelData.updateFirmwareVersion(), refreshes the changed fields, and calls
          // See3CAMCU81ModelData.callSupportFunctions() to apply dependent control states and
          // reloads usbcamHidProperty from See3CAMCU81ModelData.getSee3CAMHidModelData().
          function onFirmwareVersionReceived(firmwareVersion) {
               var changedFields = See3CAMCU81ModelData.updateFirmwareVersion(firmwareVersion)
               triggerUpdateSignal(changedFields)
			   See3CAMCU81ModelData.callSupportFunctions()
			usbcamHidProperty = See3CAMCU81ModelData.getSee3CAMHidModelData()
          }
     }

	 Connections {
		target: see3camcu27Controller

		// ---------------------------
		// AWB
		// ---------------------------
		// Handles see3camcu27Controller.awbPresetModeReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateAWBPresetMode() and refreshes the changed fields.
		function onAwbPresetModeReceived(awbMode) {
			var changedFields = See3CAMCU27ModelData.updateAWBPresetMode(awbMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu27Controller.awbLockStatusReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateAWBLockStatus() and refreshes the changed fields.
		function onAwbLockStatusReceived(lockStatus) {
			var changedFields = See3CAMCU27ModelData.updateAWBLockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// AE
		// ---------------------------
		// Handles see3camcu27Controller.aeMeteringModeReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateAEMeteringMode() and refreshes the changed fields.
		function onAeMeteringModeReceived(meterMode) {
			var changedFields = See3CAMCU27ModelData.updateAEMeteringMode(meterMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu27Controller.aeLockStatusReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateAELockStatus() and refreshes the changed fields.
		function onAeLockStatusReceived(lockStatus) {
			var changedFields = See3CAMCU27ModelData.updateAELockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flicker
		// ---------------------------
		// Handles see3camcu27Controller.flickerModeReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onFlickerModeReceived(flickerMode) {
			var changedFields = See3CAMCU27ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// JPEG / Burst
		// ---------------------------
		// Handles see3camcu27Controller.qFactorReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorReceived(qFactor) {
			var changedFields = See3CAMCU27ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu27Controller.burstLengthReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthReceived(burstLength) {
			var changedFields = See3CAMCU27ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Denoise / Roll
		// ---------------------------
		// Handles see3camcu27Controller.denoiseModeReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateDenoiseMode() and refreshes the changed fields.
		function onDenoiseModeReceived(denoiseMode) {
			var changedFields = See3CAMCU27ModelData.updateDenoiseMode(denoiseMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu27Controller.rollValueReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateRollValue() and refreshes the changed fields.
		function onRollValueReceived(rollValue) {
			var changedFields = See3CAMCU27ModelData.updateRollValue(rollValue)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Firmware / Status
		// ---------------------------
		// Handles see3camcu27Controller.ispFirmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateISPFirmwareVersioninUI() and refreshes the changed fields.
		function onIspFirmwareVersionReceived(firmwareVersion) {
			var changedFields = See3CAMCU27ModelData.updateISPFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu27Controller.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAMCU27ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu27Controller.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU27ModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
		// reloads usbcamHidProperty from See3CAMCU27ModelData.getSee3CAMHidModelData().
		function onFirmwareVersionReceived(firmwareVersion) {
			var changedFields = See3CAMCU27ModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
			usbcamHidProperty = See3CAMCU27ModelData.getSee3CAMHidModelData()
		}
	}

	Connections {
		target: see3cam160Controller

		// ---------------------------
		// AF / Focus
		// ---------------------------
		// Handles see3cam160Controller.afModeChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateAFMode() and refreshes the changed fields.
		function onAfModeChanged(afMode) {
			var changedFields = See3CAM160ModelData.updateAFMode(afMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam160Controller.afStatusChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateAFStatus() and refreshes the changed fields.
		function onAfStatusChanged(afstatus) {
			var changedFields = See3CAM160ModelData.updateAFStatus(afstatus)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam160Controller.manualLensPositionModeChanged signal: passes the value(s)
		// to See3CAM160ModelData.updateManualLensPosition() and refreshes the changed fields.
		function onManualLensPositionModeChanged(lensPosMode) {
			var changedFields = See3CAM160ModelData.updateManualLensPosition(lensPosMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam160Controller.afLockStatusChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateAFLockStatus() and refreshes the changed fields.
		function onAfLockStatusChanged(lockStatus) {
			var changedFields = See3CAM160ModelData.updateAFLockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam160Controller.autoFocusRoiModeChanged signal: intentionally a no-op,
		// no JS model update is implemented for AF ROI mode yet.
		function onAutoFocusRoiModeChanged(afRoiMode) {
			// No model function yet
		}

		// Handles see3cam160Controller.cafScanRangeModeChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateCAFScanRangeMode() and refreshes the changed fields.
		function onCafScanRangeModeChanged(scanRangeMode) {
			var changedFields = See3CAM160ModelData.updateCAFScanRangeMode(scanRangeMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// AWB
		// ---------------------------
		// Handles see3cam160Controller.awbPresetModeChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateAWBPresetMode() and refreshes the changed fields.
		function onAwbPresetModeChanged(awbMode) {
			var changedFields = See3CAM160ModelData.updateAWBPresetMode(awbMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam160Controller.awbLockStatusChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateAWBLockStatus() and refreshes the changed fields.
		function onAwbLockStatusChanged(lockStatus) {
			var changedFields = See3CAM160ModelData.updateAWBLockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// AE
		// ---------------------------
		// Handles see3cam160Controller.aeLockStatusChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateAELockStatus() and refreshes the changed fields.
		function onAeLockStatusChanged(lockStatus) {
			var changedFields = See3CAM160ModelData.updateAELockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam160Controller.aeMeterModeChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateAEMeteringMode() and refreshes the changed fields.
		function onAeMeterModeChanged(meterMode) {
			var changedFields = See3CAM160ModelData.updateAEMeteringMode(meterMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Image / Capture
		// ---------------------------
		// Handles see3cam160Controller.qFactorValue signal: passes the value(s) to
		// See3CAM160ModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorValue(qFactor) {
			var changedFields = See3CAM160ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3cam160Controller.burstLengthValue signal: passes the value(s) to
		// See3CAM160ModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthValue(burstLength) {
			var changedFields = See3CAM160ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flicker
		// ---------------------------
		// Handles see3cam160Controller.flickerModeChanged signal: passes the value(s) to
		// See3CAM160ModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onFlickerModeChanged(flickerMode) {
			var changedFields = See3CAM160ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Status / Firmware
		// ---------------------------

          // Handles see3cam160Controller.serialNumberReceived signal: passes the value(s) to
          // See3CAM160ModelData.updateSerialNumber() and refreshes the changed fields.
          function onSerialNumberReceived(serialNum) {
               var changedFields = See3CAM160ModelData.updateSerialNumber(serialNum)
               triggerUpdateSignal(changedFields)
          }

          // Handles see3cam160Controller.firmwareVersionReceived signal: passes the value(s) to
          // See3CAM160ModelData.updateFirmwareVersion(), refreshes the changed fields, and calls
          // See3CAM160ModelData.callSupportFunctions() to apply dependent control states and reloads
          // usbcamHidProperty from See3CAM160ModelData.getSee3CAMHidModelData().
          function onFirmwareVersionReceived(firmwareVersion) {
               var changedFields = See3CAM160ModelData.updateFirmwareVersion(firmwareVersion)
               triggerUpdateSignal(changedFields)
			   See3CAM160ModelData.callSupportFunctions()
			   usbcamHidProperty = See3CAM160ModelData.getSee3CAMHidModelData()
          }
	}

	Connections {
		target: see3camcu84Controller

		// ---------------------------
		// Special Effects
		// ---------------------------
		// Handles see3camcu84Controller.specialEffectReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateEffectMode() and refreshes the changed fields.
		function onSpecialEffectReceived(effect) {
			var changedFields = See3CAMCU84ModelData.updateEffectMode(effect)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Denoise
		// ---------------------------
		// Handles see3camcu84Controller.denoiseValueReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateDenoiseValue() and refreshes the changed fields.
		function onDenoiseValueReceived(denoiseValue) {
			var changedFields = See3CAMCU84ModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// ROI Auto Exposure
		// ---------------------------
		// Handles see3camcu84Controller.roiAutoExpModeReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateRoiAEMode() and refreshes the changed fields.
		function onRoiAutoExpModeReceived(roiMode, winSize) {
			var changedFields = See3CAMCU84ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Burst Length
		// ---------------------------
		// Handles see3camcu84Controller.burstLengthReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthReceived(burstLength) {
			var changedFields = See3CAMCU84ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flip Mode
		// ---------------------------
		// Handles see3camcu84Controller.flipModeReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateFlipMode() and refreshes the changed fields.
		function onFlipModeReceived(flipMode) {
			var changedFields = See3CAMCU84ModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Exposure Compensation
		// ---------------------------
		// Handles see3camcu84Controller.exposureCompReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateExposureComp() and refreshes the changed fields.
		function onExposureCompReceived(expComp) {
			var changedFields = See3CAMCU84ModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Frame Rate
		// ---------------------------
		// Handles see3camcu84Controller.frameRateReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateFrameRate() and refreshes the changed fields.
		function onFrameRateReceived(frameRate) {
			var changedFields = See3CAMCU84ModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Anti-Flicker
		// ---------------------------
		// Handles see3camcu84Controller.antiFlickerModeReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onAntiFlickerModeReceived(flickerMode) {
			var changedFields = See3CAMCU84ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Stream Mode
		// ---------------------------
		// Handles see3camcu84Controller.streamModeReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateStreamMode() and refreshes the changed fields.
		function onStreamModeReceived(streamMode) {
			var changedFields = See3CAMCU84ModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flash Mode
		// ---------------------------
		// Handles see3camcu84Controller.flashModeReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateFlashMode() and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			var changedFields = See3CAMCU84ModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Face Detection
		// ---------------------------
		// Handles see3camcu84Controller.faceDetectModeReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateFaceDetectMode() and refreshes the changed fields.
		function onFaceDetectModeReceived(mode, overlayRect, embedData) {
			var changedFields = See3CAMCU84ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Q Factor
		// ---------------------------
		// Handles see3camcu84Controller.qFactorReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorReceived(qFactor) {
			var changedFields = See3CAMCU84ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Serial / Firmware / Status
		// ---------------------------
		// Handles see3camcu84Controller.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAMCU84ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu84Controller.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU84ModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
		// calls See3CAMCU84ModelData.callSupportFunctions() to apply dependent control states and
		// reloads usbcamHidProperty from See3CAMCU84ModelData.getSee3CAMCU84HidModelData().
		function onFirmwareVersionReceived(firmwareVersion) {
			var changedFields = See3CAMCU84ModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)

			See3CAMCU84ModelData.callSupportFunctions()

			usbcamHidProperty = See3CAMCU84ModelData.getSee3CAMCU84HidModelData()
		}

	}

	Connections {
		target: see3camcu512mController

		// ---------------------------
		// Stream Mode
		// ---------------------------
		// Handles see3camcu512mController.streamModeReceived signal: passes the value(s) to
		// See3CAMCU512MModelData.updateStreamMode() and refreshes the changed fields.
		function onStreamModeReceived(streamMode) {
			var changedFields = See3CAMCU512MModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flash Mode
		// ---------------------------
		// Handles see3camcu512mController.flashModeReceived signal: passes the value(s) to
		// See3CAMCU512MModelData.updateFlashMode() and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			var changedFields = See3CAMCU512MModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Orientation / Flip
		// ---------------------------
		// Handles see3camcu512mController.orientationReceived signal: passes the value(s) to
		// See3CAMCU512MModelData.updateOrientation() and refreshes the changed fields.
		function onOrientationReceived(flipMode) {
			var changedFields = See3CAMCU512MModelData.updateOrientation(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Serial / Firmware / Status
		// ---------------------------
		// Handles see3camcu512mController.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU512MModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAMCU512MModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu512mController.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU512MModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
		// calls See3CAMCU512MModelData.callSupportFunctions() to apply dependent control states
		// and reloads usbcamHidProperty from See3CAMCU512MModelData.getSee3CAMHidModelData().
		function onFirmwareVersionReceived(firmwareVersion) {
			var changedFields = See3CAMCU512MModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)

			See3CAMCU512MModelData.callSupportFunctions()

			usbcamHidProperty = See3CAMCU512MModelData.getSee3CAMHidModelData()
		}
	}

	Connections {
		target: see3camcu58Controller

		// Firmware
		// Handles see3camcu58Controller.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
		// calls See3CAMCU58ModelData.callSupportFunctions() to apply dependent control states.
		function onFirmwareVersionReceived(firmwareVer) {
			var changedFields = See3CAMCU58ModelData.updateFirmwareVersioninUI(firmwareVer)
			triggerUpdateSignal(changedFields)
			See3CAMCU58ModelData.callSupportFunctions() 
		}

		// Handles see3camcu58Controller.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAMCU58ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Effect / Denoise
		// Handles see3camcu58Controller.effectModeReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateEffectMode() and refreshes the changed fields.
		function onEffectModeReceived(effectMode) {
			var changedFields = See3CAMCU58ModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu58Controller.denoiseValueReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateDenoiseValue() and refreshes the changed fields.
		function onDenoiseValueReceived(denoiseValue) {
			var changedFields = See3CAMCU58ModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		// Handles see3camcu58Controller.roiAutoExpModeReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateRoiAEMode() and refreshes the changed fields.
		function onRoiAutoExpModeReceived(roiMode, winSize) {
			var changedFields = See3CAMCU58ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu58Controller.exposureCompReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateExposureComp() and refreshes the changed fields.
		function onExposureCompReceived(expComp) {
			var changedFields = See3CAMCU58ModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		// Handles see3camcu58Controller.burstLengthReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthReceived(burstLength) {
			var changedFields = See3CAMCU58ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu58Controller.qFactorReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorReceived(qFactor) {
			var changedFields = See3CAMCU58ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu58Controller.frameRateReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateFrameRate() and refreshes the changed fields.
		function onFrameRateReceived(frameRate) {
			var changedFields = See3CAMCU58ModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Flip / AntiFlicker

		// Handles see3camcu58Controller.flipModeReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateFlipMode() and refreshes the changed fields.
		function onFlipModeReceived(flipMode) {
			var changedFields = See3CAMCU58ModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu58Controller.antiFlickerModeReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onAntiFlickerModeReceived(flickerMode) {
			var changedFields = See3CAMCU58ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		// Handles see3camcu58Controller.faceDetectModeReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateFaceDetectMode() and refreshes the changed fields.
		function onFaceDetectModeReceived(mode, embedData, overlayRect) {
			var changedFields = See3CAMCU58ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// Flash
		// Handles see3camcu58Controller.flashModeReceived signal: passes the value(s) to
		// See3CAMCU58ModelData.updateFlashMode() and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			var changedFields = See3CAMCU58ModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu55Controller

		// Firmware
		// Handles see3camcu55Controller.firmwareVersionReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and
		// calls See3CAMCU55ModelData.callSupportFunctions() to apply dependent control states.
		function onFirmwareVersionReceived(firmwareVer) {
			var changedFields = See3CAMCU55ModelData.updateFirmwareVersioninUI(firmwareVer)
			triggerUpdateSignal(changedFields)
			See3CAMCU55ModelData.callSupportFunctions() 
		}

		// Handles see3camcu55Controller.serialNumberReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateSerialNumber() and refreshes the changed fields.
		function onSerialNumberReceived(serialNum) {
			var changedFields = See3CAMCU55ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Effect / Denoise
		// Handles see3camcu55Controller.effectModeReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateEffectMode() and refreshes the changed fields.
		function onEffectModeReceived(effectMode) {
			var changedFields = See3CAMCU55ModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu55Controller.denoiseValueReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateDenoiseValue() and refreshes the changed fields.
		function onDenoiseValueReceived(denoiseValue) {
			var changedFields = See3CAMCU55ModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		// Handles see3camcu55Controller.roiAutoExpModeReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateRoiAEMode() and refreshes the changed fields.
		function onRoiAutoExpModeReceived(roiMode, winSize) {
			var changedFields = See3CAMCU55ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu55Controller.exposureCompReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateExposureComp() and refreshes the changed fields.
		function onExposureCompReceived(expComp) {
			var changedFields = See3CAMCU55ModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		// Handles see3camcu55Controller.burstLengthReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateBurstLength() and refreshes the changed fields.
		function onBurstLengthReceived(burstLength) {
			var changedFields = See3CAMCU55ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu55Controller.qFactorReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateQFactor() and refreshes the changed fields.
		function onQFactorReceived(qFactor) {
			var changedFields = See3CAMCU55ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu55Controller.frameRateReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateFrameRate() and refreshes the changed fields.
		function onFrameRateReceived(frameRate) {
			var changedFields = See3CAMCU55ModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Flip / AntiFlicker
		// Handles see3camcu55Controller.flipModeReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateFlipMode() and refreshes the changed fields.
		function onFlipModeReceived(flipMode) {
			var changedFields = See3CAMCU55ModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// Handles see3camcu55Controller.antiFlickerModeReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateAntiFlickerMode() and refreshes the changed fields.
		function onAntiFlickerModeReceived(flickerMode) {
			var changedFields = See3CAMCU55ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		// Handles see3camcu55Controller.faceDetectModeReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateFaceDetectMode() and refreshes the changed fields.
		function onFaceDetectModeReceived(mode, embedData, overlayRect) {
			var changedFields = See3CAMCU55ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// Smile Detection
		// Handles see3camcu55Controller.smileDetectModeReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateSmileDetectMode() and refreshes the changed fields.
		function onSmileDetectModeReceived(mode, embedData) {
			var changedFields = See3CAMCU55ModelData.updateSmileDetectMode(mode, embedData)
			triggerUpdateSignal(changedFields)
		}

		// Flash
		// Handles see3camcu55Controller.flashModeReceived signal: passes the value(s) to
		// See3CAMCU55ModelData.updateFlashMode() and refreshes the changed fields.
		function onFlashModeReceived(flashMode) {
			var changedFields = See3CAMCU55ModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}
	}

	// ================================================================
	// DensiCAM  QML Connections block
	// Target: densicamController
	// ================================================================

	Connections {
		target: densicamController

		// ---- Common ----
		// Handles densicamController.firmwareVersionReceived signal: passes the value(s) to
		// DensiCAMModelData.updateFirmwareVersioninUI(), refreshes the changed fields, and reloads
		// usbcamHidProperty from DensiCAMModelData.getDensiCAMHidModelData() and calls
		// DensiCAMModelData.callSupportFunctions() to apply dependent control states.
		function onFirmwareVersionReceived(firmwareVersion) {
			var changedFields = DensiCAMModelData.updateFirmwareVersioninUI(firmwareVersion)
			
			usbcamHidProperty = DensiCAMModelData.getDensiCAMHidModelData()
			triggerUpdateSignal(changedFields)
			DensiCAMModelData.callSupportFunctions()
		}

		// Handles densicamController.uniqueIDReceived signal: passes the value(s) to
		// DensiCAMModelData.updateUniqueID() and refreshes the changed fields.
		function onUniqueIDReceived(uniqueID) {
			var changedFields = DensiCAMModelData.updateUniqueID(uniqueID)
			triggerUpdateSignal(changedFields)
		}

		// ---- Extension Controls ----
		// Handles densicamController.pixelTargetValueReceived signal: passes the value(s) to
		// DensiCAMModelData.updatePixelTargetValue() and refreshes the changed fields.
		function onPixelTargetValueReceived(value, status) {
			var changedFields = DensiCAMModelData.updatePixelTargetValue(value, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.denoiseValueReceived signal: passes the value(s) to
		// DensiCAMModelData.updateDenoiseValue() and refreshes the changed fields.
		function onDenoiseValueReceived(value, status) {
			var changedFields = DensiCAMModelData.updateDenoiseValue(value, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.orientationReceived signal: passes the value(s) to
		// DensiCAMModelData.updateFlipMode() and refreshes the changed fields.
		function onOrientationReceived(value, status) {
			var changedFields = DensiCAMModelData.updateFlipMode(value, status)
			triggerUpdateSignal(changedFields)
		}

		// ---- Command Controls 8-bit range ----
		// Handles densicamController.brightnessReceived signal: passes the value(s) to
		// DensiCAMModelData.updateBrightness() and refreshes the changed fields.
		function onBrightnessReceived(minVal, maxVal, defVal, curVal, resVal, status) {
			var changedFields = DensiCAMModelData.updateBrightness(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.contrastReceived signal: passes the value(s) to
		// DensiCAMModelData.updateContrast() and refreshes the changed fields.
		function onContrastReceived(minVal, maxVal, defVal, curVal, resVal, status) {
			var changedFields = DensiCAMModelData.updateContrast(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.saturationReceived signal: passes the value(s) to
		// DensiCAMModelData.updateSaturation() and refreshes the changed fields.
		function onSaturationReceived(minVal, maxVal, defVal, curVal, resVal, status) {
			var changedFields = DensiCAMModelData.updateSaturation(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.sharpnessReceived signal: passes the value(s) to
		// DensiCAMModelData.updateSharpness() and refreshes the changed fields.
		function onSharpnessReceived(minVal, maxVal, defVal, curVal, resVal, status) {
			var changedFields = DensiCAMModelData.updateSharpness(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.gainReceived signal: passes the value(s) to
		// DensiCAMModelData.updateGain() and refreshes the changed fields.
		function onGainReceived(minVal, maxVal, defVal, curVal, resVal, status) {
			var changedFields = DensiCAMModelData.updateGain(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// ---- Command Controls  16-bit range ----
		// Handles densicamController.gammaReceived signal: passes the value(s) to
		// DensiCAMModelData.updateGamma() and refreshes the changed fields.
		function onGammaReceived(minVal, maxVal, defVal, curVal, resVal, status) {
			var changedFields = DensiCAMModelData.updateGamma(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.manualWhiteBalanceReceived signal: passes the value(s) to
		// DensiCAMModelData.updateManualWhiteBalance() and refreshes the changed fields.
		function onManualWhiteBalanceReceived(minVal, maxVal, defVal, curVal, resVal, status) {
			var changedFields = DensiCAMModelData.updateManualWhiteBalance(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// ---- Command Controls  32-bit range ----
		// Handles densicamController.manualExposureReceived signal: passes the value(s) to
		// DensiCAMModelData.updateManualExposure() and refreshes the changed fields.
		function onManualExposureReceived(minVal, maxVal, defVal, curVal, resVal, status) {
			var changedFields = DensiCAMModelData.updateManualExposure(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// ---- Command Controls  single-byte ----
		// Handles densicamController.autoWhiteBalanceReceived signal: passes the value(s) to
		// DensiCAMModelData.updateAutoWhiteBalance() and refreshes the changed fields.
		function onAutoWhiteBalanceReceived(value, status) {
			var changedFields = DensiCAMModelData.updateAutoWhiteBalance(value, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.autoExposureReceived signal: passes the value(s) to
		// DensiCAMModelData.updateAutoExposure() and refreshes the changed fields.
		function onAutoExposureReceived(value, status) {
			var changedFields = DensiCAMModelData.updateAutoExposure(value, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.ledReceived signal: passes the value(s) to
		// DensiCAMModelData.updateLED() and refreshes the changed fields.
		function onLedReceived(value, status) {
			var changedFields = DensiCAMModelData.updateLED(value, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.imageCaptureReceived signal: passes the value(s) to
		// DensiCAMModelData.updateImageCapture() and refreshes the changed fields.
		function onImageCaptureReceived(mode, status) {
			var changedFields = DensiCAMModelData.updateImageCapture(mode, status)
			triggerUpdateSignal(changedFields)
		}

		// Handles densicamController.sceneModeReceived signal: passes the value(s) to
		// DensiCAMModelData.updateSceneMode() and refreshes the changed fields.
		function onSceneModeReceived(mode, status) {
			var changedFields = DensiCAMModelData.updateSceneMode(mode, status)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target : window
		// Handles window.mouseRightClicked signal (right-click on the preview): forwards the
		// click position and preview size to the device JS model's handleRightClick(), which
		// sets the manual ROI for auto exposure / auto focus where supported.
		function onMouseRightClicked(x, y, width, height){
			switch(currentDevType()) {
				case DeviceEnums.See3CAM_130E:
				case DeviceEnums.See3CAM_130E_H02R1:
					See3CAM130EModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_1318_TC:
					See3CAM1318_TCModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_CU130:
					See3CAMCU130ModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_CU135M_H01R1:
					See3CAMCU135M_H01R1ModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_CU135:
					See3CAMCU135ModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_24CUG:
					See3CAM24CUGModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_CU81:
					See3CAMCU81ModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_CU58:
				case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
					See3CAMCU58ModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_CU55:
					See3CAMCU55ModelData.handleRightClick(x, y, width, height); break
				case DeviceEnums.See3CAM_CU200:
					See3CAMCU200ModelData.handleRightClick(x, y, width, height); break
				default: break
			}
		}
	}

	// Sets the expanded flag of the accordion item whose label matches (searched up to four
	// levels deep) and recomputes heightVal/hidScrollHeight and the flickable content width
	// from the number of visible child rows; logs expanded items via logController.
	function setExpandedState(label, expanded){
		var length = 0
        var indexes = findLabelIndex(usbcamHidProperty,label)
        if(indexes.length == 1){
			var lengthChild = 0
			var lengthGrandChild =0
            usbcamHidProperty[indexes[0]].expanded = expanded
			length = usbcamHidProperty[indexes[0]].children.length
			
			var children = usbcamHidProperty[indexes[0]].children
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
			var item = usbcamHidProperty[indexes[0]].children[indexes[1]]
			item.expanded = expanded
			usbcamHidProperty[indexes[0]].children[indexes[1]].expanded = expanded

			var children = item.children
			length = children.length

			for (var i = 0; i < children.length; i++) {
				if (children[i].expanded === true) {
					lengthChild += children[i].children.length
					if(item.expanded == true){
						logController.expandedExtItem(children[i].id)
					}
				}
			}
			length = length + lengthChild + lengthGrandChild			
		} else if(indexes.length == 3){
            usbcamHidProperty[indexes[0]].children[indexes[1]].children[indexes[2]].expanded = expanded
			length = usbcamHidProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children.length
		}  else if(indexes.length == 4){
            usbcamHidProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children[indexes[3]].expanded = expanded
			length =  usbcamHidProperty[indexes[0]].children[indexes[1]].children[indexes[2]].children[indexes[3]].length
		} 

		var width = 0.0805 * MonitorHandler.screenResolution.width
		var scrollWidth;
		if(expanded == true){
			heightVal += length*  0.052 * screenHeight 
			if(heightVal > usbcamRect.height){
				hidScrollHeight = heightVal +  0.052 * screenHeight + selectedDeviceCount *  0.052 * screenHeight
				scrollWidth = 0.2 * MonitorHandler.screenResolution.width
			} else{
				scrollWidth = 0.2 * MonitorHandler.screenResolution.width
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
			if(usbcamRect.width > 0 && usbcamFlickable.dynamicContentWidth < scrollWidth + width){
				usbcamFlickable.dynamicContentWidth = scrollWidth + width
			}
		} else{			
			heightVal = heightVal - length * 0.052 * screenHeight 
			hidScrollHeight = heightVal + 2 *  0.052 * screenHeight + 80
			var count =0
			for(i =0 ; i < usbcamHidProperty.length ; i++){
				if(usbcamHidProperty[i]. expanded == false){
					count ++
				}
				if(count == usbcamHidProperty.length){
					usbcamFlickable.dynamicContentWidth = 0
				}
			}
		}
    }

    // Recursively searches the nested control model for an item with the given label.
    // Returns the index path (e.g. [i, j, k]) to that item, or null if not found.
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

	//Function for value update in the Slider   
	// Routes a slider value change to the current device's JS model (updateSliderValue).
	// Default (generic USB cams) uses updateSliderVal and emits fieldValueChanged for each
	// returned change; otherwise emits fieldValueChanged(id, currentVal) to update the label.
	function handleSliderValChanged(label, id, currentVal){
		switch(currentDevType()) {
			case DeviceEnums.See3CAM_130E:
			case DeviceEnums.See3CAM_130E_H02R1:
				See3CAM130EModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_1318_TC:
				See3CAM1318_TCModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU31:
				See3CAMCU31ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU83:
				See3CAMCU83ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU84:
				See3CAMCU84ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU27:
				See3CAMCU27ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_27CUG:
				See3CAM27CUGModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_37CUG:
				See3CAM37CUGModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU130:
				See3CAMCU130ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU135M_H01R1:
				See3CAMCU135M_H01R1ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU135:
				See3CAMCU135ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_24CUG:
				See3CAM24CUGModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU81:
				See3CAMCU81ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU58:
			case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
				See3CAMCU58ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU55:
				See3CAMCU55ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.See3CAM_CU200:
				See3CAMCU200ModelData.updateSliderValue(id, currentVal); break
			case DeviceEnums.DensiCAM:
				DensiCAMModelData.updateSliderValue(id, currentVal); break
			default: {
				var changedFields = UsbcamExtensionModelData.updateSliderVal(label, id, currentVal, controlSelectedDevName)
				if (changedFields && changedFields.length > 0) {
					for (var i = 0; i < changedFields.length; i++) {
						var change = changedFields[i];
						if (change.hasOwnProperty('value')) {
							usbcamHidAcc.fieldValueChanged(change.id, change.currentValue);
						}
					}
					return;
				}
			}
		}

		// Emit signal to update the parent label text
		usbcamHidAcc.fieldValueChanged(id, currentVal);
	}

	//Function for value update in the radiobutton
	// Routes a radio-button change to the current device's JS model and emits targeted
	// field signals (enabled/selected/visible/expanded/checked/text) for each change.
	// Also forwards anti-flicker AUTO to the UVC panel on non-Windows for 1318_TC/130E/
	// 24CUG/CU27, and restarts the preview stream when trigger mode is disabled.
	function radioButtonChanged(groupId, id, checked){ 

		var length = 0

		// Emit AUTO from QML so the sibling UVC settings component always
		// receives the request to add and select its temporary blank option.
		var devType = currentDevType()
		if (checked && Qt.platform.os !== "windows" &&
			(devType === DeviceEnums.See3CAM_1318_TC ||
			 devType === DeviceEnums.See3CAM_130E ||
			 devType === DeviceEnums.See3CAM_130E_H02R1 ||
			 devType === DeviceEnums.See3CAM_24CUG ||
			 devType === DeviceEnums.See3CAM_CU27) &&
			groupId === "antiFlickerMode" && id === "autoMode") {
			usbcamRect.setHidAntiFlicker("AUTO")
		}

		var changedFields
		switch(currentDevType()) {
			case DeviceEnums.See3CAM_130E:
			case DeviceEnums.See3CAM_130E_H02R1:
				changedFields = See3CAM130EModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_1318_TC:
				changedFields = See3CAM1318_TCModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU31:
				changedFields = See3CAMCU31ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU83:
				changedFields = See3CAMCU83ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU84:
				changedFields = See3CAMCU84ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU27:
				changedFields = See3CAMCU27ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_27CUG:
				changedFields = See3CAM27CUGModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_37CUG:
				changedFields = See3CAM37CUGModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU130:
				changedFields = See3CAMCU130ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU135M_H01R1:
				changedFields = See3CAMCU135M_H01R1ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU135:
				changedFields = See3CAMCU135ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_24CUG:
				changedFields = See3CAM24CUGModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU81:
				changedFields = See3CAMCU81ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_160:
				changedFields = See3CAM160ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU58:
			case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
				changedFields = See3CAMCU58ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU55:
				changedFields = See3CAMCU55ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU200M:
				changedFields = See3CAMCU200MModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.See3CAM_CU200:
				changedFields = See3CAMCU200ModelData.handleRadioButtonChange(groupId, id, checked); break
			case DeviceEnums.DensiCAM:
				changedFields = DensiCAMModelData.handleRadioButtonChange(groupId, id, checked); break
			default:
				changedFields = UsbcamExtensionModelData.handleRadioButtonChange(groupId, id, checked); break
		}

		// Leaving trigger mode back to free-run/master re-arms the sensor's
		// own capture state without ever going through setCurrentImageProperty,
		// so frames can start arriving again while the grab/process threads
		// and OpenGL display are still stuck on the trigger-mode state and
		// never render them. Restart the stream unconditionally to recover.
		if (checked && groupId === "triggerModeGroup" && id === "triggerDisable") {
			prevController.restartPreviewStream(index)
		}


		// Emit targeted signals for only the changed fields
		if (changedFields && changedFields.length > 0) {
			// Collect text changes for delayed processing
			var textChanges = [];
			
			for (var i = 0; i < changedFields.length; i++) {
				var change = changedFields[i];
				
				if (change.hasOwnProperty('enabled')) {
					usbcamHidAcc.fieldChanged (change.id, change.enabled);
				}

				if (change.hasOwnProperty('selected')) {
					usbcamHidAcc.fieldOptionsChanged(change.id, change.selected);
				}

				if (change.hasOwnProperty('visible')) {
					usbcamHidAcc.fieldVisibilityChanged(change.id, change.visible);
				}

				if (change.hasOwnProperty('expanded')) {
					usbcamHidAcc.fieldExpandedChanged(change.id, change.expanded);
				}

				if (change.hasOwnProperty('checked')) {	
					usbcamHidAcc.fieldCheckedChanged(change.id, change.checked);
				}

				if (change.hasOwnProperty('text')) {
					usbcamHidAcc.fieldTextChanged(change.id, change.text);
				}	
			}
        }
	}

	// OPTIMIZED: No full reload, only targeted updates
    // Routes a combo-box selection change to the current device's JS model
    // (handleDropBoxValueChanged) and emits fieldChanged/fieldOptionsChanged for each
    // returned change, avoiding a full model reload.
    function handleDropBoxValChanged(label, id, value) {

		var changedFields
		switch(currentDevType()) {
			case DeviceEnums.See3CAM_130E:
			case DeviceEnums.See3CAM_130E_H02R1:
				changedFields = See3CAM130EModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_1318_TC:
				changedFields = See3CAM1318_TCModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU31:
				changedFields = See3CAMCU31ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU83:
				changedFields = See3CAMCU83ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU84:
				changedFields = See3CAMCU84ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU27:
				changedFields = See3CAMCU27ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_37CUG:
				changedFields = See3CAM37CUGModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU130:
				changedFields = See3CAMCU130ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU135M_H01R1:
				changedFields = See3CAMCU135M_H01R1ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU135:
				changedFields = See3CAMCU135ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_24CUG:
				changedFields = See3CAM24CUGModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU81:
				changedFields = See3CAMCU81ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_160:
				changedFields = See3CAM160ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU58:
			case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
				changedFields = See3CAMCU58ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU55:
				changedFields = See3CAMCU55ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.See3CAM_CU200:
				changedFields = See3CAMCU200ModelData.handleDropBoxValueChanged(id, value); break
			case DeviceEnums.DensiCAM:
				changedFields = DensiCAMModelData.handleDropBoxValueChanged(id, value); break
			default:
				changedFields = UsbcamExtensionModelData.handleDropBoxValChanged(label, id, value, controlSelectedDevName); break
		}
        // Emit targeted signals for only the changed fields
        if (changedFields && changedFields.length > 0) {
            for (var i = 0; i < changedFields.length; i++) {
                var change = changedFields[i];
                
                if (change.hasOwnProperty('enabled')) {
                    // Notify specific field about enabled state change
                    usbcamHidAcc.fieldChanged(change.id, change.enabled);
                }

				if (change.hasOwnProperty('selected')) {
					// Notify about value change for label update
					usbcamHidAcc.fieldOptionsChanged(change.id, change.selected);
				}
            }
        }
    }

	// Routes a check-box toggle to the current device's JS model (updateCheckBoxValue),
	// falling back to the generic extension model for unlisted devices.
	function handleCheckBoxValChanged(label, id, checked){
		switch(currentDevType()) {
			case DeviceEnums.See3CAM_130E:
			case DeviceEnums.See3CAM_130E_H02R1:
				See3CAM130EModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_1318_TC:
				See3CAM1318_TCModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU31:
				See3CAMCU31ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU83:
				See3CAMCU83ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU84:
				See3CAMCU84ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU27:
				See3CAMCU27ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_27CUG:
				See3CAM27CUGModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_37CUG:
				See3CAM37CUGModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU130:
				See3CAMCU130ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU135M_H01R1:
				See3CAMCU135M_H01R1ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU135:
				See3CAMCU135ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_24CUG:
				See3CAM24CUGModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU81:
				See3CAMCU81ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_160:
				See3CAM160ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU58:
			case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
				See3CAMCU58ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU55:
				See3CAMCU55ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU200M:
				See3CAMCU200MModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.See3CAM_CU200:
				See3CAMCU200ModelData.updateCheckBoxValue(id, checked); break
			case DeviceEnums.DensiCAM:
				DensiCAMModelData.updateCheckBoxValue(id, checked); break
			default:
				UsbcamExtensionModelData.updateCheckBoxValue(id, checked); break
		}
	}

	// Routes an edited text-field value to the current device's JS model
	// (updateTextBoxField); ignored for devices without text-box controls.
	function handleTextBoxValChanged(id, text){
		switch(currentDevType()) {
			case DeviceEnums.See3CAM_130E:
			case DeviceEnums.See3CAM_130E_H02R1:
				See3CAM130EModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_1318_TC:
				See3CAM1318_TCModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU31:
				See3CAMCU31ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU83:
				See3CAMCU83ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_27CUG:
				See3CAM27CUGModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_37CUG:
				See3CAM37CUGModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU130:
				See3CAMCU130ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU135M_H01R1:
				See3CAMCU135M_H01R1ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU135:
				See3CAMCU135ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_24CUG:
				See3CAM24CUGModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU81:
				See3CAMCU81ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU84:
				See3CAMCU84ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_160:
				See3CAM160ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU58:
			case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
				See3CAMCU58ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU55:
				See3CAMCU55ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.See3CAM_CU200:
				See3CAMCU200ModelData.updateTextBoxField(id, text); break
			case DeviceEnums.DensiCAM:
				DensiCAMModelData.updateTextBoxField(id, text); break
			default: break
		}
	}

	// Routes a button click (by control id) to the current device's JS model; for
	// e-CAM212_USB the "resetBtn" id calls ecam212usbUvcextController.resetDevice().
	function handleButtonClick(id){
		switch(currentDevType()) {
			case DeviceEnums.ECAM212_USB:
				if(id == "resetBtn") ecam212usbUvcextController.resetDevice(); break
			case DeviceEnums.See3CAM_130E:
			case DeviceEnums.See3CAM_130E_H02R1:
				See3CAM130EModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_1318_TC:
				See3CAM1318_TCModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU31:
				See3CAMCU31ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU83:
				See3CAMCU83ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_27CUG:
				See3CAM27CUGModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_37CUG:
				See3CAM37CUGModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU130:
				See3CAMCU130ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU135M_H01R1:
				See3CAMCU135M_H01R1ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU135:
				See3CAMCU135ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_24CUG:
				See3CAM24CUGModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU81:
				See3CAMCU81ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_160:
				See3CAM160ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU84:
				See3CAMCU84ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU27:
				See3CAMCU27ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU512M:
				See3CAMCU512MModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU58:
			case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
				See3CAMCU58ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU55:
				See3CAMCU55ModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU200M:
				See3CAMCU200MModelData.handleButtonClick(id); break
			case DeviceEnums.See3CAM_CU200:
				See3CAMCU200ModelData.handleButtonClick(id); break
			case DeviceEnums.DensiCAM:
				DensiCAMModelData.handleButtonClick(id); break
			default: break
		}
	}

	// Requests the initial HID control values by calling getCameraControls() on the JS
	// model of the current device type (generic model for e-CAM212/16/82).
	function getCameraControls(){
		switch(currentDevType()) {
			case DeviceEnums.ECAM212_USB:
				UsbcamExtensionModelData.getCameraControls(); break
			case DeviceEnums.ECAM16_USB:
				UsbcamExtensionModelData.getCameraControls(); break
			case DeviceEnums.ECAM82_USB:
				UsbcamExtensionModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_130E:
			case DeviceEnums.See3CAM_130E_H02R1:
				See3CAM130EModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_1318_TC:
				See3CAM1318_TCModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU31:
				See3CAMCU31ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU83:
				See3CAMCU83ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_27CUG:
				See3CAM27CUGModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU27:
				See3CAMCU27ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_37CUG:
				See3CAM37CUGModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU130:
				See3CAMCU130ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU135M_H01R1:
				See3CAMCU135M_H01R1ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU135:
				See3CAMCU135ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU200M:
				See3CAMCU200MModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU200:
				See3CAMCU200ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_24CUG:
				See3CAM24CUGModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU81:
				See3CAMCU81ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU84:
				See3CAMCU84ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_160:
				See3CAM160ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU512M:
				See3CAMCU512MModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU58:
			case DeviceEnums.See3CAM_CU55_CHLCW_H21R1:
				See3CAMCU58ModelData.getCameraControls(); break
			case DeviceEnums.See3CAM_CU55:
				See3CAMCU55ModelData.getCameraControls(); break
			case DeviceEnums.DensiCAM:
				DensiCAMModelData.getCameraControls(); break
			default: break
		}
	}

	// Emits the accordion field signals for each entry of a changed-field list: enabled,
	// selected, checked, text and currentValue. Does nothing if the list is null/undefined.
	function triggerUpdateSignal(changedFields){
		if (changedFields === undefined || changedFields === null)
       		return;
		for (var i = 0; i < changedFields.length; i++) {
			var change = changedFields[i];
			
			if (change.hasOwnProperty('enabled')) {
				usbcamHidAcc.fieldChanged (change.id, change.enabled);
			}

			if (change.hasOwnProperty('selected')) {
				usbcamHidAcc.fieldOptionsChanged(change.id, change.selected);
			}

			if (change.hasOwnProperty('checked')) {
				usbcamHidAcc.fieldCheckedChanged(change.id, change.checked);
			}

			if (change.hasOwnProperty('text')) {
				usbcamHidAcc.fieldTextChanged(change.id, change.text);
			}	

			if(change.hasOwnProperty('currentValue')) {
				usbcamHidAcc.fieldValueChanged(change.id, change.currentValue);
			}
		}
	}

	// Starts getexposureCompFrameRateCtrlTimer, which re-reads exposure compensation and
	// frame-rate control from the device after a 500 ms delay.
	function getexposureCompFrameRateCtrl(){
		getexposureCompFrameRateCtrlTimer.start()
	}

	// ADD this utility function inside UsbcamHidSettings:
	// Returns the DeviceEnums type of the selected camera, resolved from its VID/PID
	// (controlSelectedVid/controlSelectedPid) through DeviceEnumInstance.resolveDevice().
	function currentDevType() {
		return DeviceEnumInstance.resolveDevice(
			controlSelectedVid,
			controlSelectedPid
		)
	}

}
