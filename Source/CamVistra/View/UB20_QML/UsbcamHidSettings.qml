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
		onExtensionJsonArrayRead: {
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

		onCameraClosed: {
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
		onCurrentImagePropChanged: {
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
		onSetExposureMode: {
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

		onSetFocusMode: {
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

		onSetUvcAntiFlicker: {
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
		onSetUvcGainValue: {
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
		// Shorthand for the See3CAM_27CUG handlers below: forwards the changed
		// fields returned by See3CAM27CUGModelData to triggerUpdateSignal().
		function a27(c){triggerUpdateSignal(c)}
		onStreamModeReceived: {a27(See3CAM27CUGModelData.updateStream(mode))}
		onStrobeModeReceived: {a27(See3CAM27CUGModelData.updateStrobe(mode))}
		onCameraModeReceived: {a27(See3CAM27CUGModelData.updateCamera(mode))}
		onOrientationReceived: {a27(See3CAM27CUGModelData.updateOrientation(orientation))}
		onBrightnessReceived: {a27(See3CAM27CUGModelData.slider("brightnessSlider",value))}
		onContrastReceived: {a27(See3CAM27CUGModelData.slider("contrastSlider",value))}
		onGainReceived: {a27(See3CAM27CUGModelData.slider("gainSlider",value))}
		onMinimumExposureReceived: {a27(See3CAM27CUGModelData.text("minExpTextField",exposure))}
		onMaximumExposureReceived: {a27(See3CAM27CUGModelData.text("maxExpTextField",exposure))}
		onSerialNumberReceived: {a27(See3CAM27CUGModelData.text("serialNumber",serialNumber))}
	}
	Connections {
		target: see3cam37cugController
		// Shorthand for the See3CAM_37CUG handlers below: forwards the changed
		// fields returned by See3CAM37CUGModelData to triggerUpdateSignal().
		function apply37CUG(changes) { triggerUpdateSignal(changes) }
		onCameraModeReceived: { apply37CUG(See3CAM37CUGModelData.updateCameraMode(mode)) }
		onOrientationReceived: { apply37CUG(See3CAM37CUGModelData.updateOrientation(orientation)) }
		onGainPropertiesReceived: { apply37CUG(See3CAM37CUGModelData.updateGain(mode, feature, minimum, maximum, current, step)) }
		onStrobeModeReceived: { apply37CUG(See3CAM37CUGModelData.updateStrobe(mode)) }
		onBurstLengthReceived: { apply37CUG(See3CAM37CUGModelData.updateBurst(length)) }
		onExposurePropertiesReceived: { apply37CUG(See3CAM37CUGModelData.updateExposure(mode, feature, seconds, milliSeconds, microSeconds)) }
		onTargetBrightnessReceived: { apply37CUG(See3CAM37CUGModelData.updateTargetBrightness(minimum, maximum, step, current)) }
		onAntiFlickerModeReceived: { apply37CUG(See3CAM37CUGModelData.updateAntiFlicker(mode)) }
		onStatisticsReceived: { apply37CUG(See3CAM37CUGModelData.updateStatistics(seconds, milliSeconds, microSeconds, gain)) }
		onTemperatureReceived: { apply37CUG(See3CAM37CUGModelData.updateTemperature(temperature)) }
		onFastAutoExposureReceived: { apply37CUG(See3CAM37CUGModelData.updateFastAutoExposure(mode)) }
		onExposureCompensationReceived: { apply37CUG(See3CAM37CUGModelData.updateExposureCompensation(seconds, milliSeconds, microSeconds)) }
		onFaeTargetBrightnessReceived: { apply37CUG(See3CAM37CUGModelData.updateFAETargetBrightness(minimum, maximum, step, current)) }
		onFaeExecutionFramesReceived: { apply37CUG(See3CAM37CUGModelData.updateFAEExecutionFrames(frames)) }
		onIspFirmwareVersionReceived: { apply37CUG(See3CAM37CUGModelData.updateISPFirmwareVersion(version)) }
	}
	Connections {
		target: see3camcu83Controller
		// Shorthand for the See3CAM_CU83 handlers below: forwards the changed
		// fields returned by See3CAMCU83ModelData to triggerUpdateSignal().
		function applyCU83(c) { triggerUpdateSignal(c) }
		onSpecialModeReceived: {applyCU83(See3CAMCU83ModelData.updateSpecial(mode))}
		onDenoiseValueReceived: {applyCU83(See3CAMCU83ModelData.updateDenoise(value))}
		onRoiAutoExpReceived: {applyCU83(See3CAMCU83ModelData.updateROI(mode,windowSize))}
		onOrientationReceived: {applyCU83(See3CAMCU83ModelData.updateOrientation(orientation))}
		onExposureCompensationReceived: {applyCU83(See3CAMCU83ModelData.updateExposure(exposure))}
		onFrameRateReceived: {applyCU83(See3CAMCU83ModelData.updateFrameRate(value,minimum,maximum))}
		onBurstLengthReceived: {applyCU83(See3CAMCU83ModelData.updateBurst(length))}
		onAntiFlickerReceived: {applyCU83(See3CAMCU83ModelData.updateFlicker(mode))}
		onWakeOnMotionReceived: {applyCU83(See3CAMCU83ModelData.updateWake(status))}
		onFaceDetectionReceived: {applyCU83(See3CAMCU83ModelData.updateFace(enabled,overlay,embeddedData))}
		onStreamModeReceived: {applyCU83(See3CAMCU83ModelData.updateStream(mode))}
		onFlashModeReceived: {applyCU83(See3CAMCU83ModelData.updateFlash(mode))}
	}

	Connections {
		target: see3camcu31Controller
		// Shorthand for the See3CAM_CU31 handlers below: forwards the changed
		// fields returned by See3CAMCU31ModelData to triggerUpdateSignal().
		function applyCU31(changes) { triggerUpdateSignal(changes) }
		onOrientationReceived: { applyCU31(See3CAMCU31ModelData.updateOrientation(orientation)) }
		onRawNoiseReductionReceived: { applyCU31(See3CAMCU31ModelData.updateRNR(status)) }
		onTriggerModeReceived: { applyCU31(See3CAMCU31ModelData.updateTrigger(mode)) }
		onAeConvergenceSpeedReceived: { applyCU31(See3CAMCU31ModelData.updateAESpeed(speed)) }
		onAutoExposureStatusReceived: { applyCU31(See3CAMCU31ModelData.updateAEStatus(status)) }
		onAwbStatusReceived: { applyCU31(See3CAMCU31ModelData.updateAWBStatus(status)) }
		onTemperatureReceived: { applyCU31(See3CAMCU31ModelData.setText("readTempTextField", temperature)) }
		onAntiFlickerModeReceived: { applyCU31(See3CAMCU31ModelData.updateFlicker(mode)) }
		onCameraModeReceived: { applyCU31(See3CAMCU31ModelData.updateCameraMode(mode)) }
		onAeWindowOverlayReceived: { applyCU31(See3CAMCU31ModelData.updateOverlay("AEWindow", status)) }
		onAeWindowDimensionsReceived: { applyCU31(See3CAMCU31ModelData.updateAEWindow(width,height,xStart,yStart)) }
		onAeMaskOverlayReceived: { applyCU31(See3CAMCU31ModelData.updateOverlay("AEMask", status)) }
		onAeMaskDimensionsReceived: { applyCU31(See3CAMCU31ModelData.updateAEMask(includeId,id,state,width,height,xStart,yStart)) }
		onAwbWindowOverlayReceived: { applyCU31(See3CAMCU31ModelData.updateOverlay("AWBWindow", status)) }
		onAwbWindowDimensionsReceived: { applyCU31(See3CAMCU31ModelData.updateAWBWindow(width,height,xStart,yStart)) }
		onAwbMaskOverlayReceived: { applyCU31(See3CAMCU31ModelData.updateOverlay("AWBMask", status)) }
		onAwbMaskDimensionsReceived: { applyCU31(See3CAMCU31ModelData.updateAWBMask(includeId,id,state,width,height,xStart,yStart)) }
		onPresetPropertiesReceived: { applyCU31(See3CAMCU31ModelData.updatePreset(mode)) }
		onSerialNumberReceived: { applyCU31(See3CAMCU31ModelData.setText("serial_no_selected", serialNumber)) }
		onIspFirmwareVersionReceived: { applyCU31(See3CAMCU31ModelData.setText("ispFirmwareVersion", version)) }
	}

	Connections {
		target : ecam212usbUvcextController
		onFirmwareVersionReceived: {
			UsbcamExtensionModelData.updateFirmwareVersioninUI(firmwareVer)
		}
		onHdrModeReceived: {
			UsbcamExtensionModelData.updateHDRMode(value)
			usbcamHidProperty = UsbcamExtensionModelData.getUsbcamExtensionModelData()
		}
		onAeModeReceived: {
			UsbcamExtensionModelData.updateAEMode(value)
		}
		onExpCompMaxReceived: {
			UsbcamExtensionModelData.updateExpCompMaxRange(min, max, value)
		}
		onExpCompMinReceived: {
			UsbcamExtensionModelData.updateExpCompMinRange(min, max, value)
		}
		onHorizontalFlipReceived: {
			UsbcamExtensionModelData.updateHorizontalFlip(value)
		}
		onVerticalFlipReceived: {
			UsbcamExtensionModelData.updateVerticalFlip(value)
		}
	}

	Connections {
		target: see3camcu200mController
		onStreamModeReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}
		onFlashModeReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}
		onOrientationReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateOrientation(flipMode)
			triggerUpdateSignal(changedFields)
		}
		onSerialNumberReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}
		onFirmwareVersionReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200M) return
			var changedFields = See3CAMCU200MModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu200Controller
		// Shorthand for the See3CAM_CU200 handlers below: forwards changed fields to
		// triggerUpdateSignal() only when the selected camera is a See3CAM_CU200.
		function cu200(c){ if (currentDevType() === DeviceEnums.See3CAM_CU200) triggerUpdateSignal(c) }
		onBrightnessReceived: {cu200(See3CAMCU200ModelData.updateBrightness(min,max,step,current))}
		onContrastReceived: {cu200(See3CAMCU200ModelData.updateContrast(min,max,step,current))}
		onSaturationReceived: {cu200(See3CAMCU200ModelData.updateSaturation(min,max,step,current))}
		onGammaReceived: {cu200(See3CAMCU200ModelData.updateGamma(min,max,step,current))}
		onSharpnessReceived: {cu200(See3CAMCU200ModelData.updateSharpness(min,max,step,current))}
		onBlackLevelReceived: {cu200(See3CAMCU200ModelData.updateBlackLevel(min,max,step,current))}
		onTargetBrightnessReceived: {cu200(See3CAMCU200ModelData.updateTargetBrightness(min,max,step,current))}
		onColorTemperatureReceived: {cu200(See3CAMCU200ModelData.updateColorTemperature(min,max,step,current))}
		onRGainReceived: {cu200(See3CAMCU200ModelData.updateRGain(min,max,step,current))}
		onBGainReceived: {cu200(See3CAMCU200ModelData.updateBGain(min,max,step,current))}
		onColorCorrectionMatrixReceived: {cu200(See3CAMCU200ModelData.updateColorCorrectionMatrix(Rr,Rg,Rb,Gr,Gg,Gb,Br,Bg,Bb))}
		onExposureReceived: {cu200(See3CAMCU200ModelData.updateExposure(mode,autoFeature,manualValue))}
		onExposureCompensationReceived: {cu200(See3CAMCU200ModelData.updateExposureCompensation(value))}
		onAutoGainUpperLimitReceived: {cu200(See3CAMCU200ModelData.updateAutoGainUpperLimit(min,max,step,current))}
		onAutoExpROIReceived: {cu200(See3CAMCU200ModelData.updateAutoExpROI(roiMode,winSize))}
		onCameraModeReceived: {cu200(See3CAMCU200ModelData.updateCameraMode(cameraMode))}
		onStrobeModeReceived: {cu200(See3CAMCU200ModelData.updateStrobeMode(strobeMode))}
		onOrientationReceived: {cu200(See3CAMCU200ModelData.updateOrientation(flipMode))}
		onAntiFlickerModeReceived: {cu200(See3CAMCU200ModelData.updateAntiFlickerMode(antiFlicker))}
		onWhiteBalanceReceived: {cu200(See3CAMCU200ModelData.updateWhiteBalance(mode,autoFeature,manualFeature))}
		onWhiteBalancePresetReceived: {cu200(See3CAMCU200ModelData.updateWhiteBalancePreset(presetMode))}
		onDenoiseFlagReceived: {cu200(See3CAMCU200ModelData.updateDenoiseFlag(flag))}
		onDenoiseStrengthReceived: {cu200(See3CAMCU200ModelData.updateDenoiseStrength(min,max,step,current))}
		onStatisticsReceived: {cu200(See3CAMCU200ModelData.updateStatistics(exposure,autoGain,rGain,bGain,Rr,Rg,Rb,Gr,Gg,Gb,Br,Bg,Bb))}
		onIspFirmwareVersionReceived: {cu200(See3CAMCU200ModelData.updateIspFirmwareVersion(firmwareVersion))}
		
		onSerialNumberReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200) return
			var changedFields = See3CAMCU200ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}
		onFirmwareVersionReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU200) return
			var changedFields = See3CAMCU200ModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu55mhController
		onStreamModeReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}
		onFlashModeReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}
		onOrientationReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateOrientation(flipMode)
			triggerUpdateSignal(changedFields)
		}
		onSerialNumberReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}
		onFirmwareVersionReceived: {
			if (currentDevType() !== DeviceEnums.See3CAM_CU55_MH) return
			var changedFields = See3CAMCU55MHModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3cam130eController

		// Firmware
		onFirmwareVersionReceived: {
			var changedFields = See3CAM130EModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
			See3CAM130EModelData.callSupportFunctions() 
		}

		onSerialNumberReceived: {
			var changedFields = See3CAM130EModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Scene / Effect / Denoise
		onSceneModeReceived: {
			var changedFields = See3CAM130EModelData.updateSceneMode(sceneMode)
			triggerUpdateSignal(changedFields)
		}

		onEffectModeReceived: {
			var changedFields = See3CAM130EModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		onDenoiseValueReceived: {
			var changedFields = See3CAM130EModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Focus
		onAfModeReceived: {
			var changedFields = See3CAM130EModelData.updateAFMode(afMode)
			triggerUpdateSignal(changedFields)
		}

		onRoiAfModeReceived: {
			var changedFields = See3CAM130EModelData.updateRoiAFMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		onAfRectModeReceived: {
			var changedFields = See3CAM130EModelData.updateAFRectMode(afRectMode)
			triggerUpdateSignal(changedFields)
		}

		onAfPositionReceived: {
			var changedFields = See3CAM130EModelData.updateAFPosition(afPosition)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		onRoiAutoExpModeReceived: {
			var changedFields = See3CAM130EModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		onAutoExposureReceived: {
			var changedFields = See3CAM130EModelData.updateAutoExposure(autoExposure)
			triggerUpdateSignal(changedFields)
		}

		onExposureCompReceived: {
			var changedFields = See3CAM130EModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// HDR
		onHdrModeReceived: {
			var changedFields = See3CAM130EModelData.updateHDRMode(hdrMode, hdrValue)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		onBurstLengthReceived: {
			var changedFields = See3CAM130EModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		onQFactorReceived: {
			var changedFields = See3CAM130EModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		onFrameRateReceived: {
			var changedFields = See3CAM130EModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Stream / Flip / AntiFlicker
		onStreamModeReceived: {
			var changedFields = See3CAM130EModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		onFlipModeReceived: {
			var changedFields = See3CAM130EModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		onAntiFlickerModeReceived: {
			var changedFields = See3CAM130EModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		onFaceDetectModeReceived: {
			var changedFields = See3CAM130EModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// White Balance / Flash
		onAutoWhiteBalanceReceived: {
			var changedFields = See3CAM130EModelData.updateAWB(awbValue)
			triggerUpdateSignal(changedFields)
		}

		onFlashModeReceived: {
			var changedFields = See3CAM130EModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// RGB Gains
		onRedGainReceived: {
			var changedFields = See3CAM130EModelData.updateRedGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		onBlueGainReceived: {
			var changedFields = See3CAM130EModelData.updateBlueGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		onGreenGainReceived: {
			var changedFields = See3CAM130EModelData.updateGreenGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		// Auto Save Config
		onAutoSaveConfigReceived: {
			var changedFields = See3CAM130EModelData.updateAutoSaveConfig(autoSaveMode)
			triggerUpdateSignal(changedFields)			
		}
	}

	
	Connections {
		target: see3cam1318tcController

		// Firmware
		onFirmwareVersionReceived: {
			var changedFields = See3CAM1318_TCModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
			See3CAM1318_TCModelData.callSupportFunctions() 
		}

		onSerialNumberReceived: {
			var changedFields = See3CAM1318_TCModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Scene / Effect / Denoise
		onSceneModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateSceneMode(sceneMode)
			triggerUpdateSignal(changedFields)
		}

		onEffectModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		onDenoiseValueReceived: {
			var changedFields = See3CAM1318_TCModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Focus
		onAfModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateAFMode(afMode)
			triggerUpdateSignal(changedFields)
		}

		onRoiAfModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateRoiAFMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		onAfRectModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateAFRectMode(afRectMode)
			triggerUpdateSignal(changedFields)
		}

		onAfPositionReceived: {
			var changedFields = See3CAM1318_TCModelData.updateAFPosition(afPosition)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		onRoiAutoExpModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		onAutoExposureReceived: {
			var changedFields = See3CAM1318_TCModelData.updateAutoExposure(autoExposure)
			triggerUpdateSignal(changedFields)
		}

		onExposureCompReceived: {
			var changedFields = See3CAM1318_TCModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// HDR
		onHdrModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateHDRMode(hdrMode, hdrValue)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		onBurstLengthReceived: {
			var changedFields = See3CAM1318_TCModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		onQFactorReceived: {
			var changedFields = See3CAM1318_TCModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		onFrameRateReceived: {
			var changedFields = See3CAM1318_TCModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Stream / Flip / AntiFlicker
		onStreamModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		onFlipModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		onAntiFlickerModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		onFaceDetectModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// White Balance / Flash
		onAutoWhiteBalanceReceived: {
			var changedFields = See3CAM1318_TCModelData.updateAWB(awbValue)
			triggerUpdateSignal(changedFields)
		}

		onFlashModeReceived: {
			var changedFields = See3CAM1318_TCModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// RGB Gains
		onRedGainReceived: {
			var changedFields = See3CAM1318_TCModelData.updateRedGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		onBlueGainReceived: {
			var changedFields = See3CAM1318_TCModelData.updateBlueGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		onGreenGainReceived: {
			var changedFields = See3CAM1318_TCModelData.updateGreenGain(minVal, maxVal, currentVal)
			triggerUpdateSignal(changedFields)
		}

		// Auto Save Config
		onAutoSaveConfigReceived: {
			var changedFields = See3CAM1318_TCModelData.updateAutoSaveConfig(autoSaveMode)
			triggerUpdateSignal(changedFields)			
		}
	}

	Connections {
		target: see3camcu130Controller

		// Firmware
		onFirmwareVersionReceived: {
			var changedFields = See3CAMCU130ModelData.updateFirmwareVersioninUI(firmwareVersion)
			usbcamHidProperty = See3CAMCU130ModelData.getSee3CAMHidModelData()
			triggerUpdateSignal(changedFields)
			See3CAMCU130ModelData.callSupportFunctions() 
		}

		onSerialNumberReceived: {
			var changedFields = See3CAMCU130ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Scene / Effect / Denoise
		onSceneModeReceived: {
			var changedFields = See3CAMCU130ModelData.updateSceneMode(sceneMode)
			triggerUpdateSignal(changedFields)
		}

		onEffectModeReceived: {
			var changedFields = See3CAMCU130ModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		onDenoiseValueReceived: {
			var changedFields = See3CAMCU130ModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		onRoiAutoExpModeReceived: {
			var changedFields = See3CAMCU130ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		onExposureCompReceived: {
			var changedFields = See3CAMCU130ModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		onBurstLengthReceived: {
			var changedFields = See3CAMCU130ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		onQFactorReceived: {
			var changedFields = See3CAMCU130ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		onFrameRateReceived: {
			var changedFields = See3CAMCU130ModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Flip / AntiFlicker
		onFlipModeReceived: {
			var changedFields = See3CAMCU130ModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		onAntiFlickerModeReceived: {
			var changedFields = See3CAMCU130ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		onFaceDetectModeReceived: {
			var changedFields = See3CAMCU130ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		onSmileDetectModeReceived: {
			var changedFields = See3CAMCU130ModelData.updateSmileDetectMode(mode, embedData)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu135mh01r1Controller

		// Firmware
		onFirmwareVersionReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateFirmwareVersioninUI(firmwareVersion)
			usbcamHidProperty = See3CAMCU135M_H01R1ModelData.getSee3CAMHidModelData()
			triggerUpdateSignal(changedFields)
			See3CAMCU135M_H01R1ModelData.callSupportFunctions()
		}

		onSerialNumberReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Flash Control
		onFlashModeReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// Stream Mode
		onStreamModeReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// Flip Control
		onFlipModeReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateFlipMode(flipValue)
			triggerUpdateSignal(changedFields)
		}

		// ROI Auto Exposure
		onRoiAutoExpModeReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Black Level Adjustment
		onBlackLevelAdjustmentReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateBlackLevelAdjustment(blacklevel)
			triggerUpdateSignal(changedFields)
		}

		// Target Brightness
		onTargetBrightnessReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateTargetBrightness(brightness)
			triggerUpdateSignal(changedFields)
		}

		// Anti-Flicker
		onAntiFlickerModeReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateAntiFlickerMode(antiFlicker)
			triggerUpdateSignal(changedFields)
		}

		// Gain
		onGainModeReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateGainMode(gainMode, autoGainMode, gainValue)
			triggerUpdateSignal(changedFields)
		}

		// Exposure Mode
		onExposureModeReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateExposureMode(exposureMode)
			triggerUpdateSignal(changedFields)
		}

		// Gain / Exposure Limits
		onLowerLimitGainReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateGainLowerLimit(lowerLimit)
			triggerUpdateSignal(changedFields)
		}

		onUpperLimitGainReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateGainUpperLimit(upperLimit)
			triggerUpdateSignal(changedFields)
		}

		onExposureLowerLimitReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateExposureLowerLimit(lowerLimit)
			triggerUpdateSignal(changedFields)
		}

		onExposureUpperLimitReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateExposureUpperLimit(upperLimit)
			triggerUpdateSignal(changedFields)
		}

		onStatisticsReceived: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateStatistics(exposureUs, gainValue)
			triggerUpdateSignal(changedFields)
		}

		onCrossStillPropertiesSet: {
			var changedFields = See3CAMCU135M_H01R1ModelData.updateCrossStill(success)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu135Controller

		// Scene / Effect / Denoise
		onSceneModeValue: {
			var changedFields = See3CAMCU135ModelData.updateSceneMode(sceneMode)
			triggerUpdateSignal(changedFields)
		}

		onEffectModeValue: {
			var changedFields = See3CAMCU135ModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		onDenoiseValue: {
			var changedFields = See3CAMCU135ModelData.updateDenoiseValue(denoiseVal)
			triggerUpdateSignal(changedFields)
		}

		// iHDR Mode
		onHdrModeValue: {
			var changedFields = See3CAMCU135ModelData.updateHDRMode(hdrMode, hdrValue)
			triggerUpdateSignal(changedFields)
		}

		// Q Factor
		onQFactorValue: {
			var changedFields = See3CAMCU135ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// Stream Mode
		onStreamModeValue: {
			var changedFields = See3CAMCU135ModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// Flip / Mirror Mode
		onFlipMirrorModeChanged: {
			var changedFields = See3CAMCU135ModelData.updateFlipMode(flipMirrorMode)
			triggerUpdateSignal(changedFields)
		}

		// Burst Length
		onBurstLengthValue: {
			var changedFields = See3CAMCU135ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// ROI Auto Exposure
		onRoiAutoExpMode: {
			var changedFields = See3CAMCU135ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// Exposure Compensation
		onExposureCompValue: {
			var changedFields = See3CAMCU135ModelData.updateExposureComp(exposureCompensation)
			triggerUpdateSignal(changedFields)
		}

		// Frame Rate
		onFrameRateCtrlValue: {
			var changedFields = See3CAMCU135ModelData.updateFrameRate(frameRateVal)
			triggerUpdateSignal(changedFields)
		}

		// Anti-Flicker Mode
		onFlickerDetectionMode: {
			var changedFields = See3CAMCU135ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		onFaceDetectModeValue: {
			var changedFields = See3CAMCU135ModelData.updateFaceDetectMode(faceDetectMode, faceDetectEmbedDataValue, faceDetectOverlayRect)
			triggerUpdateSignal(changedFields)
		}

		// Smile Detection
		onSmileDetectModeValue: {
			var changedFields = See3CAMCU135ModelData.updateSmileDetectMode(smileDetectMode, smileDetectEmbedDataValue)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target : ecam16usbController
		onFirmwareVersionReceived: {
			UsbcamExtensionModelData.updateFirmwareVersioninUI(firmwareVer)
			usbcamHidProperty = UsbcamExtensionModelData.getUsbcamExtensionModelData()
		}
	}

	Connections {
		target : ecam82usbController
		onFirmwareVersionReceived: {
			UsbcamExtensionModelData.updateFirmwareVersioninUI(firmwareVer)
			usbcamHidProperty = UsbcamExtensionModelData.getUsbcamExtensionModelData()
		}
	}

     Connections {
          target: see3cam24cugController

          onSendEffectMode: {
               var changedFields = See3CAM24CUGModelData.updateEffectMode(effectMode)
               triggerUpdateSignal(changedFields)
          }

          onSendDenoiseValue: {
               var changedFields = See3CAM24CUGModelData.updateDenoiseValue(denoiseValue)
               triggerUpdateSignal(changedFields)
          }

          onRoiAutoExpModeValue: {
               var changedFields = See3CAM24CUGModelData.updateRoiAEMode(roiMode, winSize)
               triggerUpdateSignal(changedFields)
          }

          onBurstLengthValue: {
               var changedFields = See3CAM24CUGModelData.updateBurstLength(burstLength)
               triggerUpdateSignal(changedFields)
          }

          onQFactorValue: {
               var changedFields = See3CAM24CUGModelData.updateQFactor(qFactor)
               triggerUpdateSignal(changedFields)
          }

          onFlipMirrorModeChanged: {
               var changedFields = See3CAM24CUGModelData.updateFlipMode(flipMirrorMode)
               triggerUpdateSignal(changedFields)
          }

          onFrameRateCtrlValueReceived: {
               var changedFields = See3CAM24CUGModelData.updateFrameRate(frameRateCtrlValue)
               triggerUpdateSignal(changedFields)
          }

          onExposureCompValueReceived: {
               var changedFields = See3CAM24CUGModelData.updateExposureComp(exposureCompensation)
               triggerUpdateSignal(changedFields)
          }

          onFaceDetectModeValue: {
               var changedFields = See3CAM24CUGModelData.updateFaceDetectMode(faceDetectMode, faceDetectEmbedDataValue, faceDetectOverlayRect)
               triggerUpdateSignal(changedFields)
          }

          onFlashModeValue: {
               var changedFields = See3CAM24CUGModelData.updateFlashMode(flashMode)
               triggerUpdateSignal(changedFields)
          }

          onFlickerDetectionMode: {
               var changedFields = See3CAM24CUGModelData.updateAntiFlickerMode(flickerMode)
               triggerUpdateSignal(changedFields)
          }

          onStreamModeValue: {
               var changedFields = See3CAM24CUGModelData.updateStreamMode(streamMode, autoFunctionLock)
               triggerUpdateSignal(changedFields)
          }

          onSerialNumberReceived: {
               var changedFields = See3CAM24CUGModelData.updateSerialNumber(serialNum)
               triggerUpdateSignal(changedFields)
          }

          onFirmwareVersionReceived: {
               var changedFields = See3CAM24CUGModelData.updateFirmwareVersioninUI(firmwareVersion)
               triggerUpdateSignal(changedFields)
			   
				See3CAM24CUGModelData.callSupportFunctions()
			   usbcamHidProperty = See3CAM24CUGModelData.getSee3CAMHidModelData()
          }
     }

     Connections {
          target: see3camcu81Controller

          onCameraModeReceived: {
               var changedFields = See3CAMCU81ModelData.updateCameraMode(cameraMode)
               triggerUpdateSignal(changedFields)
          }

          onEffectModeReceived: {
               var changedFields = See3CAMCU81ModelData.updateEffectMode(effectMode)
               triggerUpdateSignal(changedFields)
          }

          onDenoiseValueReceived: {
               var changedFields = See3CAMCU81ModelData.updateDenoiseValue(denoiseValue)
               triggerUpdateSignal(changedFields)
          }

          onRoiAutoExpModeReceived: {
               var changedFields = See3CAMCU81ModelData.updateRoiAEMode(roiMode, winSize)
               triggerUpdateSignal(changedFields)
          }

          onAutoExposureReceived: {
               var changedFields = See3CAMCU81ModelData.updateAutoExposure(autoExposure)
               triggerUpdateSignal(changedFields)
          }

          onExposureCompReceived: {
               var changedFields = See3CAMCU81ModelData.updateExposureComp(expComp)
               triggerUpdateSignal(changedFields)
          }

          onBurstLengthReceived: {
               var changedFields = See3CAMCU81ModelData.updateBurstLength(burstLength)
               triggerUpdateSignal(changedFields)
          }

          onQFactorReceived: {
               var changedFields = See3CAMCU81ModelData.updateQFactor(qFactor)
               triggerUpdateSignal(changedFields)
          }

          onFrameRateReceived: {
               var changedFields = See3CAMCU81ModelData.updateFrameRate(frameRate)
               triggerUpdateSignal(changedFields)
          }

          onFlipModeReceived: {
               var changedFields = See3CAMCU81ModelData.updateFlipMode(flipMode)
               triggerUpdateSignal(changedFields)
          }

          onAntiFlickerModeReceived: {
               var changedFields = See3CAMCU81ModelData.updateAntiFlickerMode(flickerMode)
               triggerUpdateSignal(changedFields)
          }

          onFaceDetectModeReceived: {
               var changedFields = See3CAMCU81ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
               triggerUpdateSignal(changedFields)
          }

          onAutoWhiteBalanceReceived: {
               var changedFields = See3CAMCU81ModelData.updateAWB(awbValue)
               triggerUpdateSignal(changedFields)
          }

          onSerialNumberReceived: {
               var changedFields = See3CAMCU81ModelData.updateSerialNumber(serialNum)
               triggerUpdateSignal(changedFields)
          }

          onFirmwareVersionReceived: {
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
		onAwbPresetModeReceived: {
			var changedFields = See3CAMCU27ModelData.updateAWBPresetMode(awbMode)
			triggerUpdateSignal(changedFields)
		}

		onAwbLockStatusReceived: {
			var changedFields = See3CAMCU27ModelData.updateAWBLockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// AE
		// ---------------------------
		onAeMeteringModeReceived: {
			var changedFields = See3CAMCU27ModelData.updateAEMeteringMode(meterMode)
			triggerUpdateSignal(changedFields)
		}

		onAeLockStatusReceived: {
			var changedFields = See3CAMCU27ModelData.updateAELockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flicker
		// ---------------------------
		onFlickerModeReceived: {
			var changedFields = See3CAMCU27ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// JPEG / Burst
		// ---------------------------
		onQFactorReceived: {
			var changedFields = See3CAMCU27ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		onBurstLengthReceived: {
			var changedFields = See3CAMCU27ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Denoise / Roll
		// ---------------------------
		onDenoiseModeReceived: {
			var changedFields = See3CAMCU27ModelData.updateDenoiseMode(denoiseMode)
			triggerUpdateSignal(changedFields)
		}

		onRollValueReceived: {
			var changedFields = See3CAMCU27ModelData.updateRollValue(rollValue)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Firmware / Status
		// ---------------------------
		onIspFirmwareVersionReceived: {
			var changedFields = See3CAMCU27ModelData.updateISPFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
		}

		onSerialNumberReceived: {
			var changedFields = See3CAMCU27ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		onFirmwareVersionReceived: {
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
		onAfModeChanged: {
			var changedFields = See3CAM160ModelData.updateAFMode(afMode)
			triggerUpdateSignal(changedFields)
		}

		onAfStatusChanged: {
			var changedFields = See3CAM160ModelData.updateAFStatus(afstatus)
			triggerUpdateSignal(changedFields)
		}

		onManualLensPositionModeChanged: {
			var changedFields = See3CAM160ModelData.updateManualLensPosition(lensPosMode)
			triggerUpdateSignal(changedFields)
		}

		onAfLockStatusChanged: {
			var changedFields = See3CAM160ModelData.updateAFLockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		onAutoFocusRoiModeChanged: {
			// No model function yet
		}

		onCafScanRangeModeChanged: {
			var changedFields = See3CAM160ModelData.updateCAFScanRangeMode(scanRangeMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// AWB
		// ---------------------------
		onAwbPresetModeChanged: {
			var changedFields = See3CAM160ModelData.updateAWBPresetMode(awbMode)
			triggerUpdateSignal(changedFields)
		}

		onAwbLockStatusChanged: {
			var changedFields = See3CAM160ModelData.updateAWBLockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// AE
		// ---------------------------
		onAeLockStatusChanged: {
			var changedFields = See3CAM160ModelData.updateAELockStatus(lockStatus)
			triggerUpdateSignal(changedFields)
		}

		onAeMeterModeChanged: {
			var changedFields = See3CAM160ModelData.updateAEMeteringMode(meterMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Image / Capture
		// ---------------------------
		onQFactorValue: {
			var changedFields = See3CAM160ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		onBurstLengthValue: {
			var changedFields = See3CAM160ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flicker
		// ---------------------------
		onFlickerModeChanged: {
			var changedFields = See3CAM160ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Status / Firmware
		// ---------------------------

          onSerialNumberReceived: {
               var changedFields = See3CAM160ModelData.updateSerialNumber(serialNum)
               triggerUpdateSignal(changedFields)
          }

          onFirmwareVersionReceived: {
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
		onSpecialEffectReceived: {
			var changedFields = See3CAMCU84ModelData.updateEffectMode(effect)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Denoise
		// ---------------------------
		onDenoiseValueReceived: {
			var changedFields = See3CAMCU84ModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// ROI Auto Exposure
		// ---------------------------
		onRoiAutoExpModeReceived: {
			var changedFields = See3CAMCU84ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Burst Length
		// ---------------------------
		onBurstLengthReceived: {
			var changedFields = See3CAMCU84ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flip Mode
		// ---------------------------
		onFlipModeReceived: {
			var changedFields = See3CAMCU84ModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Exposure Compensation
		// ---------------------------
		onExposureCompReceived: {
			var changedFields = See3CAMCU84ModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Frame Rate
		// ---------------------------
		onFrameRateReceived: {
			var changedFields = See3CAMCU84ModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Anti-Flicker
		// ---------------------------
		onAntiFlickerModeReceived: {
			var changedFields = See3CAMCU84ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Stream Mode
		// ---------------------------
		onStreamModeReceived: {
			var changedFields = See3CAMCU84ModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flash Mode
		// ---------------------------
		onFlashModeReceived: {
			var changedFields = See3CAMCU84ModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Face Detection
		// ---------------------------
		onFaceDetectModeReceived: {
			var changedFields = See3CAMCU84ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Q Factor
		// ---------------------------
		onQFactorReceived: {
			var changedFields = See3CAMCU84ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Serial / Firmware / Status
		// ---------------------------
		onSerialNumberReceived: {
			var changedFields = See3CAMCU84ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		onFirmwareVersionReceived: {
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
		onStreamModeReceived: {
			var changedFields = See3CAMCU512MModelData.updateStreamMode(streamMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Flash Mode
		// ---------------------------
		onFlashModeReceived: {
			var changedFields = See3CAMCU512MModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Orientation / Flip
		// ---------------------------
		onOrientationReceived: {
			var changedFields = See3CAMCU512MModelData.updateOrientation(flipMode)
			triggerUpdateSignal(changedFields)
		}

		// ---------------------------
		// Serial / Firmware / Status
		// ---------------------------
		onSerialNumberReceived: {
			var changedFields = See3CAMCU512MModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		onFirmwareVersionReceived: {
			var changedFields = See3CAMCU512MModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)

			See3CAMCU512MModelData.callSupportFunctions()

			usbcamHidProperty = See3CAMCU512MModelData.getSee3CAMHidModelData()
		}
	}

	Connections {
		target: see3camcu58Controller

		// Firmware
		onFirmwareVersionReceived: {
			var changedFields = See3CAMCU58ModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
			See3CAMCU58ModelData.callSupportFunctions() 
		}

		onSerialNumberReceived: {
			var changedFields = See3CAMCU58ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Effect / Denoise
		onEffectModeReceived: {
			var changedFields = See3CAMCU58ModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		onDenoiseValueReceived: {
			var changedFields = See3CAMCU58ModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		onRoiAutoExpModeReceived: {
			var changedFields = See3CAMCU58ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		onExposureCompReceived: {
			var changedFields = See3CAMCU58ModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		onBurstLengthReceived: {
			var changedFields = See3CAMCU58ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		onQFactorReceived: {
			var changedFields = See3CAMCU58ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		onFrameRateReceived: {
			var changedFields = See3CAMCU58ModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Flip / AntiFlicker

		onFlipModeReceived: {
			var changedFields = See3CAMCU58ModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		onAntiFlickerModeReceived: {
			var changedFields = See3CAMCU58ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		onFaceDetectModeReceived: {
			var changedFields = See3CAMCU58ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// Flash
		onFlashModeReceived: {
			var changedFields = See3CAMCU58ModelData.updateFlashMode(flashMode)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target: see3camcu55Controller

		// Firmware
		onFirmwareVersionReceived: {
			var changedFields = See3CAMCU55ModelData.updateFirmwareVersioninUI(firmwareVersion)
			triggerUpdateSignal(changedFields)
			See3CAMCU55ModelData.callSupportFunctions() 
		}

		onSerialNumberReceived: {
			var changedFields = See3CAMCU55ModelData.updateSerialNumber(serialNum)
			triggerUpdateSignal(changedFields)
		}

		// Effect / Denoise
		onEffectModeReceived: {
			var changedFields = See3CAMCU55ModelData.updateEffectMode(effectMode)
			triggerUpdateSignal(changedFields)
		}

		onDenoiseValueReceived: {
			var changedFields = See3CAMCU55ModelData.updateDenoiseValue(denoiseValue)
			triggerUpdateSignal(changedFields)
		}

		// Auto Exposure
		onRoiAutoExpModeReceived: {
			var changedFields = See3CAMCU55ModelData.updateRoiAEMode(roiMode, winSize)
			triggerUpdateSignal(changedFields)
		}

		onExposureCompReceived: {
			var changedFields = See3CAMCU55ModelData.updateExposureComp(expComp)
			triggerUpdateSignal(changedFields)
		}

		// Burst / QFactor / FrameRate
		onBurstLengthReceived: {
			var changedFields = See3CAMCU55ModelData.updateBurstLength(burstLength)
			triggerUpdateSignal(changedFields)
		}

		onQFactorReceived: {
			var changedFields = See3CAMCU55ModelData.updateQFactor(qFactor)
			triggerUpdateSignal(changedFields)
		}

		onFrameRateReceived: {
			var changedFields = See3CAMCU55ModelData.updateFrameRate(frameRate)
			triggerUpdateSignal(changedFields)
		}

		// Flip / AntiFlicker
		onFlipModeReceived: {
			var changedFields = See3CAMCU55ModelData.updateFlipMode(flipMode)
			triggerUpdateSignal(changedFields)
		}

		onAntiFlickerModeReceived: {
			var changedFields = See3CAMCU55ModelData.updateAntiFlickerMode(flickerMode)
			triggerUpdateSignal(changedFields)
		}

		// Face Detection
		onFaceDetectModeReceived: {
			var changedFields = See3CAMCU55ModelData.updateFaceDetectMode(mode, embedData, overlayRect)
			triggerUpdateSignal(changedFields)
		}

		// Smile Detection
		onSmileDetectModeReceived: {
			var changedFields = See3CAMCU55ModelData.updateSmileDetectMode(mode, embedData)
			triggerUpdateSignal(changedFields)
		}

		// Flash
		onFlashModeReceived: {
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
		onFirmwareVersionReceived: {
			var changedFields = DensiCAMModelData.updateFirmwareVersioninUI(firmwareVersion)
			
			usbcamHidProperty = DensiCAMModelData.getDensiCAMHidModelData()
			triggerUpdateSignal(changedFields)
			DensiCAMModelData.callSupportFunctions()
		}

		onUniqueIDReceived: {
			var changedFields = DensiCAMModelData.updateUniqueID(uniqueID)
			triggerUpdateSignal(changedFields)
		}

		// ---- Extension Controls ----
		onPixelTargetValueReceived: {
			var changedFields = DensiCAMModelData.updatePixelTargetValue(value, status)
			triggerUpdateSignal(changedFields)
		}

		onDenoiseValueReceived: {
			var changedFields = DensiCAMModelData.updateDenoiseValue(value, status)
			triggerUpdateSignal(changedFields)
		}

		onOrientationReceived: {
			var changedFields = DensiCAMModelData.updateFlipMode(value, status)
			triggerUpdateSignal(changedFields)
		}

		// ---- Command Controls 8-bit range ----
		onBrightnessReceived: {
			var changedFields = DensiCAMModelData.updateBrightness(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		onContrastReceived: {
			var changedFields = DensiCAMModelData.updateContrast(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		onSaturationReceived: {
			var changedFields = DensiCAMModelData.updateSaturation(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		onSharpnessReceived: {
			var changedFields = DensiCAMModelData.updateSharpness(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		onGainReceived: {
			var changedFields = DensiCAMModelData.updateGain(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// ---- Command Controls  16-bit range ----
		onGammaReceived: {
			var changedFields = DensiCAMModelData.updateGamma(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		onManualWhiteBalanceReceived: {
			var changedFields = DensiCAMModelData.updateManualWhiteBalance(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// ---- Command Controls  32-bit range ----
		onManualExposureReceived: {
			var changedFields = DensiCAMModelData.updateManualExposure(minVal, maxVal, defVal, curVal, resVal, status)
			triggerUpdateSignal(changedFields)
		}

		// ---- Command Controls  single-byte ----
		onAutoWhiteBalanceReceived: {
			var changedFields = DensiCAMModelData.updateAutoWhiteBalance(value, status)
			triggerUpdateSignal(changedFields)
		}

		onAutoExposureReceived: {
			var changedFields = DensiCAMModelData.updateAutoExposure(value, status)
			triggerUpdateSignal(changedFields)
		}

		onLedReceived: {
			var changedFields = DensiCAMModelData.updateLED(value, status)
			triggerUpdateSignal(changedFields)
		}

		onImageCaptureReceived: {
			var changedFields = DensiCAMModelData.updateImageCapture(mode, status)
			triggerUpdateSignal(changedFields)
		}

		onSceneModeReceived: {
			var changedFields = DensiCAMModelData.updateSceneMode(mode, status)
			triggerUpdateSignal(changedFields)
		}
	}

	Connections {
		target : window
		onMouseRightClicked: {
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

	// Expands/collapses the extension-settings node with the given label (found
	// via findLabelIndex), counts the visible child rows it adds/removes, adjusts
	// heightVal/hidScrollHeight and grows or resets the flickable width.
	// For a level-2 node, also notifies logController.expandedExtItem() for each
	// expanded child.
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

	// Routes a slider change to the selected camera's model (by currentDevType());
	// unknown devices go to UsbcamExtensionModelData, whose dependent changes are
	// emitted individually. Otherwise emits fieldValueChanged for the slider.
	//Function for value update in the Slider   
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

	// Routes a radio-button change to the selected camera's model and emits
	// targeted usbcamHidAcc signals for the fields it reports changed. Also emits
	// setHidAntiFlicker("AUTO") for supported cameras on Linux, and restarts the
	// preview stream when trigger mode is disabled.
	//Function for value update in the radiobutton
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

    // Routes a drop-down selection to the selected camera's model and emits
    // enabled/selected updates for only the fields it reports changed.
	// OPTIMIZED: No full reload, only targeted updates
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

	// Routes a check-box change to the selected camera's model; unknown devices
	// fall back to UsbcamExtensionModelData.
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

	// Routes a text-field change to the selected camera's model; ignored for
	// devices without a dedicated model.
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

	// Routes a button click to the selected camera's model; for ECAM212_USB the
	// "resetBtn" id resets the device via ecam212usbUvcextController.
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

	// Reads all extension/HID controls of the selected camera by calling the
	// matching model's getCameraControls() (e-CAM USB devices share
	// UsbcamExtensionModelData).
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

	// Emits the matching usbcamHidAcc signal (enabled, selected, checked, text,
	// currentValue) for each entry of changedFields so only the affected controls
	// refresh.
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

	// Starts the 500 ms one-shot timer that re-reads the exposure compensation
	// and frame-rate controls from the selected camera's model.
	function getexposureCompFrameRateCtrl(){
		getexposureCompFrameRateCtrlTimer.start()
	}

	// Returns the DeviceEnums type of the selected camera, resolved from its
	// VID/PID via DeviceEnumInstance.
	// ADD this utility function inside UsbcamHidSettings:
	function currentDevType() {
		return DeviceEnumInstance.resolveDevice(
			controlSelectedVid,
			controlSelectedPid
		)
	}

}
