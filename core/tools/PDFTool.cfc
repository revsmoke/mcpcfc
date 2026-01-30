/**
 * PDFTool.cfc
 * PDF generation, text extraction, and merging
 * Leverages ColdFusion's built-in PDF capabilities
 */
component extends="AbstractTool" output="false" {

    /**
     * Initialize the tool
     */
    public function init() {
        setName("pdf");
        setTitle("PDF Operations");
        setDescription("Generate PDFs from HTML, extract text from PDFs, or merge multiple PDFs. Uses ColdFusion's powerful built-in PDF engine.");

        setInputSchema({
            type: "object",
            properties: {
                action: {
                    type: "string",
                    enum: ["generate", "extract", "merge", "info"],
                    description: "The PDF operation to perform"
                },
                html: {
                    type: "string",
                    description: "HTML content to convert to PDF (for 'generate' action)"
                },
                filename: {
                    type: "string",
                    description: "Output filename for generated PDF (for 'generate' action)"
                },
                pdfPath: {
                    type: "string",
                    description: "Path to PDF file (for 'extract' and 'info' actions)"
                },
                sourcePaths: {
                    type: "array",
                    items: { type: "string" },
                    description: "Array of PDF paths to merge (for 'merge' action)"
                },
                outputPath: {
                    type: "string",
                    description: "Output path for merged PDF (for 'merge' action)"
                },
                orientation: {
                    type: "string",
                    enum: ["portrait", "landscape"],
                    description: "Page orientation for generated PDF (default: portrait)"
                },
                pageSize: {
                    type: "string",
                    description: "Page size (e.g., 'letter', 'A4') for generated PDF"
                }
            },
            required: ["action"]
        });

        return this;
    }

    /**
     * Execute the PDF operation
     * @toolArgs The tool arguments
     * @return The operation result
     */
    public struct function execute(required struct toolArgs) {
        validateRequired(arguments.toolArgs, ["action"]);

        var action = lCase(arguments.toolArgs.action);

        switch(action) {
            case "generate":
                return generatePDF(arguments.toolArgs);

            case "extract":
                return extractText(arguments.toolArgs);

            case "merge":
                return mergePDFs(arguments.toolArgs);

            case "info":
                return getPDFInfo(arguments.toolArgs);

            default:
                return errorResult("Unknown action: #action#. Valid actions: generate, extract, merge, info");
        }
    }

    /**
     * Generate PDF from HTML content
     */
    private struct function generatePDF(required struct args) {
        validateRequired(arguments.args, ["html", "filename"]);

        var html = arguments.args.html;
        var filename = arguments.args.filename;

        // Ensure filename has .pdf extension
        if (!findNoCase(".pdf", filename)) {
            filename &= ".pdf";
        }

        // Sanitize filename
        filename = reReplace(filename, "[^a-zA-Z0-9._-]", "_", "all");

        // Build path in temp directory
        var tempDir = application.config.tempDirectory;
        var pdfPath = tempDir & filename;

        // Check HTML size
        if (len(html) > application.config.maxPdfSize) {
            return errorResult("HTML content too large. Maximum size: #application.config.maxPdfSize# bytes");
        }

        try {
            // Ensure temp directory exists
            if (!directoryExists(tempDir)) {
                directoryCreate(tempDir);
            }

            // PDF generation options
            var orientation = getParam(arguments.args, "orientation", "portrait");
            var pageSize = getParam(arguments.args, "pageSize", "letter");

            // Generate PDF using ColdFusion's cfdocument
            cfdocument(
                format: "pdf",
                filename: pdfPath,
                overwrite: true,
                orientation: orientation,
                pagetype: pageSize,
                marginTop: "0.5",
                marginBottom: "0.5",
                marginLeft: "0.5",
                marginRight: "0.5"
            ) {
                writeOutput(html);
            }

            // Get file size for confirmation
            var fileInfo = getFileInfo(pdfPath);

            logExecution("PDF generated", {
                filename: filename,
                size: fileInfo.size,
                orientation: orientation
            });

            return textResult("PDF generated successfully: #filename# (#fileInfo.size# bytes) in temp directory");

        } catch (any e) {
            logExecution("PDF generation failed", { error: e.message });
            return errorResult("Failed to generate PDF: #e.message#");
        }
    }

    /**
     * Extract text from a PDF file
     */
    private struct function extractText(required struct args) {
        validateRequired(arguments.args, ["pdfPath"]);

        var pdfPath = resolvePDFPath(arguments.args.pdfPath);

        if (!fileExists(pdfPath)) {
            return errorResult("PDF file not found: #arguments.args.pdfPath#");
        }

        try {
            var extractedText = "";

            cfpdf(
                action: "extracttext",
                source: pdfPath,
                name: "local.pdfText"
            );

            if (isDefined("local.pdfText")) {
                extractedText = local.pdfText;
            }

            // Limit text length
            var maxTextLength = 50000;
            var truncated = false;

            if (len(extractedText) > maxTextLength) {
                extractedText = left(extractedText, maxTextLength);
                truncated = true;
            }

            logExecution("PDF text extracted", {
                pdfPath: arguments.args.pdfPath,
                textLength: len(extractedText),
                truncated: truncated
            });

            var result = "Extracted text from #arguments.args.pdfPath#:\n\n#extractedText#";
            if (truncated) {
                result &= "\n\n[Text truncated - exceeded #maxTextLength# characters]";
            }

            return textResult(result);

        } catch (any e) {
            logExecution("PDF text extraction failed", { error: e.message });
            return errorResult("Failed to extract text: #e.message#");
        }
    }

    /**
     * Merge multiple PDF files
     */
    private struct function mergePDFs(required struct args) {
        validateRequired(arguments.args, ["sourcePaths", "outputPath"]);

        var sourcePaths = arguments.args.sourcePaths;
        var outputPath = arguments.args.outputPath;

        // Validate sourcePaths is an array
        if (!isArray(sourcePaths)) {
            return errorResult("sourcePaths must be an array of file paths");
        }

        if (arrayLen(sourcePaths) < 2) {
            return errorResult("At least 2 PDF files are required for merging");
        }

        // Resolve all source paths
        var resolvedPaths = [];
        for (var path in sourcePaths) {
            var fullPath = resolvePDFPath(path);

            if (!fileExists(fullPath)) {
                return errorResult("Source PDF not found: #path#");
            }

            arrayAppend(resolvedPaths, fullPath);
        }

        // Resolve output path
        var outputFilename = outputPath;
        if (!findNoCase(".pdf", outputFilename)) {
            outputFilename &= ".pdf";
        }
        outputFilename = reReplace(outputFilename, "[^a-zA-Z0-9._-]", "_", "all");

        var outputFullPath = application.config.tempDirectory & outputFilename;

        try {
            cfpdf(
                action: "merge",
                source: arrayToList(resolvedPaths),
                destination: outputFullPath,
                overwrite: true
            );

            var fileInfo = getFileInfo(outputFullPath);

            logExecution("PDFs merged", {
                sourceCount: arrayLen(resolvedPaths),
                outputFile: outputFilename,
                size: fileInfo.size
            });

            return textResult("Successfully merged #arrayLen(resolvedPaths)# PDFs into: #outputFilename# (#fileInfo.size# bytes)");

        } catch (any e) {
            logExecution("PDF merge failed", { error: e.message });
            return errorResult("Failed to merge PDFs: #e.message#");
        }
    }

    /**
     * Get information about a PDF file
     */
    private struct function getPDFInfo(required struct args) {
        validateRequired(arguments.args, ["pdfPath"]);

        var pdfPath = resolvePDFPath(arguments.args.pdfPath);

        if (!fileExists(pdfPath)) {
            return errorResult("PDF file not found: #arguments.args.pdfPath#");
        }

        try {
            cfpdf(
                action: "getinfo",
                source: pdfPath,
                name: "local.pdfInfo"
            );

            var info = {
                path: arguments.args.pdfPath,
                pageCount: local.pdfInfo.totalPages ?: 0,
                title: local.pdfInfo.title ?: "",
                author: local.pdfInfo.author ?: "",
                subject: local.pdfInfo.subject ?: "",
                keywords: local.pdfInfo.keywords ?: "",
                creator: local.pdfInfo.creator ?: "",
                producer: local.pdfInfo.producer ?: "",
                created: local.pdfInfo.created ?: "",
                modified: local.pdfInfo.modified ?: "",
                version: local.pdfInfo.pdfversion ?: ""
            };

            // Add file size
            var fileInfo = getFileInfo(pdfPath);
            info.fileSize = fileInfo.size;

            logExecution("PDF info retrieved", { pdfPath: arguments.args.pdfPath });

            return jsonResult(info);

        } catch (any e) {
            logExecution("PDF info retrieval failed", { error: e.message });
            return errorResult("Failed to get PDF info: #e.message#");
        }
    }

    /**
     * Resolve a PDF path (handle relative paths)
     */
    private string function resolvePDFPath(required string path) {
        var pdfPath = arguments.path;

        // If not an absolute path, assume it's relative to temp directory
        if (left(pdfPath, 1) != "/" && !findNoCase(":\", pdfPath)) {
            pdfPath = application.config.tempDirectory & pdfPath;
        } else {
            pdfPath = expandPath(pdfPath);
        }

        return pdfPath;
    }
}
