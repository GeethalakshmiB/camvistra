import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.14
import "../JS/Ethernet.js" as RoutecamModelData

Column 
{
    id:column_main
	x: routecamRect.x + 10

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
    	signal fieldOptionsChanged(string fieldId, var newOptions, var selected)
	signal fieldValueChanged(string fieldId, var newValue)
	signal fieldRangeChanged(string fieldId, var minimum, var maximum, var newValue)

	Component {
		id: buttonGroupComponent
		ButtonGroup {}
	}

	property int count:1 

    // Repeater to iterate over the model data
    Repeater {
        id: columnRepeater
        model: RoutecamModelData.getRoutecamModelData() // Get the data from JS
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

			// LISTEN TO TARGETED SIGNALS
            Connections {
                target: column_main
                
                // Handle enabled/disabled state changes
                onFieldChanged: {
                    if (accordionColumn.itemData.id === fieldId) {
                        accordionColumn.itemEnabled = enabled;
                    }
                }

				onFieldValueChanged: {

					if (accordionColumn.itemData.id === fieldId && 
						accordionColumn.itemData.value === "checkbox") {
						accordionColumn.itemData.currentValue = newValue;
						checkboxControl.checked = newValue;  // Use 'checked', not 'value'
						return;
					}
    
					// CHECK 1: Is THIS item a slider with matching ID?
					if (accordionColumn.itemData.id === fieldId && 
						accordionColumn.itemData.value === "slider") {        
						accordionColumn.itemData.currentValue = newValue;
						sliderControl.applyingBackendValue = true;
						sliderControl.value = newValue;
						sliderControl.forceUpdateVisuals();
						sliderControl.applyingBackendValue = false;
        				return; // Exit early
					}

					// CHECK 2: Is a child a slider with matching ID?
					if (accordionColumn.itemData.children && 
						accordionColumn.itemData.children.length > 0 &&
						accordionColumn.itemData.children[0].id === fieldId) {
                
						if (newValue !== null && newValue !== undefined) {
							accordionColumn.itemData.children[0].currentValue = newValue;
            
							if(accordionColumn.itemData.children[0].value == "slider"){
								sliderControl.applyingBackendValue = true;
								sliderControl.value = newValue;
								sliderControl.forceUpdateVisuals();
								sliderControl.applyingBackendValue = false;
							}
            
							// Force text binding to update
							if(accordionColumn.itemData.children[0].value == "slider" || 
							   accordionColumn.itemData.children[0].value == "dropBox"){			
								textItm.text = accordionColumn.itemData.label + " " + String(newValue);
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
               onFieldOptionsChanged: {
					if (accordionColumn.itemData.id === fieldId) {
						// Update the data model
						accordionColumn.itemData.children_drop = newOptions;
						// Force ComboBox model refresh
						if (comboBox_id) {
							comboBox_id.model = newOptions.map(function(child) { 
								return child.label1; 
							});
							// Now set selected value
							if (selected) {
								// Find index of the selected label in newOptions
								var index = newOptions.findIndex(function(opt) {
									return opt.label1 === selected;
								});
								if (index >= 0) {
									comboBox_id.currentIndex = index;
								} else {
									// Default to first option if not found
									comboBox_id.currentIndex = 0;
								}
							} else if (newOptions.length > 0) {
								// Default to first if selected not provided
								comboBox_id.currentIndex = 0;
							}
						}
					}
				}

				onFieldRangeChanged: {
					if (accordionColumn.itemData.id === fieldId &&
						accordionColumn.itemData.value === "slider") {
						accordionColumn.itemData.min = minimum;
						accordionColumn.itemData.max = maximum;
						accordionColumn.itemData.currentValue = newValue;
						sliderControl.applyingBackendValue = true;
						sliderControl.from = minimum;
						sliderControl.to = maximum;
						sliderControl.value = newValue;
						sliderControl.forceUpdateVisuals();
						sliderControl.applyingBackendValue = false;
					}
				}

            }

            Item{
                id: infoRow
				// Slider rows are taller: value above the handle, min/max under the track
				height: accordionColumn.itemData.value === "slider" ? Math.max(0.052 * screenHeight, sliderRow.height) : 0.052 * screenHeight
                width: parent.width
                enabled: accordionColumn.itemEnabled
                visible: accordionColumn.itemData.visible !== undefined ? accordionColumn.itemData.visible : false
                property bool expanded: accordionColumn.itemData.expanded ? accordionColumn.itemData.expanded : false
			
				MouseArea {
					id: mouse_id
					anchors.fill: parent
					
					onClicked: {
						if (modelData.value === "checkbox") {
							if (accordionColumn.itemEnabled) {
								checkboxControl.checked = !checkboxControl.checked
								checkboxControl.clicked()
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
                    anchors.left: carot.visible ? carot.right : parent.left
					anchors.verticalCenter: parent.verticalCenter
				    anchors.leftMargin: 12
                    font.pixelSize: menuFontSize
					color: accordionColumn.itemEnabled ? "#ffffff" : "#808080"  // Visual feedback
					text: {
						if (!accordionColumn.itemData.label) return ""
    
						var hasChildren = accordionColumn.itemData.children && accordionColumn.itemData.children.length > 0
						if (!hasChildren) return accordionColumn.itemData.label
    
						var currentVal = accordionColumn.itemData.children[0].currentValue
						var valueStr = (currentVal !== undefined && currentVal !== null) ? String(currentVal) : ""
    
						return accordionColumn.itemData.label + " " + valueStr
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
					anchors.leftMargin: (accordionColumn.itemData.id == "exposureTime" || accordionColumn.itemData.id == "min_exposure_s" 
									|| accordionColumn.itemData.id == "max_exposure_s" || accordionColumn.itemData.id == "gain_s" ||
									accordionColumn.itemData.id == "bGain" || accordionColumn.itemData.id == "rGain") ?
									sliderLeftMargin : -subentryIndent
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
						property bool initializationComplete: false
						property bool applyingBackendValue: false
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
    
						Component.onCompleted: initializationComplete = true

						onValueChanged: {
							if (initializationComplete && !applyingBackendValue &&
								accordionColumn.itemEnabled) {
								accordionColumn.itemData.currentValue = value;
								handleSliderValChanged(accordionColumn.itemData.label, accordionColumn.itemData.id, value);
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

			//Label
			Item {
					id: label_item
					visible: accordionColumn.itemData.value === 'label'
					enabled: accordionColumn.itemEnabled
					opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
					
					Text {
						id:textData
						anchors.left: parent.right
						anchors.leftMargin: textFieldWidth // Space between label and TextField
						anchors.verticalCenter : parent.verticalCenter
						anchors.top: parent.top
						anchors.topMargin: 12 // Moves the TextField down, aligned with the label
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
								delay: 200  // optional: show after delay
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

			// DROP BOX
			Item {
				id: drop_item
                visible: accordionColumn.itemData.value === 'dropBox'
                enabled: accordionColumn.itemEnabled
                opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
				anchors.left: parent.left
				anchors.leftMargin:  xPosValue
				anchors.top: parent.top    
				anchors.topMargin: 10         // And this to move it down
			
				// Returns the index of the drop-down entry whose label1 matches the item's
				// "selected" value, or 0 if there is no selection or no match.
				function getInitialIndex() {
                    if (!accordionColumn.itemData.selected || !Array.isArray(accordionColumn.itemData.children_drop))
                        return 0;
                    for (var i = 0; i < accordionColumn.itemData.children_drop.length; ++i) {
                        if (accordionColumn.itemData.children_drop[i].label1 === accordionColumn.itemData.selected) {
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
                        enabled: accordionColumn.itemEnabled ? accordionColumn.itemEnabled : false
						width: textFieldWidth
						height : menuItemHeight

						model: Array.isArray(accordionColumn.itemData.children_drop)
                            ? accordionColumn.itemData.children_drop.map(function(child) { return child.label1; })
                            : []

						currentIndex: drop_item.getInitialIndex()

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
									ctx.fillStyle = accordionColumn.itemEnabled ? "#000000" : "#808080";
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
								width: 500
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
							//horizontalAlignment: Text.AlignHCenter
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
				
				enabled: accordionColumn.itemEnabled ? accordionColumn.itemEnabled : false
				opacity: accordionColumn.itemEnabled ? 1.0 : 0.3
				visible: accordionColumn.itemData.value === 'textBox' && accordionColumn.itemData.visible ? accordionColumn.itemData.visible : false
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
					text: accordionColumn.itemData.text ? accordionColumn.itemData.text : ""
					color: "black"
					font.family: "Arial"
					font.pixelSize: textFieldFontSize
					font.bold: false
					
					background: Rectangle {
						color: accordionColumn.itemEnabled ? "white" : "#cccccc"
						radius: 4
						border.color: "white"
					}

					onTextChanged: {
						modelData.text = textField_id.text;
						handleTextBoxValChanged(modelData.label, modelData.id, textField_id.text);
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
						if (modelData.id === "updateNtp") {
							setNTPIp();
						}else if (modelData.id === "updateNetworkSettings") {
							setNetworkSettings();
						} else if( modelData.id === "updateQp" || modelData.id === "updateRcType"){
							setQParameters();
							routecamOnvifController.setQualityParameters();
							updateProperty(selectedIndex)
						} else if (modelData.id == "updateVidProperty"){
							if (setCurrentImageProperty() === 1) {
								updateProperty(selectedIndex)
							}
						} else if ( modelData.id === "updateGop"){
							setGopSize();
							updateProperty(selectedIndex)
						} else if ( modelData.id === "updateBitrate"){
							setBitrate();
							updateProperty(selectedIndex)
						} else if (modelData.id === "updateDefault"){
							routecamOnvifController.setDefaultValues()
						}
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
				
				Row {
					anchors.left: parent.left
					anchors.leftMargin: sliderLeftMargin
					spacing: 10
					anchors.verticalCenter: parent.verticalCenter
					
					CheckBox {
						id: checkboxControl
						objectName: "checkboxControl"
						checked: accordionColumn.itemData.currentValue ? accordionColumn.itemData.currentValue : false
						enabled: accordionColumn.itemEnabled
						width: expandedStateIconH
						height: expandedStateIconW
						
						// Custom indicator (visual look)
						indicator: Rectangle {
							implicitWidth: expandedStateIconH
							implicitHeight: expandedStateIconW
							x: 0
							anchors.verticalCenter: parent.verticalCenter
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
						
						// Empty contentItem to remove default label
						contentItem: Item {}
						
						// Tooltip logic only for hover — not blocking clicks
						HoverHandler {
							id: hoverHandler
							acceptedDevices: PointerDevice.Mouse
							//onHoveredChanged: checkboxTooltip.visible = hovered && accordionColumn.itemData.toolTip
						}
						
						/*ToolTip {
							id: checkboxTooltip
							visible: false
							delay: 200
							
							background: Rectangle {
								color: window.titleBarColor
								border.color: window.titleBarColor
								border.width: 1
								implicitWidth: checkboxTextItem.paintedWidth + 16 < 400 ? checkboxTextItem.paintedWidth + 16 : 400
								implicitHeight: checkboxTextItem.paintedHeight + 16
							}
							
							contentItem: Text {
								id: checkboxTextItem
								color: window.titleBarColor
								font.pixelSize: baseFontSize + 1
								wrapMode: Text.WordWrap
								text: accordionColumn.itemData.toolTip ? accordionColumn.itemData.toolTip : ""
							}
						}*/
						
						// Changed from onToggled to onClicked
						onClicked: {
							if (accordionColumn.itemEnabled) {
								accordionColumn.itemData.currentValue = checked
								handleCheckBoxValChanged(
									accordionColumn.itemData.label,
									accordionColumn.itemData.id,
									checked
								)
							}
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

