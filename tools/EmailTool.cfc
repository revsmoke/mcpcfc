component displayname="EmailTool" {
    
    /**
     * Example ColdFusion MCP Tool using CF's built-in email capabilities
     */
    
    public struct function execute(required struct args) {
        validateRequiredParams(arguments.args, ["to", "subject", "body"]);
        
        try {
            // Use ColdFusion's cfmail tag functionality
            var mailService = new mail();
            mailService.setTo(arguments.args.to);
            mailService.setFrom(arguments.args.from ?: "noreply@example.com");
            mailService.setSubject(arguments.args.subject);
            mailService.setType(arguments.args.type ?: "text");
            
            // Add the body
            mailService.addPart(type=mailService.getType(), body=arguments.args.body);
            
            // Send the email
            mailService.send();
            
            return {
                "content": [{
                    "type": "text",
                    "text": "Email sent successfully to #arguments.args.to#"
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
    
    private void function validateRequiredParams(required struct args, required array required) {
        for (var param in arguments.required) {
            if (!structKeyExists(arguments.args, param) || len(trim(arguments.args[param])) == 0) {
                throw(type="InvalidParams", message="Missing required parameter: #param#");
            }
        }
    }
}