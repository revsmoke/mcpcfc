/**
 * SendGridEmailTool.cfc
 * Send emails via SendGrid API
 * Requires SENDGRID_API_KEY environment variable
 */
component extends="AbstractTool" output="false" {

    /**
     * Initialize the tool
     */
    public function init() {
        setName("sendEmail");
        setTitle("Send Email");
        setDescription("Send an email via SendGrid API. Supports plain text and HTML content.");

        setInputSchema({
            type: "object",
            properties: {
                to: {
                    type: "string",
                    description: "Recipient email address"
                },
                subject: {
                    type: "string",
                    description: "Email subject line"
                },
                body: {
                    type: "string",
                    description: "Email body (plain text)"
                },
                htmlBody: {
                    type: "string",
                    description: "HTML body (optional, in addition to plain text)"
                },
                from: {
                    type: "string",
                    description: "Sender email address (optional, uses default if not provided)"
                },
                fromName: {
                    type: "string",
                    description: "Sender display name (optional)"
                },
                cc: {
                    type: "string",
                    description: "CC email address (optional)"
                },
                bcc: {
                    type: "string",
                    description: "BCC email address (optional)"
                },
                replyTo: {
                    type: "string",
                    description: "Reply-To email address (optional)"
                }
            },
            required: ["to", "subject", "body"]
        });

        return this;
    }

    /**
     * Execute the email send
     * @toolArgs The tool arguments
     * @return The result
     */
    public struct function execute(required struct toolArgs) {
        validateRequired(arguments.toolArgs, ["to", "subject", "body"]);

        logExecution("Email send requested", {
            to: arguments.toolArgs.to,
            subjectLength: len(arguments.toolArgs.subject),
            bodyLength: len(arguments.toolArgs.body)
        });

        // Get API key from config
        var apiKey = application.config.sendGridApiKey ?: "";
        if (!len(apiKey)) {
            logExecution("SendGrid API key missing");
            return errorResult("SendGrid API key not configured. Set SENDGRID_API_KEY environment variable.");
        }

        // Validate email addresses
        var validator = new validators.InputValidator();

        if (!validator.isValidEmail(arguments.toolArgs.to)) {
            logExecution("Invalid recipient email", { to: arguments.toolArgs.to });
            return errorResult("Invalid recipient email address: #arguments.toolArgs.to#");
        }

        // Get sender info
        var fromEmail = getParam(arguments.toolArgs, "from", application.config.defaultFromEmail);
        var fromName = getParam(arguments.toolArgs, "fromName", application.config.defaultFromName);

        if (!validator.isValidEmail(fromEmail)) {
            logExecution("Invalid sender email", { from: fromEmail });
            return errorResult("Invalid sender email address: #fromEmail#");
        }

        // Build SendGrid API payload
        var payload = buildPayload(arguments.toolArgs, fromEmail, fromName);
        logExecution("SendGrid payload built", {
            to: arguments.toolArgs.to,
            hasHtml: structKeyExists(arguments.toolArgs, "htmlBody") && len(arguments.toolArgs.htmlBody)
        });

        try {
            var result = sendViaSendGrid(payload, apiKey);
            return result;

        } catch (any e) {
            logExecution("Email send failed", { error: e.message });
            return errorResult("Failed to send email: #e.message#");
        }
    }

    /**
     * Build the SendGrid API payload
     */
    private struct function buildPayload(
        required struct args,
        required string fromEmail,
        required string fromName
    ) {
        var payload = structNew("ordered");

        // Personalizations (recipients)
        var personalization = structNew("ordered");
        personalization["to"] = [{ email: arguments.args.to }];

        // Add CC if provided
        if (structKeyExists(arguments.args, "cc") && len(arguments.args.cc)) {
            personalization["cc"] = [{ email: arguments.args.cc }];
        }

        // Add BCC if provided
        if (structKeyExists(arguments.args, "bcc") && len(arguments.args.bcc)) {
            personalization["bcc"] = [{ email: arguments.args.bcc }];
        }

        payload["personalizations"] = [personalization];

        // From address
        payload["from"] = structNew("ordered");
        payload.from["email"] = arguments.fromEmail;
        if (len(arguments.fromName)) {
            payload.from["name"] = arguments.fromName;
        }

        // Reply-To if provided
        if (structKeyExists(arguments.args, "replyTo") && len(arguments.args.replyTo)) {
            payload["reply_to"] = { email: arguments.args.replyTo };
        }

        // Subject
        payload["subject"] = arguments.args.subject;

        // Content
        payload["content"] = [];

        // Always include plain text
        arrayAppend(payload.content, {
            type: "text/plain",
            value: arguments.args.body
        });

        // Add HTML if provided
        if (structKeyExists(arguments.args, "htmlBody") && len(arguments.args.htmlBody)) {
            arrayAppend(payload.content, {
                type: "text/html",
                value: arguments.args.htmlBody
            });
        }

        return payload;
    }

    /**
     * Send the email via SendGrid API
     */
    private struct function sendViaSendGrid(required struct payload, required string apiKey) {
        var apiUrl = application.config.sendGridApiUrl;

        cfhttp(
            url: apiUrl,
            method: "POST",
            result: "httpResult",
            timeout: 30
        ) {
            cfhttpparam(type: "header", name: "Authorization", value: "Bearer #arguments.apiKey#");
            cfhttpparam(type: "header", name: "Content-Type", value: "application/json");
            cfhttpparam(type: "body", value: serializeJson(arguments.payload));
        }

        var statusCode = val(listFirst(httpResult.statusCode, " "));

        // SendGrid returns 202 for successful queued emails
        if (statusCode == 202 || statusCode == 200) {
            logExecution("Email sent successfully", {
                to: arguments.payload.personalizations[1].to[1].email,
                subject: arguments.payload.subject
            });

            return textResult("Email sent successfully to #arguments.payload.personalizations[1].to[1].email#");
        }

        // Handle errors
        var errorDetail = "";
        if (len(httpResult.fileContent)) {
            try {
                var errorResponse = deserializeJson(httpResult.fileContent);
                if (structKeyExists(errorResponse, "errors") && isArray(errorResponse.errors)) {
                    errorDetail = errorResponse.errors.map(function(e) {
                        return e.message ?: "";
                    }).toList("; ");
                }
            } catch (any e) {
                errorDetail = httpResult.fileContent;
            }
        }

        logExecution("SendGrid API error", {
            statusCode: statusCode,
            error: errorDetail
        });

        return errorResult("SendGrid API error (#statusCode#): #errorDetail#");
    }
}
