<!--- Example: How to Register Custom Tools in Application.cfc --->

<cfscript>
// Add this to your registerTools() function in Application.cfc

// Email Tool Registration
application.toolRegistry.registerTool("sendEmail", {
    "description": "Send an email using ColdFusion's mail service",
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
                "description": "Email body content"
            },
            "from": {
                "type": "string",
                "description": "Sender email address (optional)"
            },
            "type": {
                "type": "string",
                "enum": ["text", "html"],
                "description": "Email format (optional, defaults to text)"
            }
        },
        "required": ["to", "subject", "body"]
    }
});

// PDF Generation Tool
application.toolRegistry.registerTool("generatePDF", {
    "description": "Generate a PDF document from HTML",
    "inputSchema": {
        "type": "object",
        "properties": {
            "html": {
                "type": "string",
                "description": "HTML content to convert"
            },
            "filename": {
                "type": "string",
                "description": "Output filename"
            }
        },
        "required": ["html", "filename"]
    }
});