import QtQuick 2.12

Rectangle {
    id: logContentRect
    width: parent ? parent.width : 0
    implicitHeight: tableHeader.height + Math.max(30, logRowsColumn.height)
    height: parent ? Math.max(parent.height, implicitHeight) : implicitHeight
    color: "#0b1723"
	border.color: "#36536b"
	border.width: 1

    property string activeLevel: "Critical"
    property string rawLogText: ""
	property real rightGutter: 0
	property real scrollOffset: 0
    readonly property real timeColumnWidth: Math.max(170, width * 0.25)
    readonly property real levelColumnWidth: Math.max(80, width * 0.11)

    ListModel {
        id: logRows
    }

    // Returns the active log level if it is Info, Verbose or Critical; any other
    // value falls back to "Critical".
    function normalizedLevel() {
        if (activeLevel === "Info" || activeLevel === "Verbose" || activeLevel === "Critical")
            return activeLevel
        return "Critical"
    }

    // Prepends a log message: adds it to rawLogText and inserts each non-empty
    // Prepends one row per received log message (newest first), splitting the
    // "timestamp : message" prefix into the Date & Time and Message columns.
    function appendMessage(logMessage) {
        if (!logMessage || logMessage.length === 0)
            return

        // One log entry -> one row. Messages from the SDKs typically start with "\n", so
        // splitting on newlines put the timestamp and the text into two separate rows.
        var separator = logMessage.indexOf(" : ")
        var timestamp = separator >= 0 ? logMessage.substring(0, separator) : ""
        var message = (separator >= 0 ? logMessage.substring(separator + 3) : logMessage).trim()
        if (message.length === 0)
            return

        rawLogText = (timestamp.length > 0 ? timestamp + " : " : "") + message + "\n" + rawLogText
        logRows.insert(0, {
            timeValue: timestamp,
            levelValue: normalizedLevel(),
            messageValue: message
        })
    }

    Rectangle {
        id: tableHeader
		y: logContentRect.scrollOffset
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30
		z: 20
        color: "#0e1b28"
        border.color: "#263949"
        border.width: 1

        Row {
            anchors.fill: parent

            Text {
                width: logContentRect.timeColumnWidth
                height: parent.height
                leftPadding: 14
                text: "Date & Time"
                color: "#dce6ef"
                font.pixelSize: menuFontSize
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle { width: 1; height: parent.height; color: "#263949" }
            Text {
                width: logContentRect.levelColumnWidth
                height: parent.height
                leftPadding: 14
                text: "Level"
                color: "#dce6ef"
                font.pixelSize: menuFontSize
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle { width: 1; height: parent.height; color: "#263949" }
            Text {
				width: Math.max(0, parent.width - logContentRect.timeColumnWidth
								- logContentRect.levelColumnWidth - logContentRect.rightGutter - 2)
                height: parent.height
                leftPadding: 14
                text: "Message"
                color: "#dce6ef"
                font.pixelSize: menuFontSize
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Column {
		id: logRowsColumn
		y: tableHeader.height

        anchors.left: parent.left
        anchors.right: parent.right

        Repeater {
            model: logRows
            delegate: Rectangle {
                width: logContentRect.width
				height: Math.max(30, messageText.paintedHeight + 10)
                color: rowMouseArea.containsMouse ? "#12365a" : "#0b1723"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: "#172837"
                }

                Row {
                    anchors.fill: parent

                    Text {
						id: timeText
                        width: logContentRect.timeColumnWidth
                        height: parent.height
                        leftPadding: 14
                        text: timeValue
                        color: "#d6dee7"
                        font.pixelSize: menuFontSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
						id: levelText
                        width: logContentRect.levelColumnWidth + 1
                        height: parent.height
                        leftPadding: 15
                        text: levelValue
                        color: levelValue === "Critical" ? "#ff4a43"
                              : levelValue === "Verbose" ? "#ffb34d" : "#45a7ff"
                        font.pixelSize: menuFontSize
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
						id: messageText
						width: Math.max(0, parent.width - logContentRect.timeColumnWidth
										- logContentRect.levelColumnWidth - logContentRect.rightGutter - 1)
                        height: parent.height
						topPadding: 5
						bottomPadding: 5
                        leftPadding: 14
                        text: messageValue
                        color: "#d6dee7"
                        font.pixelSize: menuFontSize
						wrapMode: Text.Wrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: rowMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }

	// Keep the table columns visually framed even when there are no log rows.
	Rectangle {
		x: logContentRect.timeColumnWidth
		y: tableHeader.height
		width: 1
		height: Math.max(0, parent.height - y)
		color: "#263949"
		z: 10
	}
	Rectangle {
		x: logContentRect.timeColumnWidth + logContentRect.levelColumnWidth + 1
		y: tableHeader.height
		width: 1
		height: Math.max(0, parent.height - y)
		color: "#263949"
		z: 10
	}

    TextEdit {
        id: clipboardText
        width: 1
        height: 1
        opacity: 0
        readOnly: true
    }

    Connections {
        target: logController
        onLogMessageReceived: {
            logContentRect.appendMessage(logMessage)
        }
    }

    // Clears both the raw log text and the displayed log rows.
    function clearLog() {
        rawLogText = ""
        logRows.clear()
    }

    // Copies the whole raw log text to the clipboard via the hidden text helper;
    // returns false if the log is empty, true otherwise.
    function copyDisplayedLog() {
        if (rawLogText.length === 0)
            return false

        clipboardText.text = rawLogText
        clipboardText.selectAll()
        clipboardText.copy()
        clipboardText.deselect()
        return true
    }
}
