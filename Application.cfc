component output="false" hint="Application component for MCP Server" {
    
    this.name = "MCPServer"; //cflint ignore:GLOBAL_VAR
    this.applicationTimeout = createTimeSpan(1, 0, 0, 0);
    this.sessionManagement = false;
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
    }
}