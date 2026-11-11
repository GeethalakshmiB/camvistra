import Qt.labs.platform 1.1
// Folder Dialog
FileDialog {
        id: fileDialog
        title: "Select Folder for Still Capture"
		//selectMultiple: false
		nameFilters: ["JSON Files (*.json)"]

		signal selectedFileName(string  filename, string filePath)
        onAccepted: {
			var filePath = fileDialog.currentFile;  
			var fileName = filePath.toString().split("/").pop();
			filePath = filePath.toString()
			if (Qt.platform.os === "windows") {
				// Windows uses 'file:///'
				filePath = filePath.replace("file:///", "");
			} else {
				// Linux and macOS typically use 'file://'
				filePath = filePath.replace("file://", "");
			}
			selectedFileName(fileName, filePath)

        }
    }
