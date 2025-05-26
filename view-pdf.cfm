<!DOCTYPE html>
<html>
<head>
    <title>View Generated PDFs</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .pdf-list { margin: 20px 0; }
        .pdf-item { 
            background: #f0f0f0; 
            padding: 10px; 
            margin: 10px 0; 
            border-radius: 5px;
        }
        iframe {
            width: 100%;
            height: 600px;
            border: 1px solid #ccc;
        }
    </style>
</head>
<body>
    <h1>Generated PDFs</h1>
    
    <cfscript>
        tempDir = expandPath("./temp/");
        pdfFiles = directoryList(tempDir, false, "query", "*.pdf");
    </cfscript>
    
    <cfif pdfFiles.recordCount GT 0>
        <div class="pdf-list">
            <h2>Available PDFs:</h2>
            <cfloop query="pdfFiles">
                <div class="pdf-item">
                    <cfoutput>
                    <strong>#name#</strong> - 
                    Size: #numberFormat(size/1024, "0.00")# KB - 
                    Created: #dateFormat(dateLastModified, "mm/dd/yyyy")# #timeFormat(dateLastModified, "hh:mm:ss tt")#
                    <br>
                    <a href="temp/#name#" target="_blank">View PDF</a> | 
                    <a href="temp/#name#" download>Download PDF</a>
                    </cfoutput>
                </div>
            </cfloop>
        </div>
        
        <h2>Preview Latest PDF:</h2>
        <cfquery name="latestPDF" dbtype="query">
            SELECT * FROM pdfFiles
            ORDER BY dateLastModified DESC
        </cfquery>
        <cfoutput><iframe src="temp/#latestPDF.name#"></iframe></cfoutput>
    <cfelse>
        <p>No PDFs have been generated yet. Use the test client to generate a PDF!</p>
    </cfif>
    
    <p><a href="client-examples/test-client.cfm">Back to Test Client</a></p>
</body>
</html>