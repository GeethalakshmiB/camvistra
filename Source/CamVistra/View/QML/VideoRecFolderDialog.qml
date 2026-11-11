import Qt.labs.platform 1.1
// Folder Dialog
FolderDialog {
    id: vidRecFolderDialog
    title: "Select Folder for Video Recording"
    folder: isWindows ? StandardPaths.writableLocation(StandardPaths.DesktopLocation) : SystemVideoFolder
    onAccepted: {
		tempVidRecPath = vidRecFolderDialog.folder;
		var message = "Still capture path have been changed to : " + tempVidRecPath + "\n";
		logController.displayMessage(verboseLogPriority, message)
     	window.selectedVideoFolderPath(vidRecFolderDialog.folder)
    }
}
