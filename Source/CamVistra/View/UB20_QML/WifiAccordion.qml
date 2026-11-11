import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.14
import "../JS/Wifi.js" as ModelData

Column 
   {
    id:column_main
	x: wifiInnerRectangle.x + 10

	property alias model: columnRepeater.model
	//radio button related code
	property var buttonNames: []
	property  var groupButton:[]
	property int leftMarginAlign: MonitorHandler ? 0.0915 * MonitorHandler.screenResolution.width : 125
	property int textFieldWidth :  MonitorHandler ? 0.1098 * MonitorHandler.screenResolution.width : 150
	property int xPosValue : MonitorHandler ? 0.0878 *  MonitorHandler.screenResolution.width : 120
	property int xPositionVal : MonitorHandler ? 0.0439 * MonitorHandler.screenResolution.width : 60
	property int leftMarginValue : MonitorHandler ? 0.1 * MonitorHandler.screenResolution.width : 125
	property int sliderLeftMargin : MonitorHandler ? 0.0878 * MonitorHandler.screenResolution.width : 120
	property int sliderWidth : MonitorHandler ? 0.1171 * MonitorHandler.screenResolution.width : 160
	property int sliderHeight : MonitorHandler ? 0.0052 * MonitorHandler.screenResolution.height : 4
	property int buttonHeight : MonitorHandler ? 0.03906 * MonitorHandler.screenResolution.height : 30
	property int txtBoxLeftMargin : MonitorHandler ? 0.08784 * MonitorHandler.screenResolution.width : 120
	property int buttonW1 :  MonitorHandler ? 0.1098 * MonitorHandler.screenResolution.width : 150
	property int buttonW2 : MonitorHandler ? 0.1024 * MonitorHandler.screenResolution.width : 140

	// SIGNALS FOR TARGETED UPDATES
    signal fieldChanged(string fieldId, bool enabled)
    signal fieldOptionsChanged(string fieldId, var newOptions, var selected)
	signal fieldValueChanged(string fieldId, var newValue)
	signal fieldVisibilityChanged(string fieldId, var visible)
	signal fieldCheckedChanged(string fieldId, var checked)
	signal fieldExpandedChanged(string fieldId, var expanded)
	signal fieldTextChanged(string fieldId, var newText)
	signal fieldLabelTextChanged(string fieldId, var newText)

	Component {
		id: buttonGroupComponent
		ButtonGroup {}
	}

	property int count:1 
	// Function to get or create a ButtonGroup based on groupName
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
        objectName: "columnRepeater"
        model: ModelData.getModelData() // Get the data from JS
        delegate: accordion
    }
	

    // Accordion component to handle each item in the data model
    Component {
        id: accordion
		
        Column {
			id: accordionColumn
			objectName: modelData.id ? modelData.id : ""
            width: parent ? parent.width : 0

	
			property var itemData: modelData
            property bool itemEnabled: modelData.enabled !== undefined ? modelData.enabled : true

			Connections {
				target: column_main
				
				// Handle enabled/disabled state changes
				onFieldChanged: {

					if (accordionColumn.itemData.id === fieldId) {
						accordionColumn.itemEnabled = enabled;
						accordionColumn.itemData.enabled = enabled
					}
				}

				onFieldValueChanged: {
					updateAccordionField(accordionColumn.itemData, fieldId, newValue);	
					if (accordionColumn.itemData.id === fieldId && 
						accordionColumn.itemData.value === "slider") {        
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
						}
					}
				}
				
				// Handle dropdown options changes
				onFieldOptionsChanged: {					
					updateFieldOptions(accordionColumn.itemData, fieldId, newOptions, selected);
				}

				// Handle visibility changes
				onFieldVisibilityChanged: {
					if (accordionColumn.itemData.id === fieldId) {
						accordionColumn.itemData.visible = visible;
						if(fieldId == "preEventDuration" || fieldId == "postEventDuration" || fieldId == "usedGb" || fieldId == "totalGb" || fieldId == "freeGb" ){
							accordionColumn.itemDataChanged();
						}

					}
				}

				// Handle text field updates
				onFieldTextChanged: {
					if (accordionColumn.itemData.id == fieldId) {

						accordionColumn.itemData.text = newText;

						// Force TextField to update if it exists
						if (textField_id && textField_id.text !== newText) {
							// Temporarily disconnect to avoid triggering onTextChanged
							textField_id.text = newText;
						}
					}
				}

				onFieldLabelTextChanged: {
					if (accordionColumn.itemData.id == fieldId) {

						accordionColumn.itemData.text = newText;

						// Force TextField to update if it exists
						if (textData && textData.text !== newText) {
							// Temporarily disconnect to avoid triggering onTextChanged
							textData.text = newText;
						}
					}
				}

				// Handle expanded state changes
				onFieldExpandedChanged: {
					if (accordionColumn.itemData.id === fieldId) {
						accordionColumn.itemData.expanded = expanded;
					}
				}

				// UPDATED: Handle checked state changes with forced refresh
				onFieldCheckedChanged: {

					if (accordionColumn.itemData.id === fieldId) {
						// Update the data model
						accordionColumn.itemData.checked = checked;
            
						// Force RadioButton to update if it exists
						if (rad_button && rad_button.checked !== checked) {
							rad_button.checked = checked;
						}
            
						// Handle visibility of children if this is a radio button with children
						if (accordionColumn.itemData.children && Array.isArray(accordionColumn.itemData.children)) {
							
							accordionColumn.itemData.expanded = checked
							for (var i = 0; i < accordionColumn.itemData.children.length; i++) {
								accordionColumn.itemData.children[i].visible = checked;

							}
							accordionColumn.itemData = updateCloudProviderVisibility(accordionColumn.itemData)
							accordionColumn.itemData = updateEnabledStatus(accordionColumn.itemData)
						}
					}
				}
			}

			// Recursively finds the field with fieldId under itemData, replaces its
			// drop-down options and selection, and refreshes the combo box model/index.
			// Returns true once the field is found (stops the recursion).
			function updateFieldOptions(itemData, fieldId, newOptions, selected) {
				if (!itemData) return false;

				// --- Match found ---
				if (itemData.id === fieldId) {
					itemData.selected = selected;
					itemData.children_drop = newOptions;

					if (comboBox_id) {
						comboBox_id.model = newOptions.map(opt => opt.label1);

						if (selected) {
							let index = newOptions.findIndex(opt => opt.label1 === selected);
							if (index >= 0) {
								comboBox_id.currentIndex = index;
								//comboBox_id.selected = selected
							} else {
								comboBox_id.currentIndex = 0;
							}
						} else if (newOptions.length > 0) {
							comboBox_id.currentIndex = 0;
						}
					}
					return true; // stop recursion
				}

				// --- Recursively search children ---
				if (itemData.children && Array.isArray(itemData.children)) {
					for (let child of itemData.children) {
						if (updateFieldOptions(child, fieldId, newOptions, selected)) {
							return true;
						}
					}
				}

				return false;
			}


			// Recursively finds the field with fieldId under item and sets its selected
			// value. For "STA_IPMode", enables the static IP/Subnet/Gateway/DNS siblings
			// only when the mode is STATIC (clearing them otherwise). Returns true if found.
			function updateAccordionField(item, fieldId, newValue) {
				if (!item) return;

				if (item.id === fieldId) {
					item.selected = newValue
					  if (fieldId === "STA_IPMode") {
						const isStatic = newValue.toUpperCase() === "STATIC";

						// Find parent that contains siblings
						const parentAccordion = accordionColumn.itemData;

						if (parentAccordion && Array.isArray(parentAccordion.children)) {
							const idsToEnable = ["STA_IPAddress", "STA_Subnet", "STA_Gateway", "STA_DNS"];

							for (const sibling of parentAccordion.children) {
								if (idsToEnable.includes(sibling.id)) {
									sibling.enabled = isStatic;
									if (!isStatic) {
										sibling.text = ""; 
									}
								}
							}
						}
					}
					return true;  // stop recursion
				}

				if (item.children && Array.isArray(item.children)) {
					for (let child of item.children) {
						if (updateAccordionField(child, fieldId, newValue)) return true;
					}
				}
				return false;
			}



            Item{
                id: infoRow
				// Slider rows are taller: value above the handle, min/max under the track
				height: accordionColumn.itemData.value === "slider" ? Math.max(0.052 * screenHeight, sliderRow.height) : 0.052 * screenHeight
                width: parent.width
				enabled: accordionColumn.itemEnabled
							 ? ( (accordionColumn.itemData.id === 'vidRecording' || accordionColumn.itemData.id === "vidRecBtn") ? true : !isOnvifRecording)
							 : false
                visible: accordionColumn.itemData && accordionColumn.itemData.visible !== undefined ? accordionColumn.itemData.visible : false
                property bool expanded: accordionColumn.itemData.expanded ? accordionColumn.itemData.expanded : false
			
				MouseArea {
					id: mouse_id
					objectName: "mouse_id"
					anchors.fill: parent
					
					onClicked: {
						if (modelData.value === "radioButton") {
							if (accordionColumn.itemEnabled && !isOnvifRecording && !rad_button.checked) {
								rad_button.checked = true
								rad_button.clicked()
							}
						} else {
							infoRow.expanded = !infoRow.expanded;
							if (infoRow.expanded == true && modelData.children) {
								logController.expandedItem(modelData.id)
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
					x: (modelData.id == "hmacMode" || modelData.id == "saMode") ? 15: 0
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
                    anchors.left: carot.visible ? carot.right : parent.left
					anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    font.pixelSize: menuFontSize
					color: !accordionColumn.itemEnabled
						   ? "#808080"
						   : (accordionColumn.itemData.id !== 'vidRecording' && isOnvifRecording)
							 ? "#bdb3b3"
							 : "#ffffff"
                    text: accordionColumn.itemData.label ? accordionColumn.itemData.label : ""	
                }
				
				//radioButton
				Item {
					id: radio_item
					visible: accordionColumn.itemData.value === 'radioButton'
					enabled: accordionColumn.itemEnabled && !isOnvifRecording
					opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3

					Row {
						x: infoRow.x - 30
						height: 0.052 * screenHeight
						spacing: 10

						RadioButton {
							id: rad_button
							objectName: "rad_button"
							anchors.verticalCenter: parent.verticalCenter
							scale: 0.60
							checked: accordionColumn.itemData.checked ? accordionColumn.itemData.checked : false

							indicator: Rectangle {
								implicitWidth: 26
								implicitHeight: 26
								radius: 13
								x: rad_button.leftPadding
								y: parent.height / 2 - height / 2
								border.color: rad_button.checked ? "#2087cc" : "#888888"
								border.width: 2
								color: rad_button.checked ? "#2087cc" : "#ffffff"

								Rectangle {
									anchors.centerIn: parent
									width: 10
									height: 10
									radius: 5
									color: "#ffffff"
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

								if (typeof accordionColumn.itemData.onChange === "string" && typeof window[accordionColumn.itemData.onChange] === "function") {
									window[accordionColumn.itemData.onChange](accordionColumn.itemData.id);
								}

								if (Array.isArray(accordionColumn.itemData.children)) {
									for (let i = 0; i < accordionColumn.itemData.children.length; i++) {
										let child = accordionColumn.itemData.children[i];
										child.visible = rad_button.checked;
									}
								}
								radioButtonChanged(accordionColumn.itemData.identification, accordionColumn.itemData.label, true)
							}

							MouseArea {
								id: radioBtnMouseArea
								anchors.fill: parent
								hoverEnabled: true
								acceptedButtons: Qt.NoButton

								ToolTip {
									id: radioBtnTooltip
									width: 500
									visible: radioBtnMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
									delay: 1000
									background: Rectangle {
										color: window.titleBarColor
										border.color: window.titleBarColor
										border.width: 1
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

				Item {
					id: drop_item
					visible: (accordionColumn.itemData.value === 'dropBox') && 
							(accordionColumn.itemData.visible !== undefined ? accordionColumn.itemData.visible : true)
					enabled: accordionColumn.itemEnabled && !isOnvifRecording
					opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3
					anchors.left: parent.left
					anchors.leftMargin: xPosValue
					anchors.top: parent.top    
					anchors.topMargin: 10         // And this to move it down

					Connections {
						target: accordionColumn
						onItemDataChanged: {
							if (modelData.selected) {
								comboBox_id.currentIndex = drop_item.getInitialIndex();
							}
						}
					}
			
					// Returns the index of the drop-down entry whose label1 matches
					// modelData.selected, or 0 if there is no selection or no match.
					function getInitialIndex() {
						if (!modelData.selected || !Array.isArray(modelData.children_drop))
							return 0;
						for (var i = 0; i < modelData.children_drop.length; ++i) {
							if (modelData.children_drop[i].label1 === modelData.selected){
								return i;
							}
						}
						return 0;
					}

					Row {
						
						spacing: 15
				
						ComboBox {
							id: comboBox_id
							objectName: "comboBox_id"
                        	enabled: accordionColumn.itemEnabled && !isOnvifRecording ? accordionColumn.itemEnabled : false
							width: textFieldWidth
							height : menuItemHeight

							model: Array.isArray(accordionColumn.itemData.children_drop)
                            ? accordionColumn.itemData.children_drop.map(function(child) { return child.label1; })
                            : []

							 currentIndex: {
									if (!modelData.selected || !Array.isArray(modelData.children_drop))
										return 0;
									for (var i = 0; i < modelData.children_drop.length; ++i) {
										if (modelData.children_drop[i].label1 === modelData.selected) {
											return i;
										}
									}
									return 0;
								}

							 indicator: Item {
								width: 14  // Reduce width
								height: 16 // Reduce height
								anchors.right: parent.right
								anchors.rightMargin : 5
								anchors.verticalCenter: parent.verticalCenter

								// Use a simple triangle or image as indicator
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
										ctx.fillStyle = "#000000";
										ctx.fill();
									}
								}
							}

							 //  Customize the dropdown items
    						delegate: ItemDelegate {
        						width: comboBox_id.width
								height : comboBox_id.height
        						contentItem: Text {
            						text: modelData
									verticalAlignment: Text.AlignVCenter
									//horizontalAlignment: Text.AlignHCenter
            						font.pixelSize: 12
            						color: "black"
        						}
        						background: Rectangle {
            						color: hovered ? "#2087cc" : "white"
            						//border.color: "lightgray"
            						radius: 4
        						}
    						}

							MouseArea {
								id: dropDownMouseArea
								anchors.fill: parent
								hoverEnabled: true
								acceptedButtons: Qt.NoButton

								ToolTip {
									id: dropDownTooltip
									//width: 500
									width: Math.min(dropdownTextItem.implicitWidth + 20, 500) 
									visible: dropDownMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
									delay: 200  // optional: show after delay
									background: Rectangle {
										color: window.titleBarColor
										border.color: window.titleBarColor
										border.width: 1
										implicitHeight: dropdownTextItem.paintedHeight
									}
									contentItem: Text {
										id: dropdownTextItem
										color: "white"
										font.pixelSize: baseFontSize + 1
										wrapMode: Text.WordWrap
										text: modelData.tooltip ? modelData.tooltip : ""
									}
								}
							}

							background: Rectangle {
								implicitWidth: textFieldWidth
								implicitHeight: menuItemHeight
								radius: 6					
								color: accordionColumn.itemEnabled && !isOnvifRecording ? "white" : "#D3D3D3"
								border.width: 1
								border.color: accordionColumn.itemEnabled && !isOnvifRecording ? "#000000" : "#808080"
							}

							contentItem: Text {
								text: comboBox_id.displayText

								font.family: "Arial"
								font.pixelSize: baseFontSize
								font.bold: false
								verticalAlignment: Text.AlignVCenter
								//horizontalAlignment: Text.AlignHCenter
								elide: Text.ElideRight
                            	color: accordionColumn.itemEnabled && !isOnvifRecording ? "black" : "#808080"
								leftPadding: 8
								rightPadding: 8
							}


							onActivated: {
								accordionColumn.itemData.selected = comboBox_id.currentText;
								handleDropBoxValChanged(modelData.label, modelData.id, comboBox_id.currentText);
							}
						}
					}
				}

				//Slider
				Item {
					id: slider_item
					visible: accordionColumn.itemData.value === "slider"
					enabled: accordionColumn.itemEnabled && !isOnvifRecording
					opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3

					Item {
						id: sliderRow
						anchors.left: parent.left
						anchors.leftMargin: sliderLeftMargin;
						// Fixed-width track; value above the handle, min/max under the track ends
						width: sliderControl.width
						height: sliderValueLabel.height + 2 + sliderControl.height + 2 + sliderMinLabel.height


						Text {
							id: sliderMinLabel
							text: sliderControl.from
							color: "white"
							font.pixelSize: menuFontSize
							anchors.top: sliderControl.bottom
							anchors.topMargin: 2
							anchors.left: sliderControl.left
						}
						Slider {
							id: sliderControl
							objectName: "sliderControl"
							y: sliderValueLabel.height + 2
							enabled: accordionColumn.itemEnabled && !isOnvifRecording
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

							MouseArea {
								id: sliderMouseArea
								anchors.fill: parent
								hoverEnabled: true
								acceptedButtons: Qt.NoButton

								ToolTip {
									id: sliderTooltip
									visible: sliderMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
									delay: 200  // optional: show after delay
									background: Rectangle {
										color: window.titleBarColor
										border.color: window.titleBarColor
										border.width: 1
										implicitWidth: sliderTextItem.paintedWidth + 16 < 500 ? sliderTextItem.paintedWidth + 16 : 500
										implicitHeight: sliderTextItem.paintedHeight
									}
									contentItem: Text {
										id: sliderTextItem
										color: "white"
										font.pixelSize: baseFontSize + 1
										wrapMode: Text.WordWrap
										text: modelData.tooltip ? modelData.tooltip : ""
									}
								}
							}
							

								background: Rectangle {
										x: sliderControl.leftPadding
										anchors.verticalCenter: parent.verticalCenter
									//y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2 + 10
									implicitWidth: tabBarWidth
									implicitHeight: sliderHeight
									width: sliderControl.availableWidth
									height: implicitHeight
									radius: 2
                            		color: accordionColumn.itemEnabled && !isOnvifRecording ? "#bdbebf" : "#D3D3D3"

										Rectangle {
											id: progressBar
											width: sliderControl.visualPosition * parent.width
											height: parent.height
                                		color: accordionColumn.itemEnabled && !isOnvifRecording ? "#2087cc" : "#808080"
										radius: 2
									// visible: modelData.isVisible //? modelData.isEnabled : false//&& !checkBox.checked
									}
								}
									handle: Rectangle {
										id: sliderHandle
										x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width)
									anchors.verticalCenter: parent.verticalCenter
									//y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2 + 10
									implicitWidth: expandedStateIconH
									implicitHeight: expandedStateIconW
									radius: checkBoxFontSize
                            		color: accordionColumn.itemEnabled && !isOnvifRecording ? "#f0f0f0" : "#808080"
										border.color: "#bdbebf"
									}

									// Re-binds the handle position and progress bar width to visualPosition. Plain
									// assignments here would break the declarative bindings, leaving the handle frozen
									// on later drags while the value (and its label) keeps changing.
									function forceUpdateVisuals() {
										sliderHandle.x = Qt.binding(function() {
											return sliderControl.leftPadding +
												   sliderControl.visualPosition * (sliderControl.availableWidth - sliderHandle.width);
										});
										progressBar.width = Qt.binding(function() {
											return sliderControl.visualPosition * progressBar.parent.width;
										});
									}

									MouseArea {
									anchors.fill: parent
									hoverEnabled: true
									acceptedButtons: Qt.NoButton

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

								onValueChanged: {
									if (pressed && accordionColumn.itemEnabled) {
										accordionColumn.itemData.currentValue = value;
										handleSliderValChanged(accordionColumn.itemData.label, accordionColumn.itemData.id, value);
									}
								}
						
						}
						Text {
							id: sliderMaxLabel
							text: sliderControl.to
							color: "white"
							font.pixelSize: menuFontSize
							anchors.top: sliderControl.bottom
							anchors.topMargin: 2
							anchors.right: sliderControl.right
						}
						Text {
							id: sliderValueLabel
							text: sliderControl.value
							color: "white"
							font.pixelSize: menuFontSize
							// Centred over the handle, kept within the track
							y: 0
							x: Math.max(0, Math.min(sliderControl.width - width, sliderControl.x + sliderControl.handle.x + sliderControl.handle.width / 2 - width / 2))
						}
					}
				}

				//textbox
				Item {
					id: textBox_item
					enabled: accordionColumn.itemEnabled && !isOnvifRecording ? accordionColumn.itemEnabled : false
					//opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
					visible: {
						if (accordionColumn.itemData.value !== 'textBox') return false;
        
						var ownVisible = (accordionColumn.itemData.visible !== undefined ? accordionColumn.itemData.visible : true);
        
						return ownVisible;
					}
					//visible: accordionColumn.itemData.value === 'textBox' && accordionColumn.itemData.visible ? accordionColumn.itemData.visible : false

					Text {
						id: label
						anchors.left: parent.left
						anchors.leftMargin: txtBoxLeftMargin 
						anchors.top: parent.top
						anchors.topMargin: 10 // Moves the label slightly downward
					}

					TextField {
						id: textField_id
						objectName: "textField_id"
						width: textFieldWidth
						height : menuItemHeight
						anchors.left: label.right
						//anchors.leftMargin: 0
						anchors.top: parent.top
						anchors.topMargin: 12
						text: (accordionColumn.itemData.text != undefined || accordionColumn.itemData.text != null) ? accordionColumn.itemData.text : ""
						color: "black"
						font.family: "Arial"
						font.pixelSize: textFieldFontSize
						font.bold: false

						property bool showPassword: false  // Internal toggle state

						echoMode: (modelData.id == "AP_Password" || modelData.id == "STA_Password") 
								? (showPassword ? TextField.Normal : TextField.Password)
								: TextField.Normal

						// Toggle eye icon visible only for password fields
						Item {
							anchors.right: parent.right
							anchors.verticalCenter: parent.verticalCenter
							width: 20
							height: 20
							visible: modelData.id == "AP_Password" || modelData.id == "STA_Password"

							MouseArea {
								id: eyeMouseArea
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									textField_id.showPassword = !textField_id.showPassword;
								}

								Image {
									anchors.centerIn: parent
									source: textField_id.showPassword ? "qrc:View/icons/passwordShowing.svg" : "qrc:View/icons/passwordHiding.svg"
									width: 16
									height: 16
								}
							}
						}

						background: Rectangle {
							color: accordionColumn.itemEnabled && !isOnvifRecording? "white" : "#cccccc"
							radius: 4
							border.color: "white"
						}

						onTextChanged: {
							accordionColumn.itemData.text = textField_id.text;
							handleTextBoxValChanged(accordionColumn.itemData.label, accordionColumn.itemData.id, accordionColumn.itemData.text);
						}

						MouseArea {
							id: textFieldMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							ToolTip {
								id: textCustomTooltip
								visible: textFieldMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
								delay: 200
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									implicitWidth: textItem.paintedWidth + 16 < 500 ? textItem.paintedWidth + 16 : 500
									implicitHeight: textItem.paintedHeight
								}
								contentItem: Text {
									id: textItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}
						}
					}
				}

				Item {
					id: label_item
					visible: accordionColumn.itemData.value === 'label'
					enabled: accordionColumn.itemEnabled && !isOnvifRecording
					opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3
					width: parent.width
					height: 0.052 * screenHeight

					Text {
						id: textData
						anchors.left: parent.left
						anchors.leftMargin: xPosValue
						anchors.verticalCenter: parent.verticalCenter
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


				//Duration text box

				Item {
					id: timetextBox_item
					visible: accordionColumn.itemData.value === 'TimetextBox'
					enabled: accordionColumn.itemEnabled && !isOnvifRecording
					opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3

					Row {
						anchors.left: parent.left
						anchors.leftMargin: leftMarginAlign // Adjust position
						anchors.top: parent.top
						anchors.topMargin: 10 // Moves the row slightly downward
						spacing: 10 // Space between elements

						Text {
							id: durationLabel
							//   text: "Duration"
						}

						TextField {
							id: hourText
							objectName: "hourText"
							width:  txtFieldW
							height: txtFieldH
							text: modelData.hour ? modelData.hour : ""
							color: "black"  // Sets the text color to black
							font.family: "Arial"
							font.pixelSize: textFieldFontSize
							font.bold: false
							background: Rectangle { color: "white"; radius: 4; border.color: "gray" }
							MouseArea {
								id: durationHrMouseArea
								anchors.fill: parent
								hoverEnabled: true
								acceptedButtons: Qt.NoButton

								ToolTip {
									id: durationHrcustomTooltip
									visible: durationHrMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
									delay: 200  // optional: show after delay
									background: Rectangle {
										color: window.titleBarColor
										border.color: window.titleBarColor
										border.width: 1
										implicitWidth: durationHrItem.paintedWidth + 16 < 500 ? durationHrItem.paintedWidth + 16 : 500
										implicitHeight: durationHrItem.paintedHeight
									}
									contentItem: Text {
										id: durationHrItem
										color: "white"
										font.pixelSize: baseFontSize + 1
										wrapMode: Text.WordWrap
										text: modelData.tooltip ? modelData.tooltip : ""
									}
								}
							}
							onTextChanged: {
								handleDurationValChanged(modelData.label,  hourText.text, "hour")
							}
						}		

						TextField {
							id: minText
							objectName: "minText"
							width:  txtFieldW
							height: txtFieldH
							text: modelData.min ? modelData.min : ""
							color: "black"  // Sets the text color to black
							font.family: "Arial"
							font.pixelSize: textFieldFontSize
							font.bold: false
							background: Rectangle { color: "white"; radius: 4; border.color: "gray" }
							MouseArea {
								id: durationMinMouseArea
								anchors.fill: parent
								hoverEnabled: true
								acceptedButtons: Qt.NoButton

								ToolTip {
									id: durationMinCustomTooltip
									visible: durationMinMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
									delay: 200  // optional: show after delay
									background: Rectangle {
										color: window.titleBarColor
										border.color: window.titleBarColor
										border.width: 1
										implicitWidth: durationMinTextItem.paintedWidth + 16 < 500 ? durationMinTextItem.paintedWidth + 16 : 500
										implicitHeight: durationMinTextItem.paintedHeight
									}
									contentItem: Text {
										id: durationMinTextItem
										color: "white"
										font.pixelSize: baseFontSize + 1
										wrapMode: Text.WordWrap
										text: modelData.tooltip ? modelData.tooltip : ""
									}
								}
							}
							onTextChanged: {
								modelData.min = minText.text;
								handleDurationValChanged(modelData.label,  minText.text, "min")
							}
						}


						TextField {
							id: secText
							objectName: "secText"
							width:  txtFieldW
							height: txtFieldH
							text: modelData.sec ? modelData.sec : ""
							color: "black"  // Sets the text color to black
							font.family: "Arial"
							font.pixelSize: textFieldFontSize
							font.bold: false
							background: Rectangle { color: "white"; radius: 4; border.color: "gray" }
							MouseArea {
								id: durationSecMouseArea
								anchors.fill: parent
								hoverEnabled: true
								acceptedButtons: Qt.NoButton

								ToolTip {
									id: durationSecCustomTooltip
									visible: durationSecMouseArea.containsMouse && modelData.tooltip !== undefined &&  modelData.tooltip
									delay: 200  // optional: show after delay
									background: Rectangle {
										color: window.titleBarColor
										border.color: window.titleBarColor
										border.width: 1
										implicitWidth: durationSecTextItem.paintedWidth + 16 < 500 ? durationSecTextItem.paintedWidth + 16 : 500
										implicitHeight: durationSecTextItem.paintedHeight
									}
									contentItem: Text {
										id: durationSecTextItem
										color: "white"
										font.pixelSize: baseFontSize + 1
										wrapMode: Text.WordWrap
										text: modelData.tooltip ? modelData.tooltip : ""
									}
								}
							}
							onTextChanged: {
								modelData.sec = secText.text;
								handleDurationValChanged(modelData.label,  secText.text, "sec")
							}

						}
					}
				}

				//button
				Item
				{		
					enabled: accordionColumn.itemEnabled
							 ? (accordionColumn.itemData.id === 'vidRecBtn' ? true : !isOnvifRecording)
							 : false

					opacity: accordionColumn.itemEnabled
							 ? (accordionColumn.itemData.id === 'vidRecBtn' ? 1.0 : (isOnvifRecording ? 0.3 : 1.0))
							 : 0.3
					visible: accordionColumn.itemData.value === 'button' && accordionColumn.itemData.visible ? accordionColumn.itemData.visible : false			

					Button 
					{
						id:buttonid
						objectName: "buttonid"
						x:  modelData.id == "file" || modelData.id == "storageKey_sharedKey" || modelData.id == "storageKey_sas"?   parent.x+ (xPosValue) :  parent.x+ (xPositionVal)
						y: modelData.id == "file" || modelData.id == "storageKey_sharedKey" || modelData.id == "storageKey_sas"? 10 : parent.y + 10
						width:  modelData.id == "file" || modelData.id == "storageKey_sharedKey" || modelData.id == "storageKey_sas" ? buttonW1 : buttonW2
						height: modelData.id == "file" || modelData.id == "storageKey_sharedKey" || modelData.id == "storageKey_sas" ? txtFieldH	: buttonHeight				
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
								visible: mouseArea.containsMouse && modelData.tooltip !== undefined &&  modelData.tooltip
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

							// Add Image on the left
							Image {
								id: icon
								visible: modelData.id == "downloadSharedKeyConfig" ||
										 modelData.id == "downloadSasKeyConfig"
								source: "qrc:View/icons/download.svg"
								width: 20
								height: 20
								fillMode: Image.PreserveAspectFit
								Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
								Layout.preferredWidth: 20
								Layout.preferredHeight: 20
								Layout.minimumWidth: 20
							}

							Image {
								id: snaposhtIcon
								visible: modelData.id == "snapShotBtn"
								source: "qrc:View/icons/stillCaptureOnHover.svg"
								width: 20
								height: 20
								fillMode: Image.PreserveAspectFit
								Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
								Layout.preferredWidth: 20
								Layout.preferredHeight: 20
								Layout.minimumWidth: 20
							}

							Image {
								id: recordIcon
								visible: modelData.id == "vidRecBtn"
								source: window.isOnvifRecording?  "qrc:View/icons/recordStopOnHover.svg": "qrc:View/icons/recordStartOnHover.svg"
								width: 20
								height: 20
								fillMode: Image.PreserveAspectFit
								Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
								Layout.preferredWidth: 20
								Layout.preferredHeight: 20
								Layout.minimumWidth: 20
							}

							Image {
								id: restartIcon
								visible: modelData.id == "rebootBtn"
								source: "qrc:View/icons/restart.svg"
								width: 20
								height: 20
								fillMode: Image.PreserveAspectFit
								Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
								Layout.preferredWidth: 20
								Layout.preferredHeight: 20
								Layout.minimumWidth: 20
							}

							Image {
								id: powerOffIcon
								visible: modelData.id == "powerOffBtn"
								source: "qrc:View/icons/powerOff.svg"
								width: 20
								height: 20
								fillMode: Image.PreserveAspectFit
								Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
								Layout.preferredWidth: 20
								Layout.preferredHeight: 20
								Layout.minimumWidth: 20
							}
							
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
								if (modelData.name === "Reboot Device") {
									wifiOnvifController.reboot();
								} else if(modelData.id === "powerOffBtn"){
									wifiOnvifController.powerOff();
								} else if (modelData.id === "updateApConfig") {
									setAPConfigData();
								}else if (modelData.id === "updateStaConfig") {
									setSTAConfigData();
								} 
								else if (modelData.id === "updateLocalConfig") {
									setLocalServerData();
								}
								else if (modelData.id === "updateSAConfig" || modelData.id === "updateHMACConfig" || modelData.id === "updateCloudConfig" || modelData.id === "updateSASConfig" || modelData.id === "updateSharedKeyConfig") {
									setCloudServer();
								}
								else if (modelData.id === "updateTimerConfig") {
									setTimerData();
								}
								else if (modelData.id === "snapShotBtn") {
									wifiOnvifController.snapshotWorker()
								} else if(modelData.id === "vidRecBtn"){
									if(isOnvifRecording){
										if(wifiOnvifController.stopRecording() == 1){
											window.isOnvifRecording = false
											window.stopVideoRecording()
										}
									} else {
										if( wifiOnvifController.startRecording() == 1){
											window.isOnvifRecording = true
											window.startVideoRecording(true)
										}
									}
								}
								else if(modelData.id === "updateCamConfig"){
									setCameraConfig();
								} else if(modelData.id === "storageKey_sas"){
									//isSAS = true
									fileDialog.open()
								} else if(modelData.id === "storageKey_sharedKey"){
									//isSAS = false
									fileDialog.open()
								} else if(modelData.id === "downloadSharedKeyConfig"){
									downloadSharedKeyFile()
								} else if(modelData.id === "downloadSasKeyConfig"){
									downloadSasKeyFile()
								} 
								else if(modelData.name == "Upload file"){
									fileDialog.open()
								} else if (modelData.id == "setDefaultResolution"){
									wifiOnvifController.setDefaultResolution()
								} else if (modelData.id == "updateVidRecTimerConfig"){
									setVidRecTimerConfig();
								} else if (modelData.id == "ejectSDCardBtn"){
									wifiOnvifController.ejectSDCard()
								} else if(modelData.id == "setCameraConfigDefault"){
									wifiOnvifController.setCameraConfigDefault()
								} else if(modelData.id == "readBatteryStatusBtn"){
									readBatteryStatus()
								}
							}
					}   	
				}

			}

			// Pan Picker
			Item {
				id: panPicker
				visible: accordionColumn.itemData.value === 'Pan' && (accordionColumn.itemData.visible !== undefined ? accordionColumn.itemData.visible : true)
				enabled: accordionColumn.itemEnabled  && !isOnvifRecording
				opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3

				Row {
					//spacing: 16
					anchors.left: parent.left
					anchors.leftMargin: leftMarginAlign
					anchors.top: parent.top
					anchors.topMargin: 10

					SpinBox {
						id: panSpinBox
						objectName: "panSpinBox"
						from: -1
						to: 1
						value: modelData && modelData.pan !== undefined ? modelData.pan : 0
						stepSize: 1
						width: txtFieldW
						height: txtFieldH

						// Track boundary state
						property bool leftDisabled: false
						property bool rightDisabled: false

						background: Rectangle {
							color: "white"
							border.color: "#cccccc"
							radius: 4
						}

						contentItem: Item {}

						down.indicator: Rectangle {
							implicitWidth: parent.width / 2
							implicitHeight: parent.height
							color: panSpinBox.leftDisabled ? "#a0a0a0" : "#2087cc"
							border.color: "#cccccc"
							radius: 3
							anchors.left: parent.left

							Text {
								anchors.centerIn: parent
								text: "<"
								font.pixelSize: textFieldFontSize
								color: "white"
							}

							MouseArea {
								anchors.fill: parent
								enabled: !panSpinBox.leftDisabled
								onClicked: {
									var result = wifiOnvifController.setPan(-1)
									if (!result.success) {
										setTextMessage(result.message)
									} 
								}
							}
						}

						up.indicator: Rectangle {
							implicitWidth: parent.width / 2
							implicitHeight: parent.height
							color: panSpinBox.rightDisabled ? "#a0a0a0" : "#2087cc"
							border.color: "#cccccc"
							radius: 3
							anchors.right: parent.right

							Text {
								anchors.centerIn: parent
								text: ">"
								font.pixelSize: textFieldFontSize
								color: "white"
							}

							MouseArea {
								anchors.fill: parent
								enabled: !panSpinBox.rightDisabled
								onClicked: {
									var result = wifiOnvifController.setPan(1)
									if (!result.success) {
										setTextMessage(result.message)
									} 
								}
							}
						}

						// Disable default SpinBox behavior — we handle clicks manually
						onValueChanged: {}
					}
				}
			}

			// Tilt Picker
			Item {
				id: tiltPicker
				visible: accordionColumn.itemData.value === 'Tilt' && (accordionColumn.itemData.visible !== undefined ? accordionColumn.itemData.visible : true)
				enabled: accordionColumn.itemEnabled && !isOnvifRecording
				opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3

				Row {
					spacing: 16
					anchors.left: parent.left
					anchors.leftMargin: leftMarginAlign
					anchors.top: parent.top
					anchors.topMargin: 10

					SpinBox {
						id: tiltSpinBox
						objectName: "tiltSpinBox"
						from: -1
						to: 1
						value: modelData && modelData.tilt !== undefined ? modelData.tilt : 0
						stepSize: 1
						width: txtFieldW
						height: txtFieldH

						// Track boundary state
						property bool upDisabled: false
						property bool downDisabled: false

						background: Rectangle {
							color: "white"
							border.color: "#cccccc"
							radius: 4
						}

						contentItem: Item {}

						up.indicator: Rectangle {
							implicitWidth: parent.width
							implicitHeight: parent.height / 2
							color: tiltSpinBox.upDisabled ? "#a0a0a0" : "#2087cc"
							border.color: "#cccccc"
							radius: 3
							anchors.top: parent.top

							Text {
								anchors.centerIn: parent
								text: "^"
								font.pixelSize: textFieldFontSize
								color: "white"
							}

							MouseArea {
								anchors.fill: parent
								enabled: !tiltSpinBox.upDisabled
								onClicked: {
									var result = wifiOnvifController.setTilt(1)
									if (!result.success) {
										setTextMessage(result.message)
									} 
								}
							}
						}

						down.indicator: Rectangle {
							implicitWidth: parent.width
							implicitHeight: parent.height / 2
							color: tiltSpinBox.downDisabled ? "#a0a0a0" : "#2087cc"
							border.color: "#cccccc"
							radius: 3
							anchors.bottom: parent.bottom

							Text {
								anchors.centerIn: parent
								text: "v"
								font.pixelSize: textFieldFontSize
								color: "white"
							}

							MouseArea {
								anchors.fill: parent
								enabled: !tiltSpinBox.downDisabled
								onClicked: {
									var result = wifiOnvifController.setTilt(-1)
									if (!result.success) {
										setTextMessage(result.message)
									} 
								}
							}
						}

						onValueChanged: {}
					}
				}
			}

			// Start Time picker
			Item {
				id: startTimePicker
				visible: accordionColumn.itemData.value === 'Start Time'
				enabled: accordionColumn.itemEnabled && !isOnvifRecording
				opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3

				Row {
					spacing: 10
					anchors.left: parent.left
					anchors.leftMargin: leftMarginAlign
					
					anchors.top: parent.top
					anchors.topMargin: 10 // Moves the row slightly downward

					SpinBox {
						id: startHoursSpinBox
						objectName: "startHoursSpinBox"
						from: 0
						to: 23
						value: modelData && modelData.startHour !== undefined ? modelData.startHour : 0
						stepSize: 1
						width:  txtFieldW
						height: txtFieldH

						background: Rectangle {
							color: "white"
							border.color: "#cccccc"
							radius: 4
						}

						contentItem: Text {
							text: startHoursSpinBox.textFromValue(startHoursSpinBox.value)
							color: "black"
							font.pixelSize: textFieldFontSize
							anchors.left: parent.left
							anchors.leftMargin : 8
							verticalAlignment: Text.AlignVCenter
							anchors.fill: parent
						}

						up.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight: parent.height /2
							radius: 3

							color: "#2087cc"
							border.color: "#cccccc"
							anchors.right : parent.right
							anchors.top : parent.top
							Text {
								anchors.centerIn: parent
								text: "+"
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						down.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							anchors.right: parent.right
							anchors.bottom : parent.bottom
							border.color: "#cccccc"
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "-"						
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						MouseArea {
							id: startHrMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							ToolTip {
								id: startHrCustomTooltip
								visible: startHrMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
								delay: 200  // optional: show after delay
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									implicitHeight: startHrItem.paintedHeight
								}
								contentItem: Text {
									id: startHrItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}
						}

						onValueChanged: {		
							if (modelData) {
								modelData.startHour = value;
								handleSpinBoxValChanged(modelData.value, value,"startHour");
							} 
						}
					}
    
					SpinBox {
						id: startMinsSpinBox
						objectName: "startMinsSpinBox"
						from: 0
						to: 59
						value: modelData && modelData.startMin !== undefined ? modelData.startMin : 0
						stepSize: 1
						width:  txtFieldW
						height: txtFieldH

						background: Rectangle {
							color: "white"
							border.color: "#cccccc"
							radius: 4
						}

						contentItem: Text {
							text: startMinsSpinBox.textFromValue(startMinsSpinBox.value)
							color: "black"
							font.pixelSize: textFieldFontSize
							anchors.left: parent.left
							anchors.leftMargin : 8
							verticalAlignment: Text.AlignVCenter
							anchors.fill: parent
						}

						up.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							border.color: "#cccccc"
							anchors.right : parent.right
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "+"								
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						down.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							anchors.right : parent.right
							anchors.bottom : parent.bottom
							border.color: "#cccccc"
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "-"
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						MouseArea {
							id: startMinMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							ToolTip {
								id: startMinCustomTooltip
								visible: startMinMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
								delay: 200  // optional: show after delay
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									implicitHeight: startMinItem.paintedHeight
								}
								contentItem: Text {
									id: startMinItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}
						}
        
						onValueChanged: {
							if (modelData) {
								modelData.startMin = value;
								handleSpinBoxValChanged(modelData.value, value, "startMin");
							} 
						}
					}
    
					SpinBox {
						id: startSecsSpinBox
						objectName: "startSecsSpinBox"
						from: 0
						to: 59
						value: modelData && modelData.startSec !== undefined ? modelData.startSec : 0
						stepSize: 1
						width:  txtFieldW
						height: txtFieldH

						background: Rectangle {
							color: "white"
							border.color: "#cccccc"
							radius: 4
						}

						contentItem: Text {
							text: startSecsSpinBox.textFromValue(startSecsSpinBox.value)
							color: "black"						
							font.pixelSize: textFieldFontSize
							anchors.left: parent.left
							anchors.leftMargin : 8
							verticalAlignment: Text.AlignVCenter
							anchors.fill: parent
						}

						up.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							border.color: "#cccccc"
							anchors.right : parent.right
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "+"						
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						down.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							anchors.right : parent.right
							anchors.bottom : parent.bottom
							border.color: "#cccccc"
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "-"								
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						MouseArea {
							id: startSecMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							ToolTip {
								id: startSecCustomTooltip
								visible: startSecMouseArea.containsMouse && modelData.tooltip !== undefined &&  modelData.tooltip
								delay: 200  // optional: show after delay
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									implicitHeight: startSecItem.paintedHeight
								}
								contentItem: Text {
									id: startSecItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}
						}
        
						onValueChanged: {
							if (modelData) {
								modelData.startSec = value;

								handleSpinBoxValChanged(modelData.value, value, "startSec");
							} 
						}
					}
				}
			}


			// End Time picker
			Item {
				id: endTimePicker
				
				visible: accordionColumn.itemData.value === 'End Time'
				enabled: accordionColumn.itemEnabled && !isOnvifRecording
				opacity: accordionColumn.itemEnabled && !isOnvifRecording ? 1.0 : 0.3

				Row {
					spacing: 10
					anchors.left: parent.left
					anchors.leftMargin: leftMarginAlign
					
					anchors.top: parent.top
					anchors.topMargin: 10 // Moves the row slightly downward
		
					SpinBox {
						id: endHoursSpinBox
						objectName: "endHoursSpinBox"
						from: 0
						to: 23
						value: modelData.endHour || 0
						stepSize: 1
						width:  txtFieldW
						height: txtFieldH

						background: Rectangle {
							color: "white"
							border.color: "#cccccc"
							radius: 4
						}

						contentItem: Text {
							text: endHoursSpinBox.textFromValue(endHoursSpinBox.value)
							color: "black"
							font.pixelSize: textFieldFontSize
							anchors.left: parent.left
							anchors.leftMargin : 8
							verticalAlignment: Text.AlignVCenter
							anchors.fill: parent
						}

						up.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							border.color: "#cccccc"
							anchors.right : parent.right
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "+"
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						down.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							anchors.right : parent.right
							anchors.bottom : parent.bottom
							border.color: "#cccccc"
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "-"
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						MouseArea {
							id: endHrMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							ToolTip {
								id: endHrCustomTooltip
								visible: endHrMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
								delay: 200  // optional: show after delay
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									implicitHeight: endHrItem.paintedHeight
								}
								contentItem: Text {
									id: endHrItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}
						}

						onValueChanged: {
							 modelData.endHour = value;
							 handleSpinBoxValChanged(modelData.value,value,"endHour");
						}
					}
					SpinBox {
						id: endMinsSpinBox
						objectName: "endMinsSpinBox"
						from: 0
						to: 59
						value: modelData.endMin || 0
						stepSize: 1
						width:  txtFieldW
						height: txtFieldH

						background: Rectangle {
							color: "white"
							border.color: "#cccccc"
							radius: 4
						}

						contentItem: Text {
							text: endMinsSpinBox.textFromValue(endMinsSpinBox.value)
							color: "black"
							font.pixelSize: textFieldFontSize
							anchors.left: parent.left
							anchors.leftMargin : 8
							verticalAlignment: Text.AlignVCenter
							anchors.fill: parent
						}

						up.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							border.color: "#cccccc"
							anchors.right : parent.right
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "+"
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						down.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							anchors.right : parent.right
							anchors.bottom : parent.bottom
							border.color: "#cccccc"
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "-"
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						MouseArea {
							id: endMinMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							ToolTip {
								id: endMinCustomeTooltip
								visible: endMinMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
								delay: 200  // optional: show after delay
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									implicitHeight: endMinItem.paintedHeight
								}
								contentItem: Text {
									id: endMinItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}
						}

						onValueChanged: {
							 modelData.endMin = value;
							 handleSpinBoxValChanged(modelData.value,value,"endMin");
						}
					}
					SpinBox {
						id: endSecsSpinBox
						objectName: "endSecsSpinBox"
						from: 0
						to: 59
						value: modelData.endSec || 0
						stepSize: 1
						width:  txtFieldW
						height: txtFieldH

						background: Rectangle {
							color: "white"
							border.color: "#cccccc"
							radius: 4
						}

						contentItem: Text {
							text: endSecsSpinBox.textFromValue(endSecsSpinBox.value)
							color: "black"
							font.pixelSize: textFieldFontSize
							anchors.left: parent.left
							anchors.leftMargin : 8
							verticalAlignment: Text.AlignVCenter
							anchors.fill: parent
						}

						up.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							border.color: "#cccccc"
							anchors.right : parent.right
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "+"
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						down.indicator: Rectangle {
							implicitWidth: parent.width/3
							implicitHeight:  parent.height/ 2
							color: "#2087cc"
							anchors.right : parent.right
							anchors.bottom : parent.bottom
							border.color: "#cccccc"
							radius: 3
							Text {
								anchors.centerIn: parent
								text: "-"
								font.pixelSize: textFieldFontSize
								color: "white"
							}
						}

						MouseArea {
							id: endSecMouseArea
							anchors.fill: parent
							hoverEnabled: true
							acceptedButtons: Qt.NoButton

							ToolTip {
								id: endSecCustomTooltip
								visible: endSecMouseArea.containsMouse && modelData.tooltip !== undefined && modelData.tooltip
								delay: 200  // optional: show after delay
								background: Rectangle {
									color: window.titleBarColor
									border.color: window.titleBarColor
									border.width: 1
									implicitHeight: endSecItem.paintedHeight
								}
								contentItem: Text {
									id: endSecItem
									color: "white"
									font.pixelSize: baseFontSize + 1
									wrapMode: Text.WordWrap
									text: modelData.tooltip ? modelData.tooltip : ""
								}
							}
						}

						onValueChanged: {
							 modelData.endSec = value;
							 handleSpinBoxValChanged(modelData.value,value,"endSec");
						}
					}
				}
			}   
			// Column+Repeater for handling recursive children (subitems)
			// NOTE: Using Repeater instead of ListView so all delegates are always
			// instantiated as proper QObject children (enables findChild() in tests
			// and avoids the height=0 lazy-instantiation chicken-and-egg problem).
			Column {
				id: subentryColumn
				x: 20
				width: parent.width - x
				opacity: infoRow.expanded ? 1 : 0
				visible: opacity > 0

				Repeater {
					id: subentryRepeater
					delegate: accordion
					model: (accordionColumn.itemData.children ? accordionColumn.itemData.children : [])
				}
			}
		}  
	}
}
