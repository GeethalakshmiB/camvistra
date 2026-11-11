import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
Rectangle {
	   id:logRect
	   color:"#0d1926"
	   border.color: "#36536b"
	   border.width: 1
	   property bool comboBoxOpen : false
	   property bool isLogSelected : true
	   // Latches true the first time the Description tab is selected, so its
	   // WebEngineView (a full embedded Chromium instance) is only created on
	   // first use instead of eagerly at app startup, and is never torn down
	   // again once created.
	   property bool descriptionTabEverShown : !isLogSelected
	   onIsLogSelectedChanged: {
	       if (!isLogSelected) descriptionTabEverShown = true
	   }

	    Rectangle {		       
			id: logLabel
            height: menuItemHeight
			color: "#08131f"
			border.color: "#263949"
			border.width: 1
			radius: 0
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.leftMargin: 5
			anchors.rightMargin: 5
            anchors.top: parent.top
            anchors.topMargin: 5
			Text {
				anchors.left: parent.left
				anchors.leftMargin: 10
				anchors.verticalCenter : parent.verticalCenter
				font.family: "Helvetica"
                font.pixelSize: menuFontSize + 1
                font.bold: true
                text: isLogSelected ? "Log Window" : "Description Window"
                color: "#ffffff"
            } 
			Rectangle {
				anchors.verticalCenter : parent.verticalCenter
				id: imageBackground
				width: expandedStateIconW + 5
				height: expandedStateIconH + 5
				color: mouseArea.containsMouse ? "#c90808" : "transparent"
				anchors.right: logLabel.right
				anchors.rightMargin: 4
				visible: true

				Image {
					id: x_log
					source: "qrc:View/icons/closeSmall.svg"
					anchors.fill: parent
					fillMode: Image.PreserveAspectFit
				}

				MouseArea {
					id: mouseArea
					anchors.fill: parent
					hoverEnabled: true
					onClicked: {
						handleLogCheckedChanged(closeMiddleDown)
						closeMiddleDown = !closeMiddleDown
					}
			  }
			  ToolTip {
					visible : mouseArea.containsMouse
					background: Rectangle {
						color: window.titleBarColor
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Close Log Window"
					}
			  }
		 }
			 Item {		
				id:logPriorityCombo
				width: menuBtnWidth
				height: menuItemHeight
				visible : isLogSelected
				anchors.right : copyLogButn.left
				anchors.rightMargin: 4
				anchors.verticalCenter: parent.verticalCenter

				Rectangle {
					id: menuButton
					anchors.fill: parent
					color: "#0e1b28"
					border.color: comboBoxOpen ? "#0b84f3" : "#263949"
					border.width: 1
					radius: 4
				
					Text {
						id: selectedText
						text: "Critical"
						x: 5
						anchors.verticalCenter: parent.verticalCenter
						color: "white"
						font.pixelSize: menuFontSize
					}

					MouseArea {
						anchors.fill: parent
						onClicked:
						if(!comboBoxOpen){
							comboBoxOpen = true
							logPriorityMenu.open()
						} else{							
							comboBoxOpen = false
						}
					}

					Rectangle {
						anchors.verticalCenter: parent.verticalCenter
						anchors.right : parent.right
						anchors.rightMargin : 2
						width: 15
						height: parent.height - 5
						color: "transparent"

						Text {
							anchors.centerIn: parent
							text: "\u2B9F"
							color: "white"
							font.pixelSize: menuFontSize
						}
					}
				}

				Menu {
					id: logPriorityMenu
					x: menuButton.x
					y: menuButton.y + menuButton.height
					width: logPriorityCombo.width

					MenuItem {
						id: infoLogItem
						text: "Info"
						background: Rectangle {
							color: infoLogItem.hovered ? "#0b5fae" : "#0e1b28"
							anchors.fill: parent
						}
						contentItem: Row {
							spacing: 10
							anchors.fill: parent
							anchors.leftMargin: 10

							Text {
								text: infoLogItem.text
								color: "white"
								font.pixelSize: menuFontSize
								anchors.verticalCenter: parent.verticalCenter
								verticalAlignment: Text.AlignVCenter
							}
						}

						onTriggered: {
							selectedText.text = text
							logController.handleLogPriorityChange(0)
							logComponent.clearLog()
						}
					}

					MenuItem {
						id: verboseLogItem
						text: "Verbose"
						background: Rectangle {
							color: verboseLogItem.hovered ? "#0b5fae" : "#0e1b28"
							anchors.fill: parent
						}
						contentItem: Row {
							spacing: 10
							anchors.fill: parent
							anchors.leftMargin: 10

							Text {
								text: verboseLogItem.text
								color: "white"							
								font.pixelSize: menuFontSize
								anchors.verticalCenter: parent.verticalCenter
								verticalAlignment: Text.AlignVCenter
							}
						}
						onTriggered: {
							selectedText.text = text
							logController.handleLogPriorityChange(1)
							logComponent.clearLog()
						}
					}

					MenuItem {
						id: criticalLogItem
						text: "Critical"
						background: Rectangle {
							color: criticalLogItem.hovered ? "#0b5fae" : "#0e1b28"
							anchors.fill: parent
						}
						contentItem: Row {
							spacing: 10
							anchors.fill: parent
							anchors.leftMargin: 10

							Text {
								text: criticalLogItem.text
								color: "white"
								font.pixelSize: menuFontSize
								anchors.verticalCenter: parent.verticalCenter
								verticalAlignment: Text.AlignVCenter
							}
						}
						
						onTriggered: {
							selectedText.text = text
							logController.handleLogPriorityChange(2)
							logComponent.clearLog()
						}
					}
				}
			}

			Column{
				id: clearLogButn
				anchors.verticalCenter : parent.verticalCenter
				anchors.right : imageBackground.left
				visible : isLogSelected
				Button {
					id: clearLogBtn
					height: menuItemHeight
					width: clearLogW
					hoverEnabled: true  // Enables hover detection

					onClicked: {
						logController.displayMessage(verboseLogPriority, "UI: Clear the log window\n");
						logComponent.clearLog()
					}

					// Background color of the button
					background: Rectangle {
						color: clearLogBtn.hovered ? "#12365a" : "#0e1b28"
						border.color: clearLogBtn.hovered ? "#0b84f3" : "#263949"
						border.width: 1
						radius: 4
						Behavior on color { ColorAnimation { duration: 120 } }
					}

					// Image inside the button
					Image {
						source: "qrc:View/icons/clearLog.svg"
						anchors.centerIn: parent
						width: Math.round(Math.min(parent.width, parent.height) * 0.62)
						height: width
						fillMode: Image.PreserveAspectFit
						sourceSize: Qt.size(Math.ceil(width * Screen.devicePixelRatio),
											Math.ceil(height * Screen.devicePixelRatio))
					}
				}  
				ToolTip {
					visible : clearLogBtn.hovered
					background: Rectangle {
						color: window.titleBarColor
						border.color: window.titleBarColor
						border.width: 1
						radius: 4
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: "Clear Log"
					}
			   }
		   }

			Column {
				id: copyLogButn
				anchors.verticalCenter: parent.verticalCenter
				anchors.right: isLogSelected ? clearLogButn.left : imageBackground.left
				visible: true

				Button {
					id: copyLogBtn
					objectName: "copyLogBtn"
					property bool copied: false
					height: menuItemHeight
					width: clearLogW
					hoverEnabled: true

					onClicked: {
						var copiedSuccessfully = isLogSelected
								? logComponent.copyDisplayedLog()
								: descriptionComponent.copyDisplayedDescription()
						if (copiedSuccessfully) {
							copied = true
							copiedStateTimer.restart()
						}
					}

					background: Rectangle {
						color: copyLogBtn.hovered ? "#12365a" : "#0e1b28"
						border.color: copyLogBtn.hovered ? "#0b84f3" : "#263949"
						border.width: 1
						radius: 4
						Behavior on color { ColorAnimation { duration: 120 } }
					}

					Image {
						anchors.centerIn: parent
						width: Math.round(Math.min(parent.width, parent.height) * 0.62)
						height: width
						fillMode: Image.PreserveAspectFit
						sourceSize: Qt.size(Math.ceil(width * Screen.devicePixelRatio),
											Math.ceil(height * Screen.devicePixelRatio))
						source: copyLogBtn.copied ? "qrc:View/icons/copiedLog.svg"
												 : "qrc:View/icons/copyLog.svg"
					}

					Timer {
						id: copiedStateTimer
						interval: 2000
						repeat: false
						onTriggered: copyLogBtn.copied = false
					}
				}

				ToolTip {
					visible: copyLogBtn.hovered
					background: Rectangle {
						color: window.titleBarColor
						border.color: window.titleBarColor
						border.width: 1
						radius: 4
					}
					contentItem: Text {
						color: "white"
						font.pixelSize: baseFontSize + 1
						text: copyLogBtn.copied ? "Copied to clipboard" : "Copy to clipboard"
					}
				}
			}
			
		}

		Rectangle {
				//inner rect
                id: logInnerRect
				visible : isLogSelected
                height: parent.height - tabBarRect.height
				anchors.bottom : tabBarRect.top
                anchors.top: logLabel.bottom
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.leftMargin: 5
				anchors.rightMargin: 5
				color: "#0b1723"
				border.color: "#36536b"
				border.width: 1

				Flickable {
					id: logFlickable
                    anchors.fill: logInnerRect
                    contentWidth: width
                    contentHeight: Math.max(height, logComponent.implicitHeight)
                    focus: true
					clip: true
					interactive: true  //  Mouse interaction is allowed

				    boundsBehavior: Flickable.StopAtBounds  //  Prevent overscroll

					
                    Log{
						id: logComponent
						width: logFlickable.width
						rightGutter: 14
						scrollOffset: logFlickable.contentY
						activeLevel: selectedText.text
					}

					//  Custom vertical scrollbar
					ScrollBar.vertical: ScrollBar {
						id: logCustomVScrollBar
						width: 12
						active: false
						visible : logFlickable.contentHeight > logFlickable.height
						anchors.top: parent.top
						anchors.bottom: parent.bottom
						anchors.right: parent.right

						contentItem: Rectangle {
							implicitWidth: 8
							implicitHeight: parent.height
							radius: 4
							color: (logCustomVScrollBar.active || logCustomVScrollBar.hovered)
								   ? "#2087cc" : "#45a7ff"
						}

						background: Rectangle {
							color: "#07111d"
							border.color: "#263949"
							border.width: 1
							radius: 4
							width: 12
						}
					}
				}
		}

		Rectangle {
				//inner rect
                id: descriptionInnerRect
                height: parent.height - tabBarRect.height
				visible : !isLogSelected
				anchors.bottom : tabBarRect.top
                anchors.top: logLabel.bottom
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.leftMargin: 5
				anchors.rightMargin: 5
				color: "#0b1723"
				border.color: "#263949"
				border.width: 1
					
            Description {
				id: descriptionComponent
				loadWebEngine: descriptionTabEverShown
			}
		}

		// FIX: Replaced TabBar + TabButton entirely with Rectangle + Row + MouseArea
		// TabButton's default Qt style sheet overrides custom backgrounds at 100% DPI on 4K
		// Plain Rectangle/MouseArea has no default styling - behaves identically at any DPI/scale
		Rectangle {
			id: tabBarRect
			width: parent.width
			height: statusBarHeight
			color: "#0e1b28"
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 3

			Row {
				id: customTabRow
				anchors.fill: parent
				spacing: 0

				// ── Log Tab ──────────────────────────────────────────────
				Rectangle {
					id: logTab
					width: tabBarWidth / 2
					height: tabBarRect.height
					color: isLogSelected ? "#12365a" : "#0e1b28"

					border.color: "#5e5e5e"
					border.width: 1
					Text {
						anchors.centerIn: parent
						text: "Log"
						font.pixelSize: menuFontSize
						font.bold: isLogSelected
						color: "#ffffff"
					}

					MouseArea {
						anchors.fill: parent
						hoverEnabled: true
						onClicked: {
							isLogSelected = true
						}
					}
				}

				// ── Separator line between Log and Description tabs ───────
				Rectangle {
					id: tabSeparator
					width: 1
					height: tabBarRect.height
					color: "#555555"
				}

				// ── Description Tab ───────────────────────────────────────
				Rectangle {
					id: descriptionTab
					width: (tabBarWidth / 2) - 1  // subtract separator width to keep total width consistent
					height: tabBarRect.height
					color: !isLogSelected ? "#12365a" : "#0e1b28"

					border.color: "#5e5e5e"
					border.width: 1
					Text {
						anchors.centerIn: parent
						text: "Description"
						font.pixelSize: menuFontSize
						font.bold: !isLogSelected
						color: "#ffffff"
					}

					MouseArea {
						anchors.fill: parent
						hoverEnabled: true
						onClicked: {
							isLogSelected = false
						}
					}
				}
			}
		}

	Component.onCompleted : {
		logController.handleLogPriorityChange(2)
	}
}
