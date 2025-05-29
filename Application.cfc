component output="false" hint="Application component for MCP Server" {
    
    this.name = "MCPServer"; //cflint ignore:GLOBAL_VAR
    this.applicationTimeout = createTimeSpan(1, 0, 0, 0);
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 30, 0); // 30 minute session timeout
    /**
     * Application start handler
     */
    public void function onApplicationStart() {
        // Initialize thread-safe message queue
        application.messageQueue = createObject("java", "java.util.concurrent.LinkedBlockingQueue").init(); //cflint ignore:GLOBAL_VAR
        
        // Initialize session manager
        application.sessionManager = new components.SessionManager();
        
        // Initialize tool registry
        application.toolRegistry = new components.ToolRegistry();
        
        // Register default tools
        registerTools();
    }
    
    /**
     * Application end handler - cleanup resources
     */
    public void function onApplicationEnd() {
        // Clean up any active file watcher threads
        if (structKeyExists(application, "fileWatchers")) {
            for (var watcherId in application.fileWatchers) {
                try {
                    // Mark as inactive
                    application.fileWatchers[watcherId].active = false;
                    
                    // Terminate the thread
                    cfthread(action="terminate", name=watcherId);
                    
                    writeLog(
                        text="Terminated file watcher thread on application shutdown: " & watcherId,
                        type="information",
                        application=true
                    );
                } catch (any e) {
                    // Thread might have already stopped
                    writeLog(
                        text="Could not terminate file watcher thread: " & watcherId & " - " & e.message,
                        type="warning",
                        application=true
                    );
                }
            }
            
            // Clear the watchers struct
            structClear(application.fileWatchers);
        }
        
        // Log application shutdown
        writeLog(
            text="MCP Server application shutting down",
            type="information",
            application=true
        );
    }
    
    /**
     * Register default tools
     */
    private void function registerTools() {
        // Register hello world tool
        application.toolRegistry.registerTool("hello", { //cflint ignore:GLOBAL_VAR
            "description": "A simple hello world tool",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Name to greet"
                    }
                },
                "required": ["name"]
            }
        });
        
        // Register database query tool
        application.toolRegistry.registerTool("queryDatabase", {
            "description": "Execute a database query",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "SQL query to execute"
                    },
                    "datasource": {
                        "type": "string",
                        "description": "Database datasource name"
                    }
                },
                "required": ["query", "datasource"]
            }
        });
        
        // Register PDF generation tool
        application.toolRegistry.registerTool("generatePDF", {
            "description": "Generate a PDF from HTML content",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "html": {
                        "type": "string",
                        "description": "HTML content to convert to PDF"
                    },
                    "filename": {
                        "type": "string",
                        "description": "Output filename for the PDF (e.g., 'report.pdf')"
                    }
                },
                "required": ["html", "filename"]
            }
        });
        
        // Register PDF text extraction tool
        application.toolRegistry.registerTool("extractPDFText", {
            "description": "Extract text content from a PDF file",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "pdfPath": {
                        "type": "string",
                        "description": "Path to the PDF file (relative to temp directory)"
                    }
                },
                "required": ["pdfPath"]
            }
        });
        
        // Register PDF merge tool
        application.toolRegistry.registerTool("mergePDFs", {
            "description": "Merge multiple PDF files into one",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "sourcePaths": {
                        "type": "array",
                        "items": {
                            "type": "string"
                        },
                        "description": "Array of paths to PDF files to merge"
                    },
                    "outputPath": {
                        "type": "string",
                        "description": "Output path for the merged PDF"
                    }
                },
                "required": ["sourcePaths", "outputPath"]
            }
        });
        
        // Register email sending tool
        application.toolRegistry.registerTool("sendEmail", {
            "description": "Send a plain text email",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "to": {
                        "type": "string",
                        "description": "Recipient email address"
                    },
                    "subject": {
                        "type": "string",
                        "description": "Email subject line"
                    },
                    "body": {
                        "type": "string",
                        "description": "Plain text email body"
                    },
                    "from": {
                        "type": "string",
                        "description": "Sender email address (optional, defaults to mcpcfc@example.com)"
                    },
                    "cc": {
                        "type": "string",
                        "description": "CC recipients (optional)"
                    },
                    "bcc": {
                        "type": "string",
                        "description": "BCC recipients (optional)"
                    }
                },
                "required": ["to", "subject", "body"]
            }
        });
        
        // Register HTML email tool
        application.toolRegistry.registerTool("sendHTMLEmail", {
            "description": "Send an HTML formatted email",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "to": {
                        "type": "string",
                        "description": "Recipient email address"
                    },
                    "subject": {
                        "type": "string",
                        "description": "Email subject line"
                    },
                    "htmlBody": {
                        "type": "string",
                        "description": "HTML email body"
                    },
                    "textBody": {
                        "type": "string",
                        "description": "Plain text alternative (optional)"
                    },
                    "from": {
                        "type": "string",
                        "description": "Sender email address (optional, defaults to mcpcfc@example.com)"
                    },
                    "cc": {
                        "type": "string",
                        "description": "CC recipients (optional)"
                    },
                    "bcc": {
                        "type": "string",
                        "description": "BCC recipients (optional)"
                    }
                },
                "required": ["to", "subject", "htmlBody"]
            }
        });
        
        // Register email validation tool
        application.toolRegistry.registerTool("validateEmailAddress", {
            "description": "Validate an email address format",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "email": {
                        "type": "string",
                        "description": "Email address to validate"
                    }
                },
                "required": ["email"]
            }
        });
        
        // Register CLI tools (CF2023 enhancement tools)
        
        // Register REPL tools
