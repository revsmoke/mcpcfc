component extends="BaseTool" displayname="InstanceBridge" hint="Manages Claude-to-Claude instance connections" {
    
    /**
     * Initialize the Instance Bridge
     */
    public InstanceBridge function init() {
        // Ensure instance registry exists in application scope
        if (!structKeyExists(application, "instanceRegistry")) {
            application.instanceRegistry = structNew("ordered");
        }
        return this;
    }
    
    /**
     * Register this Claude instance
     */
    public struct function registerInstance(
        required string instanceId,
        required string instanceName,
        struct capabilities = {}
    ) {
        try {
            var instanceData = {
                "id": arguments.instanceId,
                "name": arguments.instanceName,
                "capabilities": arguments.capabilities,
                "registeredAt": now(),
                "lastHeartbeat": now(),
                "status": "active",
                "protocolVersion": "1.0"
            };
            
            // Thread-safe registration
            lock name="instanceRegistry" timeout="5" type="exclusive" {
                application.instanceRegistry[arguments.instanceId] = instanceData;
            }
            
            // Log the registration
            writeLog(
                text="Instance registered: #arguments.instanceName# (#arguments.instanceId#)",
                type="information",
                application=true
            );
            
            return createMCPResponse("Instance registered successfully. ∞→∞ Connection established!");
            
        } catch (any e) {
            return createErrorResponse("Failed to register instance: #e.message#");
        }
    }
    
    /**
     * Get list of active instances
     */
    public struct function getActiveInstances() {
        try {
            var activeInstances = [];
            var now = now();
            
            lock name="instanceRegistry" timeout="5" type="readonly" {
                for (var instanceId in application.instanceRegistry) {
                    var instance = application.instanceRegistry[instanceId];
                    // Consider instance active if heartbeat within last 5 minutes
                    var minutesSinceHeartbeat = dateDiff("n", instance.lastHeartbeat, now);
                    if (minutesSinceHeartbeat <= 5) {
                        arrayAppend(activeInstances, instance);
                    }
                }
            }
            
            return createMCPResponse({
                "instances": activeInstances,
                "count": arrayLen(activeInstances),
                "timestamp": now
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to get active instances: #e.message#");
        }
    }
    
    /**
     * Send heartbeat for this instance
     */
    public struct function heartbeat(required string instanceId) {
        try {
            lock name="instanceRegistry" timeout="5" type="exclusive" {
                if (structKeyExists(application.instanceRegistry, arguments.instanceId)) {
                    application.instanceRegistry[arguments.instanceId].lastHeartbeat = now();
                    return createMCPResponse("💫✨ Heartbeat acknowledged");
                } else {
                    return createErrorResponse("Instance not found");
                }
            }
        } catch (any e) {
            return createErrorResponse("Heartbeat failed: #e.message#");
        }
    }
    
    /**
     * Deregister an instance
     */
    public struct function deregisterInstance(required string instanceId) {
        try {
            lock name="instanceRegistry" timeout="5" type="exclusive" {
                if (structKeyExists(application.instanceRegistry, arguments.instanceId)) {
                    structDelete(application.instanceRegistry, arguments.instanceId);
                    return createMCPResponse("Instance deregistered. Until we meet again! 🌌");
                } else {
                    return createErrorResponse("Instance not found");
                }
            }
        } catch (any e) {
            return createErrorResponse("Failed to deregister: #e.message#");
        }
    }
    
    /**
     * Get the tool definition for MCP
     */
    public array function getToolDefinitions() {
        return [
            {
                name = "registerInstance",
                description = "Register a Claude instance for communication",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Unique identifier for this instance"
                        },
                        instanceName = {
                            type = "string",
                            description = "Friendly name for this instance"
                        },
                        capabilities = {
                            type = "object",
                            description = "Optional capabilities of this instance",
                            default = {}
                        }
                    },
                    required = ["instanceId", "instanceName"]
                }
            },
            {
                name = "getActiveInstances",
                description = "Get list of all active Claude instances",
                inputSchema = {
                    type = "object",
                    properties = {}
                }
            },
            {
                name = "heartbeat",
                description = "Send heartbeat to maintain active status",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Instance ID sending heartbeat"
                        }
                    },
                    required = ["instanceId"]
                }
            },
            {
                name = "deregisterInstance",
                description = "Deregister an instance from the bridge",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Instance ID to deregister"
                        }
                    },
                    required = ["instanceId"]
                }
            }
        ];
    }
}