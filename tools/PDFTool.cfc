component displayname="PDFTool" extends="components.ToolHandler" {
    
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
                    return super.executeTool(arguments.toolName, arguments.args);
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
        
        var pdfPath = expandPath("./temp/#arguments.args.filename#");
        
        // Use ColdFusion's built-in PDF generation
        cfdocument(
            format="pdf",
            filename=pdfPath,
            overwrite=true
        ) {
            writeOutput(arguments.args.html);
        }
        
        return {
            "content": [{
                "type": "text",
                "text": "PDF generated successfully at: #pdfPath#"
            }]
        };
    }
    
    private struct function extractTextFromPDF(required struct args) {
        validateRequiredParams(arguments.args, ["pdfPath"]);
        
        var pdfFile = expandPath(arguments.args.pdfPath);
        
        // Extract text from PDF
        cfpdf(
            action="extracttext",
            source=pdfFile,
            name="extractedText"
        );
        
        return {
            "content": [{
                "type": "text", 
                "text": extractedText
            }]
        };
    }
    
    private struct function mergePDFFiles(required struct args) {
        validateRequiredParams(arguments.args, ["sourcePaths", "outputPath"]);
        
        var outputFile = expandPath(arguments.args.outputPath);
        var sourceFiles = arguments.args.sourcePaths.map(function(path) {
            return expandPath(path);
        });
        
        // Merge PDFs
        cfpdf(
            action="merge",
            source=arrayToList(sourceFiles),
            destination=outputFile,
            overwrite=true
        );
        
        return {
            "content": [{
                "type": "text",
                "text": "Successfully merged #arrayLen(sourceFiles)# PDFs into: #outputFile#"
            }]
        };
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