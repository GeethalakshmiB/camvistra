import Qt.labs.platform 1.1
// Folder Dialog
FolderDialog {
        id: folderDialog
        title: "Select Folder for Still Capture"
        folder: isWindows ? StandardPaths.writableLocation(StandardPaths.DesktopLocation) : SystemPictureFolder
        onAccepted: {
			tempStillPath = folderDialog.folder;
			var message = "Still capture path have been changed to : " + tempStillPath + "\n";
			logController.displayMessage(verboseLogPriority, message)
			window.selectedStillFolderPath(folderDialog.folder)
        }
}
