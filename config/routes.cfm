<cfscript>
/**
 * MCPCFC Method Routing Configuration
 * Maps JSON-RPC methods to their handlers
 */

application.routes = {
    // Core MCP methods
    methods: {
        "initialize": {
            handler: "core.JSONRPCHandler",
            method: "handleInitialize",
            requiresSession: false
        },
        "tools/list": {
            handler: "registry.ToolRegistry",
            method: "listTools",
            requiresSession: true
        },
        "tools/call": {
            handler: "core.JSONRPCHandler",
            method: "handleToolCall",
            requiresSession: true
        },
        "resources/list": {
            handler: "registry.ResourceRegistry",
            method: "list",
            requiresSession: true
        },
        "resources/read": {
            handler: "registry.ResourceRegistry",
            method: "read",
            requiresSession: true
        },
        "prompts/list": {
            handler: "registry.PromptRegistry",
            method: "list",
            requiresSession: true
        },
        "prompts/get": {
            handler: "registry.PromptRegistry",
            method: "get",
            requiresSession: true
        },
        "ping": {
            handler: "core.JSONRPCHandler",
            method: "handlePing",
            requiresSession: false
        },
        "completion/complete": {
            handler: "core.JSONRPCHandler",
            method: "handleCompletion",
            requiresSession: true
        }
    },

    // Notifications (no response expected)
    notifications: [
        "notifications/initialized",
        "notifications/progress",
        "notifications/cancelled"
    ]
};
</cfscript>
