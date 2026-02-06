/**
 * MCPServer.cfc
 * Main MCP Server Orchestrator for ColdFusion 2025
 * Protocol Version: 2025-11-25
 */
component output="false" {

    /**
     * Initialize the MCP Server
     */
    public function init() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("MCPServer init");
        }
        return this;
    }

    /**
     * Process an incoming MCP request
     * @request The JSON-RPC request struct
     * @sessionId The session identifier
     * @return The JSON-RPC response struct
     */
    public struct function processRequest(required struct request, required string sessionId) {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Processing request", {
                sessionId: arguments.sessionId,
                method: arguments.request.method ?: ""
            });
        }
        var handler = new core.JSONRPCHandler();
        var response = handler.process(arguments.request, arguments.sessionId);
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Request processed", {
                sessionId: arguments.sessionId,
                hasError: structKeyExists(response, "error")
            });
        }
        return response;
    }

    /**
     * Register all default tools with the ToolRegistry
     */
    public void function registerDefaultTools() {
        application.logger.info("Starting tool registration");

        var toolClasses = [
            "core.tools.HelloTool",
            "core.tools.PDFTool",
            "core.tools.SendGridEmailTool",
            "core.tools.DatabaseTool",
            "core.tools.FileTool",
            "core.tools.HttpClientTool"
        ];

        var registeredTools = [];
        var failedTools = [];

        for (var toolClass in toolClasses) {
            try {
                application.logger.debug("Registering tool", { class: toolClass });
                var tool = createObject("component", toolClass).init();
                application.toolRegistry.register(tool);
                arrayAppend(registeredTools, tool.getName());
            } catch (any e) {
                arrayAppend(failedTools, { class: toolClass, error: e.message });
                application.logger.warn("Failed to register tool", {
                    class: toolClass,
                    error: e.message
                });
            }
        }

        application.logger.info("Tool registration complete", {
            registered: arrayLen(registeredTools),
            failed: arrayLen(failedTools),
            tools: registeredTools
        });

        if (arrayLen(failedTools) > 0) {
            application.logger.warn("Some tools failed to register", {
                failedTools: failedTools
            });
        }
    }

    /**
     * Register default resources
     */
    public void function registerDefaultResources() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Registering default resources");
        }
        // Server info resource
        application.resourceRegistry.register({
            uri: "mcpcfc://server/info",
            name: "Server Information",
            description: "Information about the MCPCFC server",
            mimeType: "application/json"
        });

        // Configuration resource (sanitized)
        application.resourceRegistry.register({
            uri: "mcpcfc://server/config",
            name: "Server Configuration",
            description: "Current server configuration (sensitive values hidden)",
            mimeType: "application/json"
        });

        application.logger.info("Registered default resources");
    }

    /**
     * Register default prompts
     */
    public void function registerDefaultPrompts() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Registering default prompts");
        }
        // SQL query helper prompt
        application.promptRegistry.register({
            name: "sql_query_helper",
            description: "Helps construct safe SQL SELECT queries",
            arguments: [
                {
                    name: "table",
                    description: "The table name to query",
                    required: true
                },
                {
                    name: "columns",
                    description: "Columns to select (comma-separated)",
                    required: false
                }
            ]
        });

        // Email composer prompt
        application.promptRegistry.register({
            name: "email_composer",
            description: "Helps compose professional emails",
            arguments: [
                {
                    name: "purpose",
                    description: "Purpose of the email (e.g., follow-up, introduction)",
                    required: true
                },
                {
                    name: "tone",
                    description: "Desired tone (formal, casual, friendly)",
                    required: false
                }
            ]
        });

        application.logger.info("Registered default prompts");
    }

    /**
     * Get server status information
     */
    public struct function getStatus() {
        var status = structNew("ordered");
        status["serverName"] = application.config.serverName;
        status["serverVersion"] = application.config.serverVersion;
        status["protocolVersion"] = application.config.protocolVersion;
        status["uptime"] = dateDiff("s", application.startTime, now());
        status["activeSessions"] = application.sessionManager.getSessionCount();
        status["registeredTools"] = application.toolRegistry.getToolCount();
        status["registeredResources"] = application.resourceRegistry.getResourceCount();
        status["registeredPrompts"] = application.promptRegistry.getPromptCount();
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Status requested", status);
        }
        return status;
    }

    /**
     * Shutdown the server gracefully
     */
    public void function shutdown() {
        application.logger.info("MCP Server shutting down");

        // Clean up sessions
        application.sessionManager.clearAll();

        // Stop cleanup thread
        if (structKeyExists(application, "cleanupThreadName")) {
            try {
                cfthread(action="interrupt", name=application.cleanupThreadName);
            } catch (any e) {
                // Thread may already be stopped
                if (structKeyExists(application, "logger")) {
                    application.logger.warn("Cleanup thread interrupt failed", { error: e.message });
                }
            }
        }

        application.logger.info("MCP Server shutdown complete");
    }
}