try {
     var replTool = new mcpcfc.clitools.REPLTool();
     var replTools = replTool.getToolDefinitions();
    
    // Validate tool definitions structure
    if (!isArray(replTools)) {
        throw(message="getToolDefinitions() must return an array", type="ValidationError");
    }
    
     for (var tool in replTools) {
        // Validate required tool properties
        if (!structKeyExists(tool, "name") || !structKeyExists(tool, "description") || !structKeyExists(tool, "inputSchema")) {
            writeLog(text="Skipping invalid REPL tool definition: missing required properties", type="warning");
            continue;
        }
        
         application.toolRegistry.registerTool(tool.name, {
             "description": tool.description,
             "inputSchema": tool.inputSchema
         });
     }
 } catch (any e) {
     writeLog(text="Failed to register REPL tools: " & e.message, type="error");
 }
        
// Register server management tools
         try {
             var serverTool = new mcpcfc.clitools.ServerManagementTool();
             var serverTools = serverTool.getToolDefinitions();
            
            // Validate tool definitions structure
            if (!isArray(serverTools)) {
                throw(message="getToolDefinitions() must return an array", type="ValidationError");
            }
            
             for (var tool in serverTools) {
                // Validate required tool properties
                if (!structKeyExists(tool, "name") || !structKeyExists(tool, "description") || !structKeyExists(tool, "inputSchema")) {
                    writeLog(text="Skipping invalid server tool definition: missing required properties", type="warning");
                    continue;
                }
                
                 application.toolRegistry.registerTool(tool.name, {
                     "description": tool.description,
                     "inputSchema": tool.inputSchema
                 });
             }
         } catch (any e) {
             writeLog(text="Failed to register server management tools: " & e.message, type="error");
         }

// Register package management tools  
 try {
     var packageTool = new mcpcfc.clitools.PackageManagerTool();
     var packageTools = packageTool.getToolDefinitions();
    
    // Validate tool definitions structure
    if (!isArray(packageTools)) {
        throw(message="getToolDefinitions() must return an array", type="ValidationError");
    }
    
     for (var tool in packageTools) {
        // Validate required tool properties
        if (!structKeyExists(tool, "name") || !structKeyExists(tool, "description") || !structKeyExists(tool, "inputSchema")) {
            writeLog(text="Skipping invalid package tool definition: missing required properties", type="warning");
            continue;
        }
        
         application.toolRegistry.registerTool(tool.name, {
             "description": tool.description,
             "inputSchema": tool.inputSchema
         });
     }
 } catch (any e) {
     writeLog(text="Failed to register package management tools: " & e.message, type="error");
 }

 // Register development workflow tools
 try {
     var devTool = new mcpcfc.clitools.DevWorkflowTool();
     var devTools = devTool.getToolDefinitions();
    
    // Validate tool definitions structure
    if (!isArray(devTools)) {
        throw(message="getToolDefinitions() must return an array", type="ValidationError");
    }
    
     for (var tool in devTools) {
        // Validate required tool properties
        if (!structKeyExists(tool, "name") || !structKeyExists(tool, "description") || !structKeyExists(tool, "inputSchema")) {
            writeLog(text="Skipping invalid dev tool definition: missing required properties", type="warning");
            continue;
        }
        
         application.toolRegistry.registerTool(tool.name, {
             "description": tool.description,
             "inputSchema": tool.inputSchema
         });
     }
 } catch (any e) {
     writeLog(text="Failed to register development workflow tools: " & e.message, type="error");
 }
    }
}