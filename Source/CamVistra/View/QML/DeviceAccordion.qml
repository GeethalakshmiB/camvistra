import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

Column {
    id: root
    width: parent.width
    height: parent.height
    spacing: 4

    property alias model: columnRepeater.model
    property int widthRefreshToken: 0
    property real requiredWidth: widthRefreshToken >= 0 ? requiredWidthForItems(model, 0) : 0

    FontMetrics {
        id: labelMetrics
        font.pixelSize: menuFontSize
    }

    // Recursively computes the width (px) needed to show the item labels at the given depth,
    // including expanded children, so the accordion can size itself to fit.
    function requiredWidthForItems(items, depth) {
        if (!items || items.length === undefined)
            return 0

        var maxWidth = 0
        for (var i = 0; i < items.length; ++i) {
            var item = items[i]
            var label = item && item.label !== undefined ? String(item.label) : ""
            var rowWidth = 72 + depth * 20 + labelMetrics.advanceWidth(label)
            maxWidth = Math.max(maxWidth, rowWidth)

            if (item && item.children && item.expanded)
                maxWidth = Math.max(maxWidth, requiredWidthForItems(item.children, depth + 1))
        }
        return maxWidth + 8
    }

    Repeater {
        id: columnRepeater
        delegate: accordionDelegate
    }

    /* ================= ACCORDION DELEGATE ================= */
    Component {
        id: accordionDelegate

        Column {
            width: parent ? parent.width : 0
            spacing: 8

            Item {
                id: infoRow
                width: parent.width
                height: 40                          // ← explicit fixed height instead of implicitHeight

                property bool expanded: modelData.expanded ? modelData.expanded : false
                property bool rowEnabled: modelData.enabled === false ? false : true
				property bool hovered: rowMouseArea.containsMouse || mouseArea.containsMouse || itemCheckbox.hovered

				Rectangle {
					anchors.fill: parent
					color: infoRow.hovered && infoRow.rowEnabled
						&& !modelData.children && !modelData.noDevices
						? "#12365a" : "transparent"
					radius: 4
					Behavior on color { ColorAnimation { duration: 120 } }
				}

                MouseArea {
					id: rowMouseArea
                    anchors.fill: parent
					hoverEnabled: true
                    enabled: infoRow.rowEnabled && modelData.children ? true : false
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: {
                        if (mouse.button === Qt.RightButton) {
                            if (modelData.id === "ethernetDev") {
                                var overlayPos = mapToItem(Overlay.overlay, mouse.x, mouse.y)
                                ethernetContextDialog.clickX = overlayPos.x
                                ethernetContextDialog.clickY = overlayPos.y
                                ethernetContextDialog.open()
                            }
                            else if (modelData.id === "wifiDev") {        
                                var overlayPos = mapToItem(Overlay.overlay, mouse.x, mouse.y)
                                wifiContextDialog.clickX = overlayPos.x
                                wifiContextDialog.clickY = overlayPos.y
                                wifiContextDialog.open()
                            }
                            return
                        }

                        infoRow.expanded = !infoRow.expanded
                        setExpandedState(modelData.label, infoRow.expanded)
                        root.widthRefreshToken++
                        var message = "Number of " + modelData.label + " : ";
                        if (modelData.children.length > 0) {
                            let child = modelData.children[0];
                            if (child.noDevices === true) {
                                message += "0";
                            } else {
                                if (Array.isArray(child)) {
                                    message += child.length;
                                } else {
                                    message += "1";
                                }
                            }
                        } else {
                            message += "0";
                        }
                        message += "\n"
                        logController.displayMessage(verboseLogPriority, message);
                    }
                }

                RowLayout {
                    id: headerRow
                    anchors {
                        left: parent.left
                        right: parent.right          // ← stretch full width
                        leftMargin: 12
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter   // ← center in infoRow
                    }
                    height: parent.height            // ← match infoRow height
                    spacing: 8

                    Image {
                        id: carrot
                        visible: modelData.children ? true : false
                        source: "qrc:View/icons/right-arrow.svg"
                        sourceSize.width: expandedStateIconW
                        sourceSize.height: expandedStateIconH
                        Layout.alignment: Qt.AlignVCenter
                        transform: Rotation {
                            origin.x: 5
                            origin.y: 5
                            angle: infoRow.expanded ? 90 : 0
                            Behavior on angle { NumberAnimation { duration: 150 } }
                        }
                    }

                    CheckBox {
                        id: itemCheckbox
                        objectName: modelData.devicePath
                            ? "deviceCheckbox_" + modelData.devicePath
                            : ""
                        enabled: infoRow.rowEnabled && !videoRecord && !isControlUpdated && !opencamInitiated
                        visible: (!modelData.children && !modelData.noDevices) ? true : false
                        checked: (!modelData.children && !modelData.noDevices) ? modelData.checked : false
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: checkBoxW
                        implicitHeight: checkBoxH

                        indicator: Rectangle {
                            implicitWidth: checkBoxW
                            implicitHeight: checkBoxH
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 3
                            color: itemCheckbox.checked
                                ? (!itemCheckbox.enabled ? "black" : "#1e90d4")
                                : "#161414"
                            border.color: itemCheckbox.checked
                                ? (!itemCheckbox.enabled ? "#1a4a6e" : "#1e90d4")
                                : (!itemCheckbox.enabled ? "#343434" : "#3a5a7a")
                            border.width: 2
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 2
                                color: "transparent"
                                border.color: itemCheckbox.checked ? "#5ab4f0" : "transparent"
                                border.width: 1
                                opacity: 0.4
                            }

                            Text {
                                anchors.centerIn: parent
                                text: itemCheckbox.checked ? "\u2713" : ""
                                font.pixelSize: 13
                                font.bold: true
                                color: !itemCheckbox.enabled ? "#5a5a5a" : "#ffffff"
                            }
                        }

                        onCheckedChanged: {
                            if (itemCheckbox.checked) {
								if(modelData.type == "Usb"){
									setSelectedDevice({
										label: modelData.label,
										checked: modelData.checked,
										devicePath: modelData.devicePath,
										deviceName: modelData.deviceName,
										deviceIP: modelData.deviceIP,
										deviceVid: modelData.deviceVid,
										devicePid: modelData.devicePid,
										manuallyAdded: modelData.manuallyAdded,
										transportType: modelData.transportType,
										type: modelData.type
									})
								} else {									
									setSelectedDevice({
										label: modelData.label,
										checked: modelData.checked,
										devicePath: modelData.devicePath,
										deviceName: modelData.deviceName,
										deviceIP: modelData.deviceIP,
										manuallyAdded: modelData.manuallyAdded,
										type: modelData.type
									})
								}
                            } else {
								if(modelData.type == "Usb"){
									
									deSelectDevice({
										label: modelData.label,
										checked: modelData.checked,
										devicePath: modelData.devicePath,
										deviceSerialNo: modelData.deviceSerialNo,
										deviceIP: modelData.deviceIP,
										deviceVid: modelData.deviceVid,
										devicePid: modelData.devicePid,
										manuallyAdded: modelData.manuallyAdded,
										transportType: modelData.transportType,
										type: modelData.type
									})
								} else {
									deSelectDevice({
										label: modelData.label,
										checked: modelData.checked,
										devicePath: modelData.devicePath,
										deviceSerialNo: modelData.deviceSerialNo,
										deviceIP: modelData.deviceIP,
										manuallyAdded: modelData.manuallyAdded,
										type: modelData.type
									})
								}
                            }
                        }
                    }

                    Text {
                        id: labelText
                        text: modelData.label
                        font.pixelSize: menuFontSize
                        color: modelData.noDevices || !infoRow.rowEnabled || ((videoRecord || isControlUpdated || opencamInitiated) && !modelData.children) ? "#66665f" : "#ffffff"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true       // ← takes remaining space, enables elide
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        //elide: Text.ElideRight

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: infoRow.rowEnabled && !videoRecord && !isControlUpdated && !opencamInitiated
                            onClicked: {
                                if (!modelData.children && !modelData.noDevices) {
                                    itemCheckbox.checked = !itemCheckbox.checked
                                } else if (modelData.children) {
                                    infoRow.expanded = !infoRow.expanded
                                    setExpandedState(modelData.label, infoRow.expanded)
                        root.widthRefreshToken++
                                }
                            }
                        }

                        ToolTip {
                            // Guard against opening before this delegate is actually
                            // parented into a shown window (e.g. a hover during list
                            // population) - Popup can't resolve a window to anchor
                            // itself to yet and logs "cannot find any window to open
                            // popup in" otherwise.
                            visible: mouseArea.containsMouse && labelText.Window.window !== null
                            delay: 500
			    x: 0
                            background: Rectangle {
                                color: window.titleBarColor
                                radius: 3
                            }
                            contentItem: Text {
                                color: "white"
                                font.pixelSize: baseFontSize + 1
                                text: modelData.label
                            }
                        }
                    }
                }
            }

            ListView {
                id: subEntryColumn
                x: 20
                width: parent.width - x
                model: modelData.children ? modelData.children : []
                delegate: accordionDelegate
                interactive: false
                opacity: infoRow.expanded ? 1 : 0
                visible: opacity > 0
                height: contentHeight * opacity
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

			// Separate complete parent sections. When expanded, this naturally
			// sits below the final child instead of directly below the header.
			Rectangle {
				x: 5
				width: parent.width - 5
				height: 1
				visible: modelData.children ? true : false
				color: "#263949"
			}
        }
    }
}
