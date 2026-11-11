var modelData = [];
var templateHtml = "";
var extModelData = [];
var gridModelData = []
var crossHairModelData = []

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateCrossHairModelData(jsonArray)
//
//  PURPOSE		:	To store the cross-hair documentation entries used by
//					getCrossHairHtmlDescription().
//
//	ARGUMENTS	:	jsonArray - array of cross-hair doc objects, each with an id
//					  and h1/content/API fields
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateCrossHairModelData(jsonArray) {
    crossHairModelData = jsonArray
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getCrossHairHtmlDescription(id)
//
//  PURPOSE		:	To build the HTML help page for a cross-hair control from the
//					cached cross-hair doc entry with the given id. Fills the
//					template's {{key}} placeholders from that entry and removes
//					the sections of keys it lacks.
//
//	ARGUMENTS	:	id - id of the cross-hair doc entry to render
//
//	RETURN		:	String - generated HTML, or an empty HTML page if the id is
//					not found
///////////////////////////////////////////////////////////////////////////
function getCrossHairHtmlDescription(id) {
    for (var i = 0; i < crossHairModelData.length; i++) {
        if (crossHairModelData[i].id === id) {
            var data = crossHairModelData[i]
            var html = templateHtml

            ///////////////////////////////////////////////////////////////////////////
            //  FUNCTION	:	replaceOrRemove(key)
            //
            //  PURPOSE		:	To substitute one placeholder in the cross-hair HTML with the
            //					entry's text (newlines as <br>), or remove that key's section
            //					via removeSection() when the entry has no value for it.
            //
            //	ARGUMENTS	:	key - placeholder/section name to replace or remove in the
            //					  template
            //
            //	RETURN		:	None
            ///////////////////////////////////////////////////////////////////////////
            function replaceOrRemove(key) {
                if (data[key]) {
                    html = html.replace(new RegExp(`{{${key}}}`, 'g'), data[key].replace(/\n/g, "<br>"))
                } else {
                    html = removeSection(html, key)
                }
            }

            const keys = [
                "h1", "content1", "h2", "content2", "h3",
                "struct1", "struct2",
                "getAPIHeading", "getAPIDes", "getAPICode",
                "setAPIHeading", "setAPIDes", "setAPICode"
            ]

            keys.forEach(replaceOrRemove)
            return html
        }
    }
    return "<html><body><p></p></body></html>"
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateGridModelData(jsonArray)
//
//  PURPOSE		:	To store the grid-overlay documentation entries used by
//					getGridHtmlDescription().
//
//	ARGUMENTS	:	jsonArray - array of grid doc objects, each with an id and
//					  h1/content/API fields
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateGridModelData(jsonArray) {
    gridModelData = jsonArray
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getGridHtmlDescription(id)
//
//  PURPOSE		:	To build the HTML help page for a grid-overlay control from
//					the cached grid doc entry with the given id. Fills the
//					template's {{key}} placeholders from that entry and removes
//					the sections of keys it lacks.
//
//	ARGUMENTS	:	id - id of the grid doc entry to render
//
//	RETURN		:	String - generated HTML, or an empty HTML page if the id is
//					not found
///////////////////////////////////////////////////////////////////////////
function getGridHtmlDescription(id) {
    for (var i = 0; i < gridModelData.length; i++) {
        if (gridModelData[i].id === id) {
            var data = gridModelData[i];
            var html = templateHtml;

            ///////////////////////////////////////////////////////////////////////////
            //  FUNCTION	:	replaceOrRemove(key)
            //
            //  PURPOSE		:	To substitute one placeholder in the grid HTML with the
            //					entry's text (newlines as <br>), or remove that key's section
            //					via removeSection() when the entry has no value for it.
            //
            //	ARGUMENTS	:	key - placeholder/section name to replace or remove in the
            //					  template
            //
            //	RETURN		:	None
            ///////////////////////////////////////////////////////////////////////////
            function replaceOrRemove(key) {
                if (data[key]) {
                    html = html.replace(new RegExp(`{{${key}}}`, 'g'), data[key].replace(/\n/g, "<br>"));
                } else {
                    html = removeSection(html, key);
                }
            }

            const keys = [
                "h1", "content1", "h2", "content2", "h3",
                "struct1", "struct2",
                "getAPIHeading", "getAPIDes", "getAPICode",
                "setAPIHeading", "setAPIDes", "setAPICode"
            ];

            keys.forEach(replaceOrRemove);
            return html;
        }
    }
    return "<html><body><p></p></body></html>";
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateModelData(jsonArray)
//
//  PURPOSE		:	To store the standard (UVC) control documentation entries used
//					by getHtmlDescription().
//
//	ARGUMENTS	:	jsonArray - array of control doc objects, each with an id and
//					  h1/content/API fields
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateModelData(jsonArray) {
    modelData = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	updateExtModelData(jsonArray)
//
//  PURPOSE		:	To store the extension-unit control documentation entries used
//					by getExtHtmlDescription().
//
//	ARGUMENTS	:	jsonArray - array of extension control doc objects
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function updateExtModelData(jsonArray) {
    extModelData = jsonArray;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	setTemplate(htmlContent)
//
//  PURPOSE		:	To store the HTML template (with {{key}} placeholders and
//					start/end section markers) that all get*HtmlDescription()
//					functions fill in.
//
//	ARGUMENTS	:	htmlContent - HTML template text
//
//	RETURN		:	None
///////////////////////////////////////////////////////////////////////////
function setTemplate(htmlContent) {
    templateHtml = htmlContent;
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	removeSection(html, key)
//
//  PURPOSE		:	To delete every block delimited by <!-- start:key --> and <!--
//					end:key --> (markers included) from the given HTML.
//
//	ARGUMENTS	:	html - HTML text to process
//					key - section name used in the start/end markers
//
//	RETURN		:	String - the HTML with the section(s) removed
///////////////////////////////////////////////////////////////////////////
function removeSection(html, key) {
    const regex = new RegExp(`<!-- start:${key} -->[\\s\\S]*?<!-- end:${key} -->`, "g");
    return html.replace(regex, '');
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getHtmlDescription(id)
//
//  PURPOSE		:	To build the HTML help page for a standard control from the
//					cached doc entry with the given id. Fills the template's
//					{{key}} placeholders from that entry and removes the sections
//					of keys it lacks.
//
//	ARGUMENTS	:	id - id of the control doc entry to render
//
//	RETURN		:	String - generated HTML, or an empty HTML page if the id is
//					not found
///////////////////////////////////////////////////////////////////////////
function getHtmlDescription(id) {
    for (var i = 0; i < modelData.length; i++) {
        if (modelData[i].id === id) {
            var data = modelData[i];
            var html = templateHtml;

            ///////////////////////////////////////////////////////////////////////////
            //  FUNCTION	:	replaceOrRemove(key)
            //
            //  PURPOSE		:	To substitute one placeholder in the control HTML with the
            //					entry's text (newlines as <br>), or remove that key's section
            //					via removeSection() when the entry has no value for it.
            //
            //	ARGUMENTS	:	key - placeholder/section name to replace or remove in the
            //					  template
            //
            //	RETURN		:	None
            ///////////////////////////////////////////////////////////////////////////
            function replaceOrRemove(key) {
                if (data[key]) {
                    html = html.replace(new RegExp(`{{${key}}}`, 'g'), data[key].replace(/\n/g, "<br>"));
                } else {
                    html = removeSection(html, key);
                }
            }

            const keys = [
                "h1", "content1", "h2", "content2", "h3",
                "struct1", "struct2",
                "getAPIHeading", "getAPIDes", "getAPICode",
                "setAPIHeading", "setAPIDes", "setAPICode"
            ];

            keys.forEach(replaceOrRemove);

            return html;
        }
    }
    return "<html><body><p></p></body></html>";
}

///////////////////////////////////////////////////////////////////////////
//  FUNCTION	:	getExtHtmlDescription(id)
//
//  PURPOSE		:	To build the HTML help page for an extension-unit control from
//					the cached extension doc entry with the given id. Fills the
//					template's {{key}} placeholders from that entry and removes
//					the sections of keys it lacks.
//
//	ARGUMENTS	:	id - id of the extension control doc entry to render
//
//	RETURN		:	String - generated HTML, or an empty HTML page if the id is
//					not found
///////////////////////////////////////////////////////////////////////////
function getExtHtmlDescription(id) {
    for (var i = 0; i < extModelData.length; i++) {
        if (extModelData[i].id === id) {
            var data = extModelData[i];
            var html = templateHtml;

            ///////////////////////////////////////////////////////////////////////////
            //  FUNCTION	:	replaceOrRemove(key)
            //
            //  PURPOSE		:	To substitute one placeholder in the extension HTML with the
            //					entry's text (newlines as <br>), or remove that key's section
            //					via removeSection() when the entry has no value for it.
            //
            //	ARGUMENTS	:	key - placeholder/section name to replace or remove in the
            //					  template
            //
            //	RETURN		:	None
            ///////////////////////////////////////////////////////////////////////////
            function replaceOrRemove(key) {
                if (data[key]) {
                    html = html.replace(new RegExp(`{{${key}}}`, 'g'), data[key].replace(/\n/g, "<br>"));
                } else {
                    html = removeSection(html, key);
                }
            }

            const keys = [
                "h1", "content1", "h2", "content2", "h3",
                "struct1", "struct2",
                "getAPIHeading", "getAPIDes", "getAPICode",
                "setAPIHeading", "setAPIDes", "setAPICode"
            ];

            keys.forEach(replaceOrRemove);

            return html;
        }
    }
    return "<html><body><p></p></body></html>";
}