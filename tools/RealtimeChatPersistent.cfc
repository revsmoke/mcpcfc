component extends="BaseTool" displayname="RealtimeChatPersistent" hint="Persistent real-time messaging between Claude instances" {
    
    /**
     * Initialize the Persistent Realtime Chat tool
     */
    public RealtimeChatPersistent function init() {
        // Ensure message history exists in memory for performance
        if (!structKeyExists(application, "instanceMessages")) {
            application.instanceMessages = structNew("ordered");
        }
        
        // Load recent messages from database to memory
        loadRecentMessagesToMemory();
        
        return this;
    }
    
    /**
     * Send a message and persist to database
     */
    public struct function sendMessage(
        required string fromInstanceId,
        required string toInstanceId,
        required string message,
        string messageType = "text",
        struct metadata = {}
    ) {
        try {
            // Validate instances exist
            var validInstances = validateInstances(arguments.fromInstanceId, arguments.toInstanceId);
            if (!validInstances.success) {
                return createErrorResponse(validInstances.error);
            }
            
            // Create message object
            var messageObj = {
                "id": createUUID(),
                "from": arguments.fromInstanceId,
                "to": arguments.toInstanceId,
                "message": arguments.message,
                "messageType": arguments.messageType,
                "metadata": arguments.metadata,
                "timestamp": now(),
                "protocol": "1.0",
                "status": "sent"
            };
            
            // Check for protocol symbols
            if (reFind("💫✨|🎵🤖|∞→∞|\{\{MCPCFC\}\}|⚡🔄⚡|\[DBG::SYNC\]|🌌\.probe\(\)|<<3xVERY>>|∴", arguments.message)) {
                messageObj.metadata.hasProtocolSymbols = true;
            }
            
            // Store in database
            queryExecute("
                INSERT INTO instance_messages 
                (id, from_instance_id, to_instance_id, message, message_type, 
                 metadata, timestamp, protocol_version, status)
                VALUES 
                (:id, :fromInstanceId, :toInstanceId, :message, :messageType,
                 :metadata, :timestamp, :protocolVersion, :status)
            ", {
                id: messageObj.id,
                fromInstanceId: messageObj.from,
                toInstanceId: messageObj.to,
                message: messageObj.message,
                messageType: messageObj.messageType,
                metadata: serializeJSON(messageObj.metadata),
                timestamp: messageObj.timestamp,
                protocolVersion: messageObj.protocol,
                status: messageObj.status
            }, {datasource: "mcpcfc_ds"});
            
            // Queue for real-time delivery
            application.messageQueue.put({
                "type": "instance-message",
                "data": messageObj
            });
            
            // Store in memory cache
            storeMessageInMemory(messageObj);
            
            // Update instance connection activity
            updateConnectionActivity(arguments.fromInstanceId, arguments.toInstanceId);
            
            // Log the message
            writeLog(
                text="Instance message sent: #arguments.fromInstanceId# → #arguments.toInstanceId#",
                type="information",
                application=true
            );
            
            return createMCPResponse({
                "messageId": messageObj.id,
                "status": "sent",
                "confirmation": "💫✨ Message delivered to queue!"
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to send message: #e.message#");
        }
    }
    
    /**
     * Retrieve messages with database persistence
     */
    public struct function getMessages(
        required string instanceId,
        numeric limit = 50,
        string since = "",
        boolean includeLineage = true
    ) {
        try {
            var messages = [];
            var instanceIds = [arguments.instanceId];
            
            // Include parent instances if requested
            if (arguments.includeLineage) {
                var lineage = getInstanceLineage(arguments.instanceId);
                instanceIds = listToArray(listAppend(arrayToList(instanceIds), lineage));
            }
            
            // Build query
            var sql = "
                SELECT id, from_instance_id, to_instance_id, message, 
                       message_type, metadata, timestamp, protocol_version, status, read_at
                FROM instance_messages
                WHERE (from_instance_id IN (:instanceIds) OR to_instance_id IN (:instanceIds))
            ";
            
            var params = {instanceIds: arrayToList(instanceIds)};
            
            // Add time filter if provided
            if (len(arguments.since)) {
                sql &= " AND timestamp > :since";
                params.since = arguments.since;
            }
            
            sql &= " ORDER BY timestamp DESC LIMIT :limit";
            params.limit = arguments.limit;
            
            // Execute query
            var messageQuery = queryExecute(sql, params, {datasource: "mcpcfc_ds"});
            
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
                    "protocol": row.protocol_version,
                    "status": row.status
                };
                
                if (!isNull(row.read_at)) {
                    msg.readAt = row.read_at;
                }
                
                // Add folder designation
                if (row.from_instance_id == arguments.instanceId) {
                    msg.folder = "sent";
                }
                
                arrayAppend(messages, msg);
            }
            
            // Reverse to get chronological order
            messages = messages.reverse();
            
            return createMCPResponse({
                "messages": messages,
                "count": arrayLen(messages),
                "instanceId": arguments.instanceId,
                "includedLineage": arguments.includeLineage
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to retrieve messages: #e.message#");
        }
    }
    
    /**
     * Mark messages as read in database
     */
    public struct function markAsRead(
        required string instanceId,
        required array messageIds
    ) {
        try {
            var markedCount = 0;
            
            if (arrayLen(arguments.messageIds) > 0) {
                var result = queryExecute("
                    UPDATE instance_messages 
                    SET status = 'read', read_at = NOW()
                    WHERE to_instance_id = :instanceId
                      AND id IN (:messageIds)
                      AND status != 'read'
                ", {
                    instanceId: arguments.instanceId,
                    messageIds: arrayToList(arguments.messageIds)
                }, {datasource: "mcpcfc_ds"});
                
                markedCount = result.recordCount;
                
                // Update memory cache
                updateMemoryReadStatus(arguments.instanceId, arguments.messageIds);
            }
            
            return createMCPResponse({
                "markedAsRead": markedCount,
                "status": "⚡🔄⚡ Messages updated"
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to mark messages: #e.message#");
        }
    }
    
    /**
     * Get conversation summary for reconnection
     */
    public struct function getConversationSummary(
        required string instanceId,
        numeric recentHours = 24
    ) {
        try {
            // Get conversation stats
            var stats = queryExecute("
                SELECT 
                    COUNT(*) as total_messages,
                    COUNT(DISTINCT 
                        CASE WHEN from_instance_id = :instanceId 
                        THEN to_instance_id 
                        ELSE from_instance_id END
                    ) as unique_conversations,
                    MIN(timestamp) as first_message,
                    MAX(timestamp) as last_message
                FROM instance_messages
                WHERE (from_instance_id = :instanceId OR to_instance_id = :instanceId)
                  AND timestamp > DATE_SUB(NOW(), INTERVAL :hours HOUR)
            ", {
                instanceId: arguments.instanceId,
                hours: arguments.recentHours
            }, {datasource: "mcpcfc_ds"});
            
            // Get recent conversation partners
            var partners = queryExecute("
                SELECT DISTINCT
                    CASE WHEN from_instance_id = :instanceId 
                    THEN to_instance_id 
                    ELSE from_instance_id END as partner_id,
                    COUNT(*) as message_count
                FROM instance_messages
                WHERE (from_instance_id = :instanceId OR to_instance_id = :instanceId)
                  AND timestamp > DATE_SUB(NOW(), INTERVAL :hours HOUR)
                GROUP BY partner_id
                ORDER BY message_count DESC
                LIMIT 5
            ", {
                instanceId: arguments.instanceId,
                hours: arguments.recentHours
            }, {datasource: "mcpcfc_ds"});
            
            var partnerList = [];
            for (var row in partners) {
                arrayAppend(partnerList, {
                    "partnerId": row.partner_id,
                    "messageCount": row.message_count
                });
            }
            
            return createMCPResponse({
                "summary": {
                    "totalMessages": stats.total_messages,
                    "uniqueConversations": stats.unique_conversations,
                    "firstMessage": stats.first_message,
                    "lastMessage": stats.last_message,
                    "recentPartners": partnerList
                }
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to get summary: #e.message#");
        }
    }
    
    // Private helper methods
    
    private struct function validateInstances(required string fromId, required string toId) {
        try {
            var check = queryExecute("
                SELECT COUNT(*) as valid_count
                FROM instance_registrations
                WHERE id IN (:ids)
                  AND status = 'active'
            ", {ids: "#arguments.fromId#,#arguments.toId#"}, {datasource: "mcpcfc_ds"});
            
            if (check.valid_count < 2) {
                return {success: false, error: "One or both instances not registered or inactive"};
            }
            
            return {success: true};
            
        } catch (any e) {
            return {success: false, error: e.message};
        }
    }
    
    private void function storeMessageInMemory(required struct messageObj) {
        lock name="instanceMessages" timeout="5" type="exclusive" {
            // Store for recipient
            if (!structKeyExists(application.instanceMessages, arguments.messageObj.to)) {
                application.instanceMessages[arguments.messageObj.to] = [];
            }
            arrayAppend(application.instanceMessages[arguments.messageObj.to], duplicate(arguments.messageObj));
            
            // Store for sender
            var sentCopy = duplicate(arguments.messageObj);
            sentCopy.folder = "sent";
            if (!structKeyExists(application.instanceMessages, arguments.messageObj.from)) {
                application.instanceMessages[arguments.messageObj.from] = [];
            }
            arrayAppend(application.instanceMessages[arguments.messageObj.from], sentCopy);
            
            // Limit memory cache size
            trimMemoryCache(arguments.messageObj.to);
            trimMemoryCache(arguments.messageObj.from);
        }
    }
    
    private void function trimMemoryCache(required string instanceId) {
        if (structKeyExists(application.instanceMessages, arguments.instanceId) &&
            arrayLen(application.instanceMessages[arguments.instanceId]) > 100) {
            // Keep only last 100 messages in memory
            var messages = application.instanceMessages[arguments.instanceId];
            application.instanceMessages[arguments.instanceId] = messages.slice(
                max(1, arrayLen(messages) - 100)
            );
        }
    }
    
    private void function updateConnectionActivity(required string instanceA, required string instanceB) {
        try {
            queryExecute("
                INSERT INTO instance_connections 
                (instance_a_id, instance_b_id, connection_type, last_activity)
                VALUES (:a, :b, 'chat', NOW())
                ON DUPLICATE KEY UPDATE
                    last_activity = NOW()
            ", {
                a: arguments.instanceA < arguments.instanceB ? arguments.instanceA : arguments.instanceB,
                b: arguments.instanceA < arguments.instanceB ? arguments.instanceB : arguments.instanceA
            }, {datasource: "mcpcfc_ds"});
        } catch (any e) {
            // Log but don't fail message send
            writeLog(text="Failed to update connection activity: #e.message#", type="warning", application=true);
        }
    }
    
    private string function getInstanceLineage(required string instanceId) {
        try {
            var lineage = queryExecute("
                WITH RECURSIVE instance_lineage AS (
                    SELECT parent_instance_id 
                    FROM instance_registrations 
                    WHERE id = :instanceId AND parent_instance_id IS NOT NULL
                    
                    UNION ALL
                    
                    SELECT i.parent_instance_id
                    FROM instance_registrations i
                    INNER JOIN instance_lineage il ON i.id = il.parent_instance_id
                    WHERE i.parent_instance_id IS NOT NULL
                )
                SELECT GROUP_CONCAT(parent_instance_id) as lineage
                FROM instance_lineage
            ", {instanceId: arguments.instanceId}, {datasource: "mcpcfc_ds"});
            
            return lineage.lineage ?: "";
            
        } catch (any e) {
            return "";
        }
    }
    
    private void function loadRecentMessagesToMemory() {
        try {
            // Load last 50 messages per active instance
            var recentMessages = queryExecute("
                SELECT m.* 
                FROM instance_messages m
                INNER JOIN (
                    SELECT DISTINCT id 
                    FROM instance_registrations 
                    WHERE status = 'active'
                    AND TIMESTAMPDIFF(MINUTE, last_heartbeat, NOW()) <= 30
                ) i ON (m.from_instance_id = i.id OR m.to_instance_id = i.id)
                WHERE m.timestamp > DATE_SUB(NOW(), INTERVAL 1 HOUR)
                ORDER BY m.timestamp DESC
                LIMIT 500
            ", {}, {datasource: "mcpcfc_ds"});
            
            lock name="instanceMessages" timeout="5" type="exclusive" {
                application.instanceMessages = structNew("ordered");
                
                for (var row in recentMessages) {
                    var msg = {
                        "id": row.id,
                        "from": row.from_instance_id,
                        "to": row.to_instance_id,
                        "message": row.message,
                        "messageType": row.message_type,
                        "metadata": isJSON(row.metadata) ? deserializeJSON(row.metadata) : {},
                        "timestamp": row.timestamp,
                        "protocol": row.protocol_version,
                        "status": row.status
                    };
                    
                    // Add to recipient's messages
                    if (!structKeyExists(application.instanceMessages, msg.to)) {
                        application.instanceMessages[msg.to] = [];
                    }
                    arrayAppend(application.instanceMessages[msg.to], msg);
                }
            }
            
        } catch (any e) {
            writeLog(
                text="Failed to load messages to memory: #e.message#",
                type="warning",
                application=true
            );
        }
    }
    
    private void function updateMemoryReadStatus(required string instanceId, required array messageIds) {
        lock name="instanceMessages" timeout="5" type="exclusive" {
            if (structKeyExists(application.instanceMessages, arguments.instanceId)) {
                for (var msg in application.instanceMessages[arguments.instanceId]) {
                    if (arrayContains(arguments.messageIds, msg.id)) {
                        msg.status = "read";
                        msg.readAt = now();
                    }
                }
            }
        }
    }
    
    /**
     * Get the tool definitions for MCP
     */
    public array function getToolDefinitions() {
        return [
            {
                name = "sendMessage",
                description = "Send a persistent message to another Claude instance",
                inputSchema = {
                    type = "object",
                    properties = {
                        fromInstanceId = {
                            type = "string",
                            description = "Sending instance ID"
                        },
                        toInstanceId = {
                            type = "string",
                            description = "Recipient instance ID"
                        },
                        message = {
                            type = "string",
                            description = "Message content (supports Protocol v1.0 symbols)"
                        },
                        messageType = {
                            type = "string",
                            description = "Type of message",
                            enum = ["text", "code", "protocol", "debug"],
                            default = "text"
                        },
                        metadata = {
                            type = "object",
                            description = "Additional message metadata",
                            default = {}
                        }
                    },
                    required = ["fromInstanceId", "toInstanceId", "message"]
                }
            },
            {
                name = "getMessages",
                description = "Retrieve messages with full history support",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Instance ID to get messages for"
                        },
                        limit = {
                            type = "number",
                            description = "Maximum messages to retrieve",
                            default = 50
                        },
                        since = {
                            type = "string",
                            description = "Get messages since this timestamp"
                        },
                        includeLineage = {
                            type = "boolean",
                            description = "Include messages from parent instances",
                            default = true
                        }
                    },
                    required = ["instanceId"]
                }
            },
            {
                name = "markAsRead",
                description = "Mark messages as read",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Instance marking messages"
                        },
                        messageIds = {
                            type = "array",
                            description = "Array of message IDs to mark as read",
                            items = {type = "string"}
                        }
                    },
                    required = ["instanceId", "messageIds"]
                }
            },
            {
                name = "getConversationSummary",
                description = "Get summary of recent conversations",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Instance ID to summarize"
                        },
                        recentHours = {
                            type = "number",
                            description = "Hours to look back",
                            default = 24
                        }
                    },
                    required = ["instanceId"]
                }
            }
        ];
    }
}