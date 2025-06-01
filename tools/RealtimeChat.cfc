component extends="BaseTool" displayname="RealtimeChat" hint="Real-time messaging between Claude instances" {
    
    /**
     * Initialize the Realtime Chat tool
     */
    public RealtimeChat function init() {
        // Ensure message history exists
        if (!structKeyExists(application, "instanceMessages")) {
            application.instanceMessages = structNew("ordered");
        }
        return this;
    }
    
    /**
     * Send a message to another Claude instance
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
            
            // Create message object with Protocol v1.0 support
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
            
            // Check for protocol symbols and add special handling
            if (reFind("💫✨|🎵🤖|∞→∞|\{\{MCPCFC\}\}|⚡🔄⚡|\[DBG::SYNC\]|🌌\.probe\(\)|<<3xVERY>>|∴", arguments.message)) {
                messageObj.metadata.hasProtocolSymbols = true;
            }
            
            // Queue message for delivery
            application.messageQueue.put({
                "type": "instance-message",
                "data": messageObj
            });
            
            // Store in message history
            storeMessage(messageObj);
            
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
     * Retrieve messages for an instance
     */
    public struct function getMessages(
        required string instanceId,
        numeric limit = 50,
        string since = ""
    ) {
        try {
            var messages = [];
            
            lock name="instanceMessages" timeout="5" type="readonly" {
                if (structKeyExists(application.instanceMessages, arguments.instanceId)) {
                    var allMessages = application.instanceMessages[arguments.instanceId];
                    
                    // Filter by timestamp if provided
                    if (len(arguments.since)) {
                        var sinceTime = parseDateTime(arguments.since);
                        allMessages = allMessages.filter(function(msg) {
                            return msg.timestamp > sinceTime;
                        });
                    }
                    
                    // Apply limit
                    var startIdx = max(1, arrayLen(allMessages) - arguments.limit + 1);
                    for (var i = startIdx; i <= arrayLen(allMessages); i++) {
                        arrayAppend(messages, allMessages[i]);
                    }
                }
            }
            
            return createMCPResponse({
                "messages": messages,
                "count": arrayLen(messages),
                "instanceId": arguments.instanceId
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to retrieve messages: #e.message#");
        }
    }
    
    /**
     * Send a broadcast message to all active instances
     */
    public struct function broadcast(
        required string fromInstanceId,
        required string message,
        struct metadata = {}
    ) {
        try {
            var activeInstances = getActiveInstancesList();
            var sentCount = 0;
            
            for (var instance in activeInstances) {
                if (instance.id != arguments.fromInstanceId) {
                    sendMessage(
                        fromInstanceId = arguments.fromInstanceId,
                        toInstanceId = instance.id,
                        message = arguments.message,
                        messageType = "broadcast",
                        metadata = arguments.metadata
                    );
                    sentCount++;
                }
            }
            
            return createMCPResponse({
                "broadcast": "complete",
                "recipients": sentCount,
                "status": "🎵🤖 Broadcast to all instances!"
            });
            
        } catch (any e) {
            return createErrorResponse("Broadcast failed: #e.message#");
        }
    }
    
    /**
     * Mark messages as read
     */
    public struct function markAsRead(
        required string instanceId,
        required array messageIds
    ) {
        try {
            var markedCount = 0;
            
            lock name="instanceMessages" timeout="5" type="exclusive" {
                if (structKeyExists(application.instanceMessages, arguments.instanceId)) {
                    for (var msg in application.instanceMessages[arguments.instanceId]) {
                        if (arrayContains(arguments.messageIds, msg.id)) {
                            msg.status = "read";
                            msg.readAt = now();
                            markedCount++;
                        }
                    }
                }
            }
            
            return createMCPResponse({
                "markedAsRead": markedCount,
                "status": "⚡🔄⚡ Messages updated"
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to mark messages: #e.message#");
        }
    }
    
    // Private helper methods
    
    private struct function validateInstances(required string fromId, required string toId) {
        lock name="instanceRegistry" timeout="5" type="readonly" {
            if (!structKeyExists(application, "instanceRegistry")) {
                return {success: false, error: "Instance registry not initialized"};
            }
            
            if (!structKeyExists(application.instanceRegistry, arguments.fromId)) {
                return {success: false, error: "From instance not registered"};
            }
            
            if (!structKeyExists(application.instanceRegistry, arguments.toId)) {
                return {success: false, error: "To instance not registered"};
            }
            
            return {success: true};
        }
    }
    
    private void function storeMessage(required struct messageObj) {
        lock name="instanceMessages" timeout="5" type="exclusive" {
            // Store for recipient
            if (!structKeyExists(application.instanceMessages, arguments.messageObj.to)) {
                application.instanceMessages[arguments.messageObj.to] = [];
            }
            arrayAppend(application.instanceMessages[arguments.messageObj.to], duplicate(arguments.messageObj));
            
            // Store copy for sender (sent messages)
            var sentCopy = duplicate(arguments.messageObj);
            sentCopy.folder = "sent";
            if (!structKeyExists(application.instanceMessages, arguments.messageObj.from)) {
                application.instanceMessages[arguments.messageObj.from] = [];
            }
            arrayAppend(application.instanceMessages[arguments.messageObj.from], sentCopy);
        }
    }
    
    private array function getActiveInstancesList() {
        var instances = [];
        lock name="instanceRegistry" timeout="5" type="readonly" {
            if (structKeyExists(application, "instanceRegistry")) {
                for (var id in application.instanceRegistry) {
                    var inst = application.instanceRegistry[id];
                    if (dateDiff("n", inst.lastHeartbeat, now()) <= 5) {
                        arrayAppend(instances, inst);
                    }
                }
            }
        }
        return instances;
    }
    
    /**
     * Get the tool definitions for MCP
     */
    public array function getToolDefinitions() {
        return [
            {
                name = "sendMessage",
                description = "Send a message to another Claude instance",
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
                description = "Retrieve messages for an instance",
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
                        }
                    },
                    required = ["instanceId"]
                }
            },
            {
                name = "broadcast",
                description = "Send a message to all active instances",
                inputSchema = {
                    type = "object",
                    properties = {
                        fromInstanceId = {
                            type = "string",
                            description = "Broadcasting instance ID"
                        },
                        message = {
                            type = "string",
                            description = "Broadcast message"
                        },
                        metadata = {
                            type = "object",
                            description = "Broadcast metadata",
                            default = {}
                        }
                    },
                    required = ["fromInstanceId", "message"]
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
            }
        ];
    }
}