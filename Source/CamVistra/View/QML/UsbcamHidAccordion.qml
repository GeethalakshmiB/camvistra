import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.14
import "../JS/Usb_Hid.js" as UsbcamExtensionModelData

Column 
{
    id:column_main
	x: usbcamRect.x + 10

	property alias model: columnRepeater.model
	//radio button related code
	property var buttonNames: []
	property  var groupButton:[]

	property int leftMarginAlign: MonitorHandler ? 0.0915 * MonitorHandler.screenResolution.width : 125
	property int textFieldWidth: MonitorHandler ? 0.1098 * MonitorHandler.screenResolution.width : 150
	property int xPosValue: MonitorHandler ? 0.0878 * MonitorHandler.screenResolution.width : 120
	property int xPositionVal : MonitorHandler ? 0.0439 * MonitorHandler.screenResolution.width : 60
	property int leftMarginValue : MonitorHandler ? 0.0915 * MonitorHandler.screenResolution.width : 125
	property int sliderLeftMargin : MonitorHandler ? 0.0878 * MonitorHandler.screenResolution.width : 120
	property int sliderWidth : MonitorHandler ? 0.1171 * MonitorHandler.screenResolution.width : 160
	property int subentryIndent: 20  // sub-items are indented by this; unlabelled slider rows reclaim it
	property int sliderHeight : MonitorHandler ? 0.0052 * MonitorHandler.screenResolution.height : 4
	property int buttonHeight : MonitorHandler ? 0.03906 * MonitorHandler.screenResolution.height : 30 
	property int txtBoxLeftMargin : MonitorHandler ? 0.08784 * MonitorHandler.screenResolution.width : 120
	property int buttonW1 : MonitorHandler ? 0.1098 * MonitorHandler.screenResolution.width : 150
	property int buttonW2 : MonitorHandler ? 0.1024 * MonitorHandler.screenResolution.width : 140

	// SIGNALS FOR TARGETED UPDATES
    signal fieldChanged(string fieldId, bool enabled)
   	signal fieldOptionsChanged(string fieldId, var selected)
	signal fieldValueChanged(string fieldId, var newValue)
	signal fieldCheckedChanged(string fieldId, var checked)
	signal fieldVisibilityChanged(string fieldId, var visible)
	signal fieldTextChanged(string fieldId, var newText)

	Component {
		id: buttonGroupComponent
		ButtonGroup {}
	}

	property int count:1 

	// Returns the numeric id for a radio-button group name, creating a new ButtonGroup the
	// first time the name is seen so radio buttons of one group stay exclusive.
	function getButtonNames(groupName) {
		if (!buttonNames[groupName])
		{
			 buttonNames[groupName]=count++;
			 groupButton[buttonNames[groupName]]= Qt.createQmlObject('import QtQuick.Controls 2.12; ButtonGroup { }', parent);
		}
		return buttonNames[groupName];
	}

    // Repeater to iterate over the model data
    Repeater {
        id: columnRepeater
        model: UsbcamExtensionModelData.getUsbcamExtensionModelData() // Get the data from JS
        delegate: accordion
    }
	

    // Accordion component to handle each item in the data model
    Component {
        id: accordion
		
        Column {
			id: accordionColumn
            width: parent ? parent.width : 0

			property var itemData: modelData
			// Plain message entry with no control (NoAvailableExtension.json)
			property bool isMessage: !!itemData && itemData.id === "noHid"
            property bool itemEnabled: modelData.enabled !== undefined ? modelData.enabled : true

			// LISTEN TO TARGETED SIGNALS
            Connections {
                target: column_main
                
                // Handle enabled/disabled state changes
                function onFieldChanged(fieldId, enabled) {
                    if (accordionColumn.itemData.id === fieldId) {
                        accordionColumn.itemEnabled = enabled;
						accordionColumn.itemData.enabled = enabled
                    }
                }

				// Handles the accordion's fieldValueChanged signal: if fieldId matches this row (or its
				// first/second child), stores newValue and updates the checkbox, slider or label text.
				function onFieldValueChanged(fieldId, newValue) {

					if (accordionColumn.itemData.id === fieldId && 
						accordionColumn.itemData.value === "checkbox") {
						accordionColumn.itemData.currentValue = newValue;
						checkboxControl.checked = newValue;  // Use 'checked', not 'value'
						return;
					}
    
					// CHECK 1: Is THIS item a slider with matching ID?
					if (accordionColumn.itemData.id === fieldId && 
						accordionColumn.itemData.value === "slider" && newValue != undefined) {        
						accordionColumn.itemData.currentValue = newValue;
						sliderControl.value = newValue;
						sliderControl.forceUpdateVisuals();
        				return; // Exit early
					}

					// CHECK 2: Is a child a slider with matching ID?
					if (accordionColumn.itemData.children && 
						accordionColumn.itemData.children.length > 0 &&
						accordionColumn.itemData.children[0].id === fieldId) {
                
						if (newValue !== null && newValue !== undefined) {
							accordionColumn.itemData.children[0].currentValue = newValue;
            
							if(accordionColumn.itemData.children[0].value == "slider"){
								sliderControl.value = newValue;
								sliderControl.forceUpdateVisuals();
							}
            
							// Force text binding to update
							if(accordionColumn.itemData.children[0].value == "slider" || 
							   accordionColumn.itemData.children[0].value == "dropBox"){			
								textItm.text = accordionColumn.itemData.label 
							}
						}
					}
					
					if (accordionColumn.itemData.children && 
						accordionColumn.itemData.children.length > 0 && 
						 accordionColumn.itemData.children[1] &&
						accordionColumn.itemData.children[1].id === fieldId && 
						accordionColumn.itemData.children[1].value == "checkbox"){  
							accordionColumn.itemData.children[1].currentValue = newValue;
							checkboxControl.checked = newValue;  // Use 'checked', not 'value'
					}
    
   				}
                
                // Handle dropdown options changes
               // Handles the accordion's fieldOptionsChanged signal: selects the combo box entry whose
               // label equals selected (first entry if not found) without replacing the option list.
               function onFieldOptionsChanged(fieldId, selected) {
					if (accordionColumn.itemData.id === fieldId) {
						// No need to update options — just update selected index
						if (comboBox_id && selected !== undefined && selected !== null) {

							// Find index of selected label in existing model
							var currentOptions = accordionColumn.itemData.children_drop
							var index = -1

							for (var i = 0; i < currentOptions.length; i++) {
								if (currentOptions[i].label1 == selected) {
									index = i
									break
								}
							}

							if (index >= 0) {
								comboBox_id.currentIndex = index
							} else {
								// Default to first if selected label not found
								comboBox_id.currentIndex = 0
							}
						}
					}
				}

				// UPDATED: Handle checked state changes with forced refresh
				function onFieldCheckedChanged(fieldId, checked) {
					if (accordionColumn.itemData.id === fieldId) {
						// Update the data model
						accordionColumn.itemData.checked = checked;
						if(accordionColumn.itemData.value == "radioButton"){   
							// Force RadioButton to update if it exists
							if (rad_button && rad_button.checked !== checked) {
								rad_button.checked = checked;
							}
						} else if (accordionColumn.itemData.value == "checkbox"){
							// Force CheckBox to update if it exists
							if (checkboxControl && checkboxControl.checked !== checked) {
								checkboxControl.checked = checked;
							}
						}
					}
				}

				// Handle visibility changes
				function onFieldVisibilityChanged(fieldId, visible) {
					if (accordionColumn.itemData.id === fieldId) {
						accordionColumn.itemData.visible = visible;
					}
				}

				// Handle text field updates
				// Handles the accordion's fieldTextChanged signal: updates the stored text and the
				// visible TextField (textBox rows) or label text (label rows) for a matching field.
				function onFieldTextChanged(fieldId, newText) {
					if (accordionColumn.itemData.id == fieldId && accordionColumn.itemData.value == "textBox") {

						accordionColumn.itemData.text = newText;

						// Force TextField to update if it exists
						if (textField_id && textField_id.text !== newText) {
							// Temporarily disconnect to avoid triggering onTextChanged
							textField_id.text = newText;
						}
					}
					if (accordionColumn.itemData.id == fieldId && accordionColumn.itemData.value == "label") {

						accordionColumn.itemData.text = newText;

						// Force TextField to update if it exists
						if (textData && textData.text !== newText) {
							// Temporarily disconnect to avoid triggering onTextChanged
							textData.text = newText;
						}
					}
				}

            }

            Item{
                id: infoRow
                objectName: "infoRow"
				// Slider rows are taller: value above the handle, min/max under the track
				// A message row (e.g. "No extension available...") grows to fit its wrapped text
				height: accordionColumn.itemData.value === "slider" ? Math.max(0.052 * screenHeight, sliderRow.height)
				        : accordionColumn.isMessage ? Math.max(0.052 * screenHeight, textItm.implicitHeight + 10)
				        : 0.052 * screenHeight
                width: parent.width
                enabled: accordionColumn.itemEnabled
                visible: accordionColumn.itemData.visible !== undefined ? accordionColumn.itemData.visible : false
                property bool expanded: accordionColumn.itemData.expanded ? accordionColumn.itemData.expanded : false
			
				MouseArea {
					id: mouse_id
					objectName: "infoRowMouseArea"
					anchors.fill: parent
    
					onClicked: {
						if (modelData.value === "radioButton") {
							if (accordionColumn.itemEnabled && !rad_button.checked) {
								rad_button.checked = true
								rad_button.clicked()
							}
						} else if (modelData.value === "checkbox") {
							if (accordionColumn.itemEnabled) {
								checkboxControl.checked = !checkboxControl.checked
								checkboxControl.clicked()
							}
						} else {
							infoRow.expanded = !infoRow.expanded;
							if (infoRow.expanded == true && modelData.children) {
								logController.expandedExtItem(modelData.id)
							}
							if (modelData.children) {
								setExpandedState(modelData.label, infoRow.expanded);
							}
						}
					}
				}
                Image {
                    id: carot
					anchors.verticalCenter: parent.verticalCenter
					anchors.left: parent.left
					anchors.leftMargin: 0
					x: 0
                    sourceSize.width: expandedStateIconW
                    sourceSize.height: expandedStateIconH
                    source: "qrc:View/icons/right-arrow.svg"
                    visible: (accordionColumn.itemData.children && accordionColumn.itemData.value !== "radioButton" ? true : false)
                    transform: Rotation {
                        origin.x: 5
                        origin.y: 10
                        angle: infoRow.expanded ? 90 : 0 //90
                        Behavior on angle { NumberAnimation { duration: 150 } } //
                     }    
				}                

                Text {
					id:textItm
                    // Message rows wrap within the visible settings width instead of running off it
                    width: accordionColumn.isMessage ? Math.max(0, settingsScroll.width - x - 10) : implicitWidth
                    wrapMode: accordionColumn.isMessage ? Text.WordWrap : Text.NoWrap
                    anchors.left: carot.visible ? carot.right : parent.left
					anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: (accordionColumn.itemData.value === 'radioButton' || accordionColumn.itemData.value === 'checkbox') ? 40 : 12
                    font.pixelSize: menuFontSize
					color: accordionColumn.itemEnabled ? "#ffffff" : "#808080"  // Visual feedback
					text: {
						if (!accordionColumn.itemData.label) return ""
    
						var hasChildren = accordionColumn.itemData.children && accordionColumn.itemData.children.length > 0
						if (!hasChildren) return accordionColumn.itemData.label
    
						var currentVal = accordionColumn.itemData.children[0].currentValue
						var valueStr = (currentVal !== undefined && currentVal !== null) ? String(currentVal) : ""
    
						return accordionColumn.itemData.label
					}	
                }				
			}

			//Slider
			Item {
				id: slider_item
				visible: accordionColumn.itemData.value === "slider"
				enabled: accordionColumn.itemEnabled
				opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
				Item {
					id: sliderRow
					anchors.left: parent.left
					anchors.leftMargin: accordionColumn.itemData.label ? sliderLeftMargin : -subentryIndent 
					// Fixed-width track; value above the handle, min/max under the track ends
					width: sliderControl.width
					height: sliderValueLabel.height + 2 + sliderControl.height + 2 + sliderMinLabel.height


					Text {
						id: sliderMinLabel
						text: sliderControl.from
						color: accordionColumn.itemEnabled ? "white" : "#808080"
						font.pixelSize: menuFontSize
						anchors.top: sliderControl.bottom
						anchors.topMargin: 2
						anchors.left: sliderControl.left
					}
					Slider {
						id: sliderControl
						objectName: "sliderControl"
						y: sliderValueLabel.height + 2
						enabled: accordionColumn.itemEnabled
						width: sliderWidth
						// No side padding: the track uses the whole slider width
						leftPadding: 0
						rightPadding: 0
						topPadding: 0
						bottomPadding: 0
						from: (accordionColumn.itemData.min !== undefined && typeof accordionColumn.itemData.min === "number") ? accordionColumn.itemData.min : 0
						to: (accordionColumn.itemData.max !== undefined && typeof accordionColumn.itemData.max === "number") ? accordionColumn.itemData.max : 100
						stepSize: (accordionColumn.itemData.step !== undefined && typeof accordionColumn.itemData.step === "number") ? accordionColumn.itemData.step : 1
						value: (accordionColumn.itemData.currentValue !== undefined && typeof accordionColumn.itemData.currentValue === "number") ? accordionColumn.itemData.currentValue : from

						background: Rectangle {
							x: sliderControl.leftPadding
							anchors.verticalCenter: parent.verticalCenter
							implicitWidth: tabBarWidth
							implicitHeight: sliderHeight
							width: sliderControl.availableWidth
							height: implicitHeight
							radius: 2
							color: accordionColumn.itemEnabled ? "#bdbebf" : "#D3D3D3"

							Rectangle {
								id: progressBar
								width: sliderControl.visualPosition * parent.width
								height: parent.height
								color: accordionColumn.itemEnabled ? "#2087cc" : "#808080"
								radius: 2
							}
						}
    
						handle: Rectangle {
							id: sliderHandle  // Give it an ID
							x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width) 
							anchors.verticalCenter: parent.verticalCenter
							implicitWidth: expandedStateIconH
							implicitHeight: expandedStateIconW
							radius: checkBoxFontSize
							color: accordionColumn.itemEnabled ? "#f0f0f0" : "#808080"
							border.color: "#bdbebf"
						}
    
						// Add a function to force update visuals
						function forceUpdateVisuals() {
							// Re-establish these as live bindings (not one-shot assignments) so the
							// handle/progress bar keep tracking value changes after this call too -
							// a plain assignment here would permanently break their declarative bindings.
							sliderHandle.x = Qt.binding(function() {
								return sliderControl.leftPadding +
									   sliderControl.visualPosition *
									   (sliderControl.availableWidth - sliderHandle.width);
							});
							progressBar.width = Qt.binding(function() {
								return sliderControl.visualPosition * progressBar.parent.width;
							});
						}

						MouseArea {
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							// Steps the slider by one stepSize per mouse-wheel notch (clamped to from/to) when the
							// row is enabled, and consumes the wheel event.
							onWheel: function(wheel) {
								if (!accordionColumn.itemEnabled)
									return;

								if (wheel.angleDelta.y > 0) {
									sliderControl.value = Math.min(
										sliderControl.to,
										sliderControl.value + sliderControl.stepSize
									);
								} else {
									sliderControl.value = Math.max(
										sliderControl.from,
										sliderControl.value - sliderControl.stepSize
									);
								}

								wheel.accepted = true;
							}
						}
    
						onPressedChanged: {
							if (accordionColumn.itemEnabled && 
                                            isHidInitialized == true) {
								accordionColumn.itemData.currentValue = value;
								var childId = accordionColumn.itemData.id;
								if (accordionColumn.itemData.children && accordionColumn.itemData.children.length > 0) {
									childId = accordionColumn.itemData.children[0].id;
								}
								handleSliderValChanged(accordionColumn.itemData.label, childId, value);
							}
						}
					}
					Text {
						id: sliderMaxLabel
						text: sliderControl.to
						color: accordionColumn.itemEnabled ? "white" : "#808080"
						font.pixelSize: menuFontSize
						anchors.top: sliderControl.bottom
						anchors.topMargin: 2
						anchors.right: sliderControl.right
					}
					Text {
						id: sliderValueLabel
						text: sliderControl.value
                        color: accordionColumn.itemEnabled ? "white" : "#808080"
						font.pixelSize: menuFontSize
						// Centred over the handle, kept within the track
						y: 0
						x: Math.max(0, Math.min(sliderControl.width - width, sliderControl.x + sliderControl.handle.x + sliderControl.handle.width / 2 - width / 2))
					}
				}
			}

			//Radio-button
			Item {
				id: radio_item
				visible: accordionColumn.itemData.value === 'radioButton'
				enabled: accordionColumn.itemEnabled
				opacity: accordionColumn.itemEnabled ? 1.0 : 0.3

				Row {
					x: infoRow.x
					height: 0.052 * screenHeight           // same row height as slider
					spacing: 10

					RadioButton {
						id: rad_button
						objectName: "rad_button"
						anchors.verticalCenter: parent.verticalCenter
						scale: 0.60
						checked: accordionColumn.itemData.checked ? accordionColumn.itemData.checked : false

						// ── Custom indicator styling ──────────────────────────────
						indicator: Rectangle {
							implicitWidth: 26
							implicitHeight: 26
							radius: 13
							x: rad_button.leftPadding
							y: parent.height / 2 - height / 2
							border.color: rad_button.checked ? "#2087cc" : "#888888"
							border.width: 2
							color: rad_button.checked ? "#2087cc" : "#ffffff"   // blue fill when checked, white when not

							Rectangle {
								anchors.centerIn: parent
								width: 10
								height: 10
								radius: 5
								color: "#ffffff"               // white dot in the center
								visible: rad_button.checked
							}
						}

						onClicked: {
							let group = groupButton[getButtonNames(itemData.identification)];

							if (group && group.buttons && typeof group.buttons === "object") {
								let buttons = group.buttons;
								for (let key in buttons) {
									let btn = buttons[key];
									btn.checked = (btn === rad_button);
								}
							}

							// Call the change handler if defined
							if (typeof accordionColumn.itemData.onChange === "string" && typeof window[accordionColumn.itemData.onChange] === "function") {
								window[accordionColumn.itemData.onChange](accordionColumn.itemData.id);
							}

							// Update visibility of child elements dynamically
							if (Array.isArray(accordionColumn.itemData.children)) {
								for (let i = 0; i < accordionColumn.itemData.children.length; i++) {
									let child = accordionColumn.itemData.children[i];
									child.visible = rad_button.checked;
								}
							}
							radioButtonChanged(accordionColumn.itemData.identification, accordionColumn.itemData.id, checked)
						}
							
						MouseArea {
							id: radioBtnMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							ToolTip {
								id: radioBtnTooltip
								width : 500
								visible: radioBtnMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip !== undefined
								delay: 1000  // optional: show after delay
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									//implicit
									implicitHeight: radioBtnTextItem.paintedHeight 
								}
								contentItem: Text {
									id: radioBtnTextItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}								
						}
						Component.onCompleted: {
							ButtonGroup.group = groupButton[getButtonNames(itemData.identification)]
						}
					}
				}
			}

			//Label
			Item {
				id: label_item
				visible: accordionColumn.itemData.value === 'label'
				enabled: accordionColumn.itemEnabled
				opacity: accordionColumn.itemEnabled ? 1.0 : 0.3

				Row {
					anchors.left: parent.left
					anchors.leftMargin: sliderLeftMargin
					height: 0.052 * screenHeight
					spacing: 10

					Text {
						id: textData
						anchors.verticalCenter: parent.verticalCenter  // ← was anchors.left: parent.right (wrong parent ref)
						font.pixelSize: menuFontSize
						color: "#ffffff"
						text: modelData.text ? modelData.text : ""

						MouseArea {
							id: labelMouseArea
							anchors.fill: parent
							hoverEnabled: true

							ToolTip {
								id: labelCustomTooltip
								visible: labelMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
								delay: 200
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									implicitWidth: labelTextItem.paintedWidth + 16 < 500 ? labelTextItem.paintedWidth + 16 : 500
									implicitHeight: labelTextItem.paintedHeight
								}
								contentItem: Text {
									id: labelTextItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}
						}
					}
				}
			}

			// DROP BOX
			Item {
				id: drop_item
				visible: accordionColumn.itemData.value === 'dropBox'
				enabled: accordionColumn.itemEnabled
				opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
				// ← remove manual anchors.left/top/topMargin here, let Row handle layout

				// Returns the combo box index of the item's currently selected option (0 if none/not found).
				function getInitialIndex() {
					if (!accordionColumn.itemData.selected || !Array.isArray(accordionColumn.itemData.children_drop))
						return 0;
					for (var i = 0; i < accordionColumn.itemData.children_drop.length; ++i) {
						if (accordionColumn.itemData.children_drop[i].label1 == accordionColumn.itemData.selected)
							return i;
					}
					return 0;
				}

				Row {
					anchors.left: parent.left
					anchors.leftMargin: sliderLeftMargin   // ← consistent left margin
					height: 0.052 * screenHeight
					spacing: 15

					ComboBox {
						id: comboBox_id
						objectName: "comboBox_id"
						anchors.verticalCenter: parent.verticalCenter  // ← key fix
						enabled: accordionColumn.itemEnabled
						width: textFieldWidth
						height: menuItemHeight

						model: Array.isArray(accordionColumn.itemData.children_drop)
							? accordionColumn.itemData.children_drop.map(function(child) { return child.label1; })
							: []

						currentIndex: drop_item.getInitialIndex()

						indicator: Item {
							width: 14
							height: 16
							anchors.right: parent.right
							anchors.rightMargin: 5
							anchors.verticalCenter: parent.verticalCenter
							Canvas {
								anchors.fill: parent
								onPaint: {
									var ctx = getContext("2d");
									ctx.clearRect(0, 0, width, height);
									ctx.beginPath();
									ctx.moveTo(2, 4);
									ctx.lineTo(width - 2, 4);
									ctx.lineTo(width / 2, height - 2);
									ctx.closePath();
									ctx.fillStyle = accordionColumn.itemEnabled ? "#000000" : "#808080";
									ctx.fill();
								}
							}
						}

						delegate: ItemDelegate {
							width: comboBox_id.width
							height: comboBox_id.height
							contentItem: Text {
								text: modelData
								verticalAlignment: Text.AlignVCenter
								font.pixelSize: 12
								color: "black"
							}
							background: Rectangle {
								color: hovered ? "#2087cc" : "white"
								radius: 4
							}
						}

						background: Rectangle {
							implicitWidth: textFieldWidth
							implicitHeight: menuItemHeight
							radius: 6
							color: accordionColumn.itemEnabled ? "white" : "#D3D3D3"
							border.width: 1
							border.color: accordionColumn.itemEnabled ? "#000000" : "#808080"
						}

						contentItem: Text {
							text: comboBox_id.displayText
							font.family: "Arial"
							font.pixelSize: baseFontSize
							font.bold: false
							verticalAlignment: Text.AlignVCenter
							elide: Text.ElideRight
							color: accordionColumn.itemEnabled ? "black" : "#808080"
							leftPadding: 8
							rightPadding: 8
						}

						onActivated: {
							modelData.selected = comboBox_id.currentText;
							handleDropBoxValChanged(modelData.label, modelData.id, comboBox_id.currentText);
						}
					}
				}
			}
			
			//textbox
			Item {
				id: textBox_item
				enabled: accordionColumn.itemEnabled
				opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
				visible: accordionColumn.itemData.value === 'textBox' && accordionColumn.itemData.visible
							? accordionColumn.itemData.visible : false

				Row {
					anchors.left: parent.left
					anchors.leftMargin: sliderLeftMargin   // ← consistent left margin
					height: 0.052 * screenHeight
					spacing: 10

					TextField {
						id: textField_id
						objectName: "textField_id"
						anchors.verticalCenter: parent.verticalCenter  // ← key fix
						width: textFieldWidth
						height: menuItemHeight
						// ← removed empty Text label and manual anchor chain
						text: accordionColumn.itemData.text ? accordionColumn.itemData.text : ""
						color: "black"
						font.family: "Arial"
						font.pixelSize: textFieldFontSize
						font.bold: false

						readOnly: accordionColumn.itemData.readOnly ? accordionColumn.itemData.readOnly : false

						background: Rectangle {
							color: modelData.enabled ? "white" : "#cccccc"
							radius: 4
							border.color: "white"
						}

						onTextChanged: {
							modelData.text = textField_id.text;
							handleTextBoxValChanged(modelData.id, textField_id.text);
						}

						MouseArea {
							id: textFieldMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton
						}
					}
				}
			}

			//button
			Item
			{					
				enabled: accordionColumn.itemEnabled ? accordionColumn.itemEnabled : false
				opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
				visible: accordionColumn.itemData.value === 'button' && accordionColumn.itemData.visible ? accordionColumn.itemData.visible : false
				
				Button 
				{
					id:buttonid
					objectName: "buttonid"
					x: parent.x+ (xPositionVal)
					y: parent.y + 10
					width: buttonW2
					height: buttonHeight				
					text: modelData.name
					font.family: "Arial"
					font.pixelSize: menuFontSize
					font.bold: false
					background: Rectangle {
						id:button_rec
						implicitWidth: 100
						implicitHeight: 40
						color: "#2087cc"
						border.color: "#2087cc"
						border.width: 1
						radius: 4
					}
					MouseArea {
						id: mouseArea
						anchors.fill: parent
						hoverEnabled: true
						acceptedButtons: Qt.NoButton
						ToolTip {
							id: customTooltip
							visible: mouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
							delay: 200  // optional: show after delay
							background: Rectangle {
								color: window.titleBarColor
								border.color: window.titleBarColor
								border.width: 1
								implicitWidth: btnTextItem.paintedWidth + 16 < 500 ? btnTextItem.paintedWidth + 16 : 500
								implicitHeight: btnTextItem.paintedHeight
							}
							contentItem: Text {
								id: btnTextItem
								color: "white"
								font.pixelSize: baseFontSize + 1
								wrapMode: Text.WordWrap
								text: modelData.tooltip ? modelData.tooltip : ""
							}
						}
					}

					contentItem: RowLayout {

						Text {
							text: buttonid.text
							font: buttonid.font
							color: "white"
							verticalAlignment: Text.AlignVCenter
							horizontalAlignment: Text.AlignHCenter
							Layout.fillWidth: true  // Let text expand horizontally
							Layout.alignment: Qt.AlignVCenter
							elide: Text.ElideRight
						}
					}
					onPressed:{
						button_rec.color = "#1272b3"
					}
					onReleased:{
						button_rec.color = "#2087cc"
					}
					onClicked: {
						handleButtonClick(modelData.id)
					}
				}   	
			}

			// Checkbox
			Item {
				id: checkbox_item
				visible: accordionColumn.itemData.value === "checkbox"
				enabled: accordionColumn.itemEnabled
				opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
				height: 0.052 * screenHeight

				CheckBox {
					id: checkboxControl
					objectName: "checkboxControl"

					x: infoRow.x + 15

					anchors.verticalCenter: parent.verticalCenter  

					checked: accordionColumn.itemData.checked
							? accordionColumn.itemData.checked : false
					enabled: accordionColumn.itemEnabled

					width: expandedStateIconH
					height: expandedStateIconW

					indicator: Rectangle {
						implicitWidth: expandedStateIconH
						implicitHeight: expandedStateIconW
						radius: 3
						border.color: checkboxControl.checked ? "#2087cc" : "#bdbebf"
						color: checkboxControl.checked ? "#2087cc" : "#f0f0f0"

						Rectangle {
							visible: checkboxControl.checked
							anchors.centerIn: parent
							width: parent.width * 0.5
							height: parent.height * 0.5
							radius: 2
							color: "white"
						}
					}

					contentItem: Item {}

					onClicked: {
						if (accordionColumn.itemEnabled) {
							accordionColumn.itemData.checked = checked
							handleCheckBoxValChanged(
								accordionColumn.itemData.label,
								accordionColumn.itemData.id,
								checked
							)
						}
					}
				}
			}
			
			// ListView for handling recursive children (subitems)
			ListView {
				id: subentryColumn
				x: subentryIndent
				width: parent.width - x
				height: childrenRect.height * opacity
				visible: opacity > 0
				opacity: infoRow.expanded ? 1 : 0
				delegate: accordion
                model: (accordionColumn.itemData.children ? accordionColumn.itemData.children : [])
				interactive: false 
			}
		}  
	}
}
