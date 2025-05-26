component displayname="EmailTool" {
    
    /**
     * ColdFusion MCP Email Tool - Provides email functionality
     */
    
    public struct function executeTool(required string toolName, required struct args) {
        switch(arguments.toolName) {
            case "sendEmail":
                return sendEmail(arguments.args);
            case "sendHTMLEmail":
                return sendHTMLEmail(arguments.args);
            case "validateEmailAddress":
                return validateEmailAddress(arguments.args);
            default:
                return {
                    "content": [{
                        "type": "text",
                        "text": "Unknown email tool: #arguments.toolName#"
                    }],
                    "isError": true
                };
        }
    }
    
    private struct function sendEmail(required struct args) {
        validateRequiredParams(arguments.args, ["to", "subject", "body"]);
        
        try {
            // Use ColdFusion's cfmail tag functionality
            var mailService = new mail();
            mailService.setTo(arguments.args.to);
            mailService.setFrom(arguments.args.from ?: "mcpcfc@example.com");
            mailService.setSubject(arguments.args.subject);
            mailService.setType("text");
            
            // Optional CC and BCC
            if (structKeyExists(arguments.args, "cc") && len(trim(arguments.args.cc))) {
                mailService.setCc(arguments.args.cc);
            }
            if (structKeyExists(arguments.args, "bcc") && len(trim(arguments.args.bcc))) {
                mailService.setBcc(arguments.args.bcc);
            }
            
            // Add the body
            mailService.addPart(type="text", body=arguments.args.body);
            
            // For testing, we'll just simulate sending
            // In production, uncomment the next line:
            // mailService.send();
            
            return {
                "content": [{
                    "type": "text",
                    "text": "Email simulated successfully! (In production, would send to: #arguments.args.to#)<br>Subject: #arguments.args.subject#<br>From: #mailService.getFrom()#"
                }]
            };
            
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Failed to send email: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private struct function sendHTMLEmail(required struct args) {
        validateRequiredParams(arguments.args, ["to", "subject", "htmlBody"]);
        
        try {
            // Use ColdFusion's cfmail tag functionality
            var mailService = new mail();
            mailService.setTo(arguments.args.to);
            mailService.setFrom(arguments.args.from ?: "mcpcfc@example.com");
            mailService.setSubject(arguments.args.subject);
            mailService.setType("html");
            
            // Optional CC and BCC
            if (structKeyExists(arguments.args, "cc") && len(trim(arguments.args.cc))) {
                mailService.setCc(arguments.args.cc);
            }
            if (structKeyExists(arguments.args, "bcc") && len(trim(arguments.args.bcc))) {
                mailService.setBcc(arguments.args.bcc);
            }
            
            // Add HTML body
            mailService.addPart(type="html", body=arguments.args.htmlBody);
            
            // Add optional plain text alternative
            if (structKeyExists(arguments.args, "textBody") && len(trim(arguments.args.textBody))) {
                mailService.addPart(type="text", body=arguments.args.textBody);
            }
            
            // For testing, we'll just simulate sending
            // In production, uncomment the next line:
            // mailService.send();
            
            return {
                "content": [{
                    "type": "text",
                    "text": "HTML email simulated successfully! (In production, would send to: #arguments.args.to#)<br>Subject: #arguments.args.subject#<br>Type: HTML"
                }]
            };
            
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Failed to send HTML email: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private struct function validateEmailAddress(required struct args) {
        validateRequiredParams(arguments.args, ["email"]);
        
        try {
            var email = trim(arguments.args.email);
            var isValid = false;
            var message = "";
            
            // Basic email validation regex
            var emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$";
            
            if (len(email) == 0) {
                message = "Email address is empty";
            } else if (reFindNoCase(emailRegex, email)) {
                isValid = true;
                message = "Email address '#email#' is valid";
            } else {
                message = "Email address '#email#' is not valid";
            }
            
            return {
                "content": [{
                    "type": "text",
                    "text": message & "<br>Valid: #isValid#"
                }]
            };
            
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Error validating email: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private void function validateRequiredParams(required struct args, required array required) {
        for (var param in arguments.required) {
            if (!structKeyExists(arguments.args, param) || len(trim(arguments.args[param])) == 0) {
                throw(type="InvalidParams", message="Missing required parameter: #param#");
            }
        }
    }
}