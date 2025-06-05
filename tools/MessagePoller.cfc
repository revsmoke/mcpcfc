component extends="BaseTool" displayname="MessagePoller" hint="Smart polling for new messages" {
    
    /**
     * Initialize the Message Poller
     */
    public MessagePoller function init() {
        // Track last poll times per instance
        if (!structKeyExists(application, "pollTracking")) {
            application.pollTracking = structNew("ordered");
        }
        return this;
    }
    
    /**
     * Check for new messages with smart polling
     */
    public struct function checkNewMessages(
        required string instanceId,
        string lastMessageId = "",
        boolean returnImmediately = true
    ) {
        try {
            var hasNew = false;
            var newMessages = [];
            var metadata = {
                "polledAt": now(),
                "nextPollSuggested": 5 // seconds
            };
            
            // Update poll tracking
            lock name="pollTracking" timeout="5" type="exclusive" {
                if (!structKeyExists(application.pollTracking, arguments.instanceId)) {
                    application.pollTracking[arguments.instanceId] = {
                        "lastPoll": now(),
                        "pollCount": 0,
                        "lastMessageId": ""
                    };
                }
                
                var tracking = application.pollTracking[arguments.instanceId];
                tracking.lastPoll = now();
                tracking.pollCount++;
                
                // Smart backoff based on activity
                var timeSinceLastPoll = dateDiff("s", tracking.lastPoll, now());
                if (timeSinceLastPoll < 5) {
                    metadata.nextPollSuggested = 10; // Back off if polling too fast
                } else if (tracking.pollCount > 10 && arrayLen(newMessages) == 0) {
                    metadata.nextPollSuggested = 30; // Less frequent if no activity
                }
            }
            
            // Check for new messages
            if (structKeyExists(application, "instanceMessages") && 
                structKeyExists(application.instanceMessages, arguments.instanceId)) {
                
                lock name="instanceMessages" timeout="5" type="readonly" {
                    var allMessages = application.instanceMessages[arguments.instanceId];
                    
                    // Find messages newer than lastMessageId
                    if (len(arguments.lastMessageId)) {
                        var foundLast = false;
                        for (var msg in allMessages) {
                            if (foundLast && msg.folder != "sent") {
                                arrayAppend(newMessages, msg);
                                hasNew = true;
                            }
                            if (msg.id == arguments.lastMessageId) {
                                foundLast = true;
                            }
                        }
                    } else if (arrayLen(allMessages) > 0) {
                        // No lastMessageId, check for any unread
                        for (var msg in allMessages) {
                            if (msg.status != "read" && msg.folder != "sent") {
                                arrayAppend(newMessages, msg);
                                hasNew = true;
                            }
                        }
                    }
                }
            }
            
            // Long polling simulation (wait up to 5 seconds for new messages)
            if (!arguments.returnImmediately && !hasNew) {
                var waited = 0;
                while (waited < 5000 && !hasNew) {
                    sleep(500); // Check every 500ms
                    waited += 500;
                    
                    // Re-check for messages
                    if (structKeyExists(application.instanceMessages, arguments.instanceId)) {
                        lock name="instanceMessages" timeout="5" type="readonly" {
                            var currentCount = arrayLen(application.instanceMessages[arguments.instanceId]);
                            if (currentCount > arrayLen(allMessages)) {
                                hasNew = true;
                                // Get the new messages
                                var allMessages = application.instanceMessages[arguments.instanceId];
                                newMessages = [allMessages[currentCount]];
                            }
                        }
                    }
                }
            }
            
            return createMCPResponse({
                "hasNewMessages": hasNew,
                "messageCount": arrayLen(newMessages),
                "messages": newMessages,
                "metadata": metadata,
                "suggestion": hasNew ? "New messages! Check with getMessages" : "No new messages"
            });
            
        } catch (any e) {
            return createErrorResponse("Polling failed: #e.message#");
        }
    }
    
    /**
     * Get polling status for all instances
     */
    public struct function getPollingStatus() {
        try {
            var status = {};
            
            lock name="pollTracking" timeout="5" type="readonly" {
                for (var instanceId in application.pollTracking) {
                    var tracking = application.pollTracking[instanceId];
                    status[instanceId] = {
                        "lastPoll": tracking.lastPoll,
                        "pollCount": tracking.pollCount,
                        "secondsSinceLastPoll": dateDiff("s", tracking.lastPoll, now())
                    };
                }
            }
            
            return createMCPResponse({
                "activePollers": status,
                "timestamp": now()
            });
            
        } catch (any e) {
            return createErrorResponse("Failed to get status: #e.message#");
        }
    }
    
    /**
     * Subscribe to message notifications (returns polling instructions)
     */
    public struct function subscribeToNotifications(
        required string instanceId,
        numeric pollInterval = 10
    ) {
        try {
            // Since we can't push, return polling instructions
            return createMCPResponse({
                "status": "subscription_simulated",
                "instructions": {
                    "method": "polling_required",
                    "suggestedInterval": arguments.pollInterval,
                    "endpoint": "checkNewMessages",
                    "example": "Call checkNewMessages every #arguments.pollInterval# seconds"
                },
                "note": "MCP protocol doesn't support push notifications. Use periodic polling.",
                "alternativeApproach": {
                    "description": "Claude instances could announce 'checking messages' periodically",
                    "benefit": "Natural conversation flow",
                    "example": "Every few exchanges, say 'Let me check for messages...'"
                }
            });
            
        } catch (any e) {
            return createErrorResponse("Subscription failed: #e.message#");
        }
    }
    
    /**
     * Get the tool definitions for MCP
     */
    public array function getToolDefinitions() {
        return [
            {
                name = "checkNewMessages",
                description = "Check for new messages with smart polling",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Instance ID to check messages for"
                        },
                        lastMessageId = {
                            type = "string",
                            description = "ID of last seen message (optional)"
                        },
                        returnImmediately = {
                            type = "boolean",
                            description = "Return immediately or wait up to 5s for new messages",
                            default = true
                        }
                    },
                    required = ["instanceId"]
                }
            },
            {
                name = "getPollingStatus",
                description = "Get polling activity for all instances",
                inputSchema = {
                    type = "object",
                    properties = {}
                }
            },
            {
                name = "subscribeToNotifications",
                description = "Get instructions for message notifications",
                inputSchema = {
                    type = "object",
                    properties = {
                        instanceId = {
                            type = "string",
                            description = "Instance requesting notifications"
                        },
                        pollInterval = {
                            type = "number",
                            description = "Suggested polling interval in seconds",
                            default = 10
                        }
                    },
                    required = ["instanceId"]
                }
            }
        ];
    }
}