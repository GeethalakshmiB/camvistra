import QtQuick 2.3
import QtWebEngine 1.7
import "../JS/tooltipAndDoc.js" as DescriptionJS

Rectangle {
    id: descriptionContentRect
    width: parent.width - 7
    height: parent.height - 7
    anchors.centerIn: parent
    color: "#0b1723"
    
    // Static property to track WebEngine initialization
    property bool webEngineInitialized: false
    property string displayedDescriptionHtml: ""

    // Set by the parent (LogContainer) once the Description tab has actually
    // been selected at least once. WebEngineView spins up a full embedded
    // Chromium instance — constructing it eagerly at app startup (when this
    // component is built as part of the always-present tab tree) adds real
    // load-time cost even though most users never open this tab.
    property bool loadWebEngine: false

    TextEdit {
        id: descriptionClipboardText
        visible: false
        readOnly: true
        textFormat: TextEdit.RichText
        text: displayedDescriptionHtml
    }

    Row {
        width: parent.width
        height: parent.height

        Loader {
            id: webEngineLoader
            width: parent.width
            height: parent.height
            active: loadWebEngine

            sourceComponent: Component {
                WebEngineView {
                    id: descriptionWebView
                    objectName: "descriptionWebView"
                    visible: true
                    width: parent.width
                    height: parent.height
                    backgroundColor: "#0b1723"
                    settings.javascriptEnabled: false
                    settings.localContentCanAccessRemoteUrls: false
                    settings.localContentCanAccessFileUrls: true

                    Component.onCompleted: {
                        descriptionContentRect.webEngineInitialized = true
                        // Catch up to whatever was set while the WebView didn't exist yet.
                        loadHtml(descriptionContentRect.displayedDescriptionHtml)
                    }
                }
            }
        }
		WebEngineView {
            id: descriptionWebView
            objectName: "descriptionWebView"
            visible: true
            width: parent.width 
            height: parent.height
            backgroundColor: "#0b1723" 
            settings.javascriptEnabled: false
            settings.localContentCanAccessRemoteUrls: false
            settings.localContentCanAccessFileUrls: true
        }
    }
    
    // Helper function to get WebView reference
    /*function getWebView() {
        return webEngineLoader.item
    }*/

   Connections {
	target: logController  // Replace with the actual instance of LogModel
        onTooltipAndDocJsonArrayRead: {
            DescriptionJS.updateModelData(jsonArray)
        }
        onUvcExtTooltipAndDocJsonArrayRead: {
            DescriptionJS.updateExtModelData(jsonArray)
        }
        onSelectedItem: {
           // if (descriptionContentRect.webEngineInitialized && getWebView()) {
                showDescription(DescriptionJS.getHtmlDescription(itemId))
           // }
        }
        onSelectedExtItem: {
          //  if (descriptionContentRect.webEngineInitialized && getWebView()) {
                showDescription(DescriptionJS.getExtHtmlDescription(itemId))
           // }
        }
        onHtmlFileRead: {
            DescriptionJS.setTemplate(htmlContent)
        }

        onGridDocJsonArrayRead: {
            DescriptionJS.updateGridModelData(jsonArray)
        }

        onSelectedGridItem: {
                showDescription(DescriptionJS.getGridHtmlDescription(id))
           // }
        }

        onCrossHairDocJsonArrayRead: {
            DescriptionJS.updateCrossHairModelData(jsonArray)
        }

        onSelectedCrossHairItem: {
         //   if (descriptionContentRect.webEngineInitialized && getWebView()) {
                showDescription(DescriptionJS.getCrossHairHtmlDescription(id))
          //  }
        }
    }
	Connections{
		target : prevController
		onCameraClosed: {
          //  if (descriptionContentRect.webEngineInitialized && getWebView()) {
                showDescription("<html><body><p></p></body></html>")
           // }
		}
	}
    Component.onCompleted: {
        logController.readHtmlFile(":View/HTML/description.html");
        logController.readJsonGridDocArrayFile() 
        logController.readJsonCrossHairDocArrayFile() 
    } 

    // Displays the given description HTML: rewrites legacy colours to the app
    // palette, injects themed page/scrollbar CSS, stores it in
    // displayedDescriptionHtml and loads it into the web view if already created.
    function showDescription(html) {
		// Normalize legacy templates, then enforce the application palette for
		// every payload (including small cross-hair/empty HTML documents).
		var themedHtml = html ? html.replace(/#211f1f/gi, "#0b1723") : ""
		themedHtml = themedHtml.replace(/#292922/gi, "#07111d")
							 .replace(/#19699e/gi, "#45a7ff")
							 .replace(/#2087cc/gi, "#2087cc")
		var applicationTheme = "<style>" +
			"html,body{min-height:100%;background-color:#0b1723 !important;color:#ffffff;}" +
			"::-webkit-scrollbar{width:12px;height:12px;}" +
			"::-webkit-scrollbar-track{background:#07111d;border:1px solid #263949;border-radius:4px;}" +
			"::-webkit-scrollbar-thumb{background:#45a7ff;border-radius:4px;}" +
			"::-webkit-scrollbar-thumb:hover,::-webkit-scrollbar-thumb:active{background:#2087cc;}" +
			"::-webkit-scrollbar-corner{background:#07111d;}" +
			"</style>"
		if (/<\/head>/i.test(themedHtml))
			themedHtml = themedHtml.replace(/<\/head>/i, applicationTheme + "</head>")
		else if (/<body[^>]*>/i.test(themedHtml))
			themedHtml = themedHtml.replace(/<body([^>]*)>/i, "<body$1>" + applicationTheme)
		else
			themedHtml = applicationTheme + themedHtml
        displayedDescriptionHtml = themedHtml
        // Before the Description tab has ever been opened, webEngineLoader.item
        // is null — displayedDescriptionHtml still gets updated above, and
        // Loader's Component.onCompleted replays it once the tab is first shown.
        if (webEngineLoader.item) {
            webEngineLoader.item.loadHtml(themedHtml)
        }
        //descriptionWebView.loadHtml(themedHtml)
    }

    // Copies the currently displayed description text to the clipboard via the
    // hidden text helper; returns false if nothing is displayed, true otherwise.
    function copyDisplayedDescription() {
        if (displayedDescriptionHtml.length === 0)
            return false

        descriptionClipboardText.selectAll()
        descriptionClipboardText.copy()
        descriptionClipboardText.deselect()
        return true
    }

}
