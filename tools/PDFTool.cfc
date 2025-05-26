component displayname="PDFTool" {
    
    /**
     * Example of a ColdFusion-specific tool that leverages CF's built-in PDF capabilities
     * This demonstrates how easy it is to add CF's powerful features to the MCP ecosystem
     */
    
    public struct function executeTool(required string toolName, required struct args) {
        try {
            switch(arguments.toolName) {
                case "generatePDF":
                    return generatePDFFromHTML(arguments.args);
                    
                case "extractPDFText":
                    return extractTextFromPDF(arguments.args);
                    
                case "mergePDFs":
                    return mergePDFFiles(arguments.args);
                    
                default:
                    throw(type="ToolNotFound", message="Unknown PDF tool: #arguments.toolName#");
            }
            
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Error executing PDF tool: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private struct function generatePDFFromHTML(required struct args) {
        validateRequiredParams(arguments.args, ["html", "filename"]);
        
        // Ensure filename has .pdf extension
        var filename = arguments.args.filename;
        if (!findNoCase(".pdf", filename)) {
            filename &= ".pdf";
        }
        
        // Create safe path
        var tempDir = expandPath("/mcpcfc/temp/");
        var pdfPath = tempDir & filename;
        
        try {
            // Use ColdFusion's built-in PDF generation
            cfdocument(
                format="pdf",
                filename="#pdfPath#",
                overwrite="true"
            ) {
                writeOutput(arguments.args.html);
            }
            
            return {
                "content": [{
                    "type": "text",
                    "text": "PDF generated successfully! File saved as: #filename# in temp directory"
                }]
            };
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Error generating PDF: #e.message# #e.detail#"
                }],
                "isError": true
            };
        }
    }
    
    private struct function extractTextFromPDF(required struct args) {
        validateRequiredParams(arguments.args, ["pdfPath"]);
        
        try {
            // Construct path - if path doesn't start with /, assume it's relative to temp directory
            var pdfPath = arguments.args.pdfPath;
            if (!left(pdfPath, 1) == "/" && !findNoCase(":\", pdfPath)) {
                pdfPath = "/mcpcfc/temp/" & pdfPath;
            }
            var pdfFile = expandPath(pdfPath);
            
            // Check if file exists
            if (!fileExists(pdfFile)) {
                throw(type="FileNotFound", message="PDF file not found: #pdfPath#");
            }
            
            var extractedText = "";
            
            // Extract text from PDF
            cfpdf(
                action="extracttext",
                source=pdfFile,
                name="local.pdfText"
            );
            
            if (isDefined("local.pdfText")) {
                extractedText = local.pdfText;
            }
            
            return {
                "content": [{
                    "type": "text", 
                    "text": "Extracted text from #arguments.args.pdfPath#:<br><br>#extractedText#"
                }]
            };
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Error extracting text from PDF: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private struct function mergePDFFiles(required struct args) {
        validateRequiredParams(arguments.args, ["sourcePaths", "outputPath"]);
        
        try {
            // Process output path
            var outputPath = arguments.args.outputPath;
            if (!left(outputPath, 1) == "/" && !findNoCase(":\", outputPath)) {
                outputPath = "/mcpcfc/temp/" & outputPath;
            }
            var outputFile = expandPath(outputPath);
            
            // Process source paths
            var sourceFiles = [];
            for (var path in arguments.args.sourcePaths) {
                var sourcePath = path;
                if (!left(sourcePath, 1) == "/" && !findNoCase(":\", sourcePath)) {
                    sourcePath = "/mcpcfc/temp/" & sourcePath;
                }
                var fullPath = expandPath(sourcePath);
                
                // Check if file exists
                if (!fileExists(fullPath)) {
                    throw(type="FileNotFound", message="Source PDF not found: #path#");
                }
                
                arrayAppend(sourceFiles, fullPath);
            }
            
            // Ensure we have files to merge
            if (arrayLen(sourceFiles) < 2) {
                throw(type="InvalidParams", message="At least 2 PDF files are required for merging");
            }
            
            // Merge PDFs
            cfpdf(
                action="merge",
                source=arrayToList(sourceFiles),
                destination=outputFile,
                overwrite=true
            );
            
            // Get just the filename for the success message
            var outputFilename = listLast(outputFile, "/\");
            
            return {
                "content": [{
                    "type": "text",
                    "text": "Successfully merged #arrayLen(sourceFiles)# PDFs into: #outputFilename# in temp directory"
                }]
            };
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Error merging PDFs: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private void function validateRequiredParams(required struct args, required array required) {
        for (var param in arguments.required) {
            if (!structKeyExists(arguments.args, param)) {
                throw(type="InvalidParams", message="Missing required parameter: #param#");
            }
            
            // Special handling for arrays
            if (isArray(arguments.args[param])) {
                if (arrayLen(arguments.args[param]) == 0) {
                    throw(type="InvalidParams", message="Empty array for parameter: #param#");
                }
            } else if (isSimpleValue(arguments.args[param]) && len(trim(arguments.args[param])) == 0) {
                throw(type="InvalidParams", message="Empty value for parameter: #param#");
            }
        }
    }
}

/**
 * To register these PDF tools in your Application.cfc:
 * 
 * application.toolRegistry.registerTool("generatePDF", {
 *     "description": "Generate a PDF from HTML content",
 *     "inputSchema": {
 *         "type": "object",
 *         "properties": {
 *             "html": {
 *                 "type": "string",
 *                 "description": "HTML content to convert to PDF"
 *             },
 *             "filename": {
 *                 "type": "string", 
 *                 "description": "Output filename for the PDF"
 *             }
 *         },
 *         "required": ["html", "filename"]
 *     }
 * });
 */