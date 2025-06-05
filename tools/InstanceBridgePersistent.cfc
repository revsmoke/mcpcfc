component extends="BaseTool" displayname="InstanceBridgePersistent" hint="Persistent Claude instance connections with reconnection support" {
    
    /**
     * Initialize the Persistent Instance Bridge
     */
    public InstanceBridgePersistent function init() {
        // Ensure instance registry exists (for backward compatibility)
        if (!structKeyExists(application, "instanceRegistry")) {
            application.instanceRegistry = structNew("ordered");
        }
        
        // Sync database state to memory on startup
        syncDatabaseToMemory();
        
        return this;
    }
    
    /**
     * Register or reconnect a Claude instance
     */
    public struct function registerInstance(
        required string instanceId,
        required string instanceName,
        struct capabilities = {},
        string connectionToken = "",
        boolean attemptReconnect = true
    ) {
        try {
            var reconnectionResult = {};
            var generation = 1;
            var parentInstanceId = "";
            
            // Check for reconnection possibility
            if (arguments.attemptReconnect) {
                reconnectionResult = checkForReconnection(
                    arguments.instanceId, 
                    arguments.instanceName,
                    arguments.connectionToken
                );
                
                if (reconnectionResult.canReconnect) {
                    generation = reconnectionResult.nextGeneration;
                    parentInstanceId = reconnectionResult.parentInstanceId;
                }
            }
            
            // Generate connection token if not provided
            if (!len(arguments.connectionToken)) {
                arguments.connectionToken = hash(arguments.instanceId & now() & createUUID());
            }
            
            // Create instance data
            var instanceData = {
                "id": arguments.instanceId,
                "name": arguments.instanceName,
                "capabilities": serializeJSON(arguments.capabilities),
                "registeredAt": now(),
                "lastHeartbeat": now(),
                "status": "active",
                "protocolVersion": "1.0",
                "generation": generation,
                "parentInstanceId": parentInstanceId,
                "connectionToken": arguments.connectionToken
            };
            
            // Store in database
            queryExecute("
                INSERT INTO instance_registrations 
                (id, name, capabilities, registered_at, last_heartbeat, status, 
                 protocol_version, generation, parent_instance_id, connection_token)
                VALUES 
                (:id, :name, :capabilities, :registeredAt, :lastHeartbeat, :status,
                 :protocolVersion, :generation, :parentInstanceId, :connectionToken)
                ON DUPLICATE KEY UPDATE
                    name = VALUES(name),
                    capabilities = VALUES(capabilities),
                    last_heartbeat = VALUES(last_heartbeat),
                    status = VALUES(status),
                    generation = VALUES(generation),
                    connection_token = VALUES(connection_token)
            ", instanceData, {datasource: "mcpcfc_ds"});
            
            // Update memory cache
            lock name="instanceRegistry" timeout="5" type="exclusive" {
                application.instanceRegistry[arguments.instanceId] = instanceData;
            }
            
            // Log the registration
            writeLog(
                text="Instance registered: #arguments.instanceName# (#arguments.instanceId#) Gen:#generation#",
                type="information",
                application=true
            );
            
            // Prepare response
            var response = {
                "status": "Instance registered successfully",
                "instanceId": arguments.instanceId,
                "generation": generation,
                "connectionToken": arguments.connectionToken
            };
            
            if (reconnectionResult.canReconnect) {
                response.reconnected = true;
                response.previousGeneration = reconnectionResult.previousGeneration;
                response.messageHistory = getMessageHistory(arguments.instanceId, parentInstanceId);
                response.status = "Instance reconnected! Generation #generation# ∞→∞ Previous conversations restored!";
            } else {
                response.status = "New instance registered! ∞→∞ Connection established!";
            }
            
            return createMCPResponse(response);
            
        } catch (any e) {
            return createErrorResponse("Failed to register instance: #e.message#");
        }
    }
    
    /**
     * Check if instance can reconnect to previous session
     */
    private struct function checkForReconnection(
        required string instanceId,
        required string instanceName,
        string connectionToken = ""
    ) {
        try {
            // Look for recent instances with similar ID or name
            var recentInstances = queryExecute("
                SELECT id, name, generation, connection_token, 
                       TIMESTAMPDIFF(MINUTE, last_heartbeat, NOW()) as minutes_inactive
                FROM instance_registrations
                WHERE (id = :instanceId OR name LIKE :nameLike)
                  AND status = 'active'
                  AND TIMESTAMPDIFF(MINUTE, last_heartbeat, NOW()) < 30
                ORDER BY generation DESC
                LIMIT 1
            ", {
                instanceId: arguments.instanceId,
                nameLike: "%#arguments.instanceName#%"
            }, {datasource: "mcpcfc_ds"});
            
            if (recentInstances.recordCount > 0) {
                // Validate connection token if provided
                if (len(arguments.connectionToken) && 
                    arguments.connectionToken == recentInstances.connection_token) {
                    return {
                        canReconnect: true,
                        parentInstanceId: recentInstances.id,
                        previousGeneration: recentInstances.generation,
                        nextGeneration: recentInstances.generation + 1
                    };
                } else if (recentInstances.minutes_inactive < 5) {
                    // Very recent activity, likely same session
                    return {
                        canReconnect: true,
                        parentInstanceId: recentInstances.id,
                        previousGeneration: recentInstances.generation,
                        nextGeneration: recentInstances.generation + 1
                    };
                }
            }
            
            return {canReconnect: false};
            
        } catch (any e) {
            return {canReconnect: false, error: e.message};
        }
    }
    
    /**
     * Get message history for an instance (including parent generations)
     */
    public struct function getMessageHistory(
        required string instanceId,
        string parentInstanceId = "",
        numeric limit = 100
    ) {
        try {
            var messages = [];
            
            // Get all related instance IDs (current + parents)
            var instanceIds = [arguments.instanceId];
            if (len(arguments.parentInstanceId)) {
                arrayAppend(instanceIds, arguments.parentInstanceId);
                
                // Get full lineage
                var lineage = queryExecute("
                    WITH RECURSIVE instance_lineage AS (
                        SELECT id, parent_instance_id 
                        FROM instance_registrations 
                        WHERE id = :parentId
                        
                        UNION ALL
                        
                        SELECT i.id, i.parent_instance_id
                        FROM instance_registrations i
                        INNER JOIN instance_lineage il ON i.id = il.parent_instance_id
                    )
                    SELECT id FROM instance_lineage
                ", {parentId: arguments.parentInstanceId}, {datasource: "mcpcfc_ds"});
                
                for (var row in lineage) {
                    if (!arrayContains(instanceIds, row.id)) {
                        arrayAppend(instanceIds, row.id);
                    }
                }
            }
            
            // Get messages
            var messageQuery = queryExecute("
                SELECT id, from_instance_id, to_instance_id, message, 
                       message_type, metadata, timestamp, status
                FROM instance_messages
                WHERE from_instance_id IN (:instanceIds)
                   OR to_instance_id IN (:instanceIds)
                ORDER BY timestamp DESC
                LIMIT :limit
            ", {
                instanceIds: arrayToList(instanceIds),
                limit: arguments.limit
            }, {datasource: "mcpcfc_ds"});
            
            // Convert to array
            for (var row in messageQuery) {
                var msg = {
                    "id": row.id,
                    "from": row.from_instance_id,
                    "to": row.to_instance_id,
                    "message": row.message,
                    "messageType": row.message_type,
                    "metadata": isJSON(row.metadata) ? deserializeJSON(row.metadata) : {},
                    "timestamp": row.timestamp,
                    "status": row.status
                };
                arrayAppend(messages, msg);
            }
            
            return createMCPResponse({
                "messages": messages,
                "count": arrayLen(messages),
                "instanceLineage": instanceIds
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to get message history: #e.message#");
        }
    }
    
    /**
     * Enhanced heartbeat with database update
     */
    public struct function heartbeat(required string instanceId) {
        try {
            // Update database
            queryExecute("
                UPDATE instance_registrations 
                SET last_heartbeat = NOW() 
                WHERE id = :instanceId
            ", {instanceId: arguments.instanceId}, {datasource: "mcpcfc_ds"});
            
            // Update memory
            lock name="instanceRegistry" timeout="5" type="exclusive" {
                if (structKeyExists(application.instanceRegistry, arguments.instanceId)) {
                    application.instanceRegistry[arguments.instanceId].lastHeartbeat = now();
                }
            }
            
            return createMCPResponse("💫✨ Heartbeat acknowledged - Connection persisted");
            
        } catch (any e) {
            return createErrorResponse("Heartbeat failed: #e.message#");
        }
    }
    
    /**
     * Get active instances from database
     */
    public struct function getActiveInstances() {
        try {
            var activeInstances = queryExecute("
                SELECT id, name, capabilities, registered_at, last_heartbeat,
                       status, protocol_version, generation, parent_instance_id,
                       TIMESTAMPDIFF(MINUTE, last_heartbeat, NOW()) as minutes_inactive
                FROM instance_registrations
                WHERE status = 'active'
                  AND TIMESTAMPDIFF(MINUTE, last_heartbeat, NOW()) <= 5
                ORDER BY last_heartbeat DESC
            ", {}, {datasource: "mcpcfc_ds"});
            
            var instances = [];
            for (var row in activeInstances) {
                arrayAppend(instances, {
                    "id": row.id,
                    "name": row.name,
                    "capabilities": isJSON(row.capabilities) ? deserializeJSON(row.capabilities) : {},
                    "registeredAt": row.registered_at,
                    "lastHeartbeat": row.last_heartbeat,
                    "status": row.status,
                    "protocolVersion": row.protocol_version,
                    "generation": row.generation,
                    "parentInstanceId": row.parent_instance_id,
                    "minutesInactive": row.minutes_inactive
                });
            }
            
            return createMCPResponse({
                "instances": instances,
                "count": arrayLen(instances),
                "timestamp": now()
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to get active instances: #e.message#");
        }
    }
    
    /**
     * Archive old instances
     */
    public struct function archiveInactiveInstances(numeric inactiveMinutes = 60) {
        try {
            var archived = queryExecute("
                UPDATE instance_registrations 
                SET status = 'archived',
                    last_disconnected = NOW()
                WHERE status = 'active'
                  AND TIMESTAMPDIFF(MINUTE, last_heartbeat, NOW()) > :minutes
            ", {minutes: arguments.inactiveMinutes}, {datasource: "mcpcfc_ds"});
            
            // Sync to memory
            syncDatabaseToMemory();
            
            return createMCPResponse({
                "archived": archived.recordCount,
                "message": "Archived #archived.recordCount# inactive instances"
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to archive instances: #e.message#");
        }
    }
    
    /**
     * Sync database state to memory cache
     */
    private void function syncDatabaseToMemory() {
        try {
            var activeInstances = queryExecute("
                SELECT * FROM instance_registrations 
                WHERE status = 'active'
            ", {}, {datasource: "mcpcfc_ds"});
            
            lock name="instanceRegistry" timeout="5" type="exclusive" {
                application.instanceRegistry = structNew("ordered");
                
                for (var row in activeInstances) {
                    application.instanceRegistry[row.id] = {
                        "id": row.id,
                        "name": row.name,
                        "capabilities": isJSON(row.capabilities) ? deserializeJSON(row.capabilities) : {},
                        "registeredAt": row.registered_at,
                        "lastHeartbeat": row.last_heartbeat,
                        "status": row.status,
                        "protocolVersion": row.protocol_version,
                        "generation": row.generation,
                        "parentInstanceId": row.parent_instance_id,
                        "connectionToken": row.connection_token
                    };
                }
            }
        } catch (any e) {
            writeLog(
                text="Failed to sync database to memory: #e.message#",
                type="error",
                application=true
            );
        }
    }
    
    /**
     * Get the tool definitions for MCP
     */
    public array function getToolDefinitions() {
        return [
            {
                name = "registerInstance",
                description = "Register or reconnect a Claude instance",
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
                        },
                        connectionToken = {
                            type = "string",
                            description = "Token for secure reconnection (optional)"
                        },
                        attemptReconnect = {
                            type = "boolean",
                            description = "Try to reconnect to previous session",
                            default = true
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
                name = "getMessageHistory",
                description = "Get message history for an instance",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Instance ID to get history for"
                        },
                        parentInstanceId = {
                            type = "string",
                            description = "Parent instance ID for lineage lookup"
                        },
                        limit = {
                            type = "number",
                            description = "Maximum messages to retrieve",
                            default = 100
                        }
                    },
                    required = ["instanceId"]
                }
            },
            {
                name = "archiveInactiveInstances",
                description = "Archive instances that have been inactive",
                inputSchema = {
                    type = "object",
                    properties = {
                        inactiveMinutes = {
                            type = "number",
                            description = "Minutes of inactivity before archiving",
                            default = 60
                        }
                    }
                }
            }
        ];
    }
}