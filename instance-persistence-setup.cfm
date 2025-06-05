<!DOCTYPE html>
<html>
<head>
    <title>Instance Bridge Persistence Setup</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Instance Bridge Persistence Setup</h1>
    <p>Setting up database tables for persistent instance connections and message history...</p>
    
    <cfscript>
    try {
        // Create instance_registrations table
        queryExecute("
            CREATE TABLE IF NOT EXISTS instance_registrations (
                id VARCHAR(50) PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                capabilities TEXT,
                registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_heartbeat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_disconnected TIMESTAMP NULL,
                status VARCHAR(20) DEFAULT 'active',
                protocol_version VARCHAR(10) DEFAULT '1.0',
                generation INT DEFAULT 1,
                parent_instance_id VARCHAR(50) NULL,
                connection_token VARCHAR(100) NULL,
                INDEX idx_status (status),
                INDEX idx_heartbeat (last_heartbeat),
                INDEX idx_parent (parent_instance_id)
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<div class="section">');
        writeOutput('<p class="success">✅ Created instance_registrations table</p>');
        writeOutput('<p>Features: Generation tracking for reconnections, parent instance linking, connection tokens</p>');
        writeOutput('</div>');
        
        // Create instance_messages table
        queryExecute("
            CREATE TABLE IF NOT EXISTS instance_messages (
                id VARCHAR(50) PRIMARY KEY,
                from_instance_id VARCHAR(50) NOT NULL,
                to_instance_id VARCHAR(50) NOT NULL,
                message TEXT NOT NULL,
                message_type VARCHAR(20) DEFAULT 'text',
                metadata TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                protocol_version VARCHAR(10) DEFAULT '1.0',
                status VARCHAR(20) DEFAULT 'sent',
                read_at TIMESTAMP NULL,
                INDEX idx_from (from_instance_id),
                INDEX idx_to (to_instance_id),
                INDEX idx_timestamp (timestamp),
                INDEX idx_status (status)
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<div class="section">');
        writeOutput('<p class="success">✅ Created instance_messages table</p>');
        writeOutput('<p>Features: Full message history, read status tracking, metadata storage</p>');
        writeOutput('</div>');
        
        // Create instance_connections table for tracking relationships
        queryExecute("
            CREATE TABLE IF NOT EXISTS instance_connections (
                id INT AUTO_INCREMENT PRIMARY KEY,
                instance_a_id VARCHAR(50) NOT NULL,
                instance_b_id VARCHAR(50) NOT NULL,
                connection_type VARCHAR(50) DEFAULT 'peer',
                established_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                metadata TEXT,
                INDEX idx_instance_a (instance_a_id),
                INDEX idx_instance_b (instance_b_id),
                UNIQUE KEY unique_connection (instance_a_id, instance_b_id)
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<div class="section">');
        writeOutput('<p class="success">✅ Created instance_connections table</p>');
        writeOutput('<p>Features: Track instance relationships and connection history</p>');
        writeOutput('</div>');
        
        // Create instance_sessions table for context continuity
        queryExecute("
            CREATE TABLE IF NOT EXISTS instance_sessions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                instance_id VARCHAR(50) NOT NULL,
                session_data TEXT,
                context_summary TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_instance (instance_id)
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<div class="section">');
        writeOutput('<p class="success">✅ Created instance_sessions table</p>');
        writeOutput('<p>Features: Store session context for resuming conversations</p>');
        writeOutput('</div>');
        
        // Show implementation guide
        writeOutput('<h2>Implementation Guide</h2>');
        writeOutput('<div class="section">');
        writeOutput('<h3>1. Instance Reconnection Flow:</h3>');
        writeOutput('<pre>
// When Claude Desktop starts new chat:
1. Check if previous instance exists by name pattern
2. If exists and recent (< 30 min), offer to resume:
   - Create new generation with same ID + incremented generation number
   - Link to parent instance
   - Load message history
3. If too old or not found, create new instance
        </pre>');
        
        writeOutput('<h3>2. Connection Token Usage:</h3>');
        writeOutput('<pre>
// Generate token on registration:
connectionToken = hash(instanceId & now() & createUUID())

// Store in instance metadata for future reconnection
// Use for secure reconnection validation
        </pre>');
        
        writeOutput('<h3>3. Message History Retrieval:</h3>');
        writeOutput('<pre>
// Get all messages for an instance including parent generations:
SELECT * FROM instance_messages 
WHERE (from_instance_id = :id OR to_instance_id = :id)
   OR (from_instance_id IN (
       SELECT id FROM instance_registrations 
       WHERE parent_instance_id = :id
   ))
ORDER BY timestamp DESC
        </pre>');
        writeOutput('</div>');
        
        // Show current state
        writeOutput('<h2>Current Database State:</h2>');
        
        // Check for existing instances
        var instances = queryExecute("
            SELECT COUNT(*) as count FROM instance_registrations
        ", {}, {datasource: "mcpcfc_ds"});
        writeOutput('<p>Registered instances: ' & instances.count & '</p>');
        
        // Check for existing messages
        var messages = queryExecute("
            SELECT COUNT(*) as count FROM instance_messages
        ", {}, {datasource: "mcpcfc_ds"});
        writeOutput('<p>Stored messages: ' & messages.count & '</p>');
        
        writeOutput('<h2>Next Steps:</h2>');
        writeOutput('<ol>');
        writeOutput('<li>Update InstanceBridge.cfc to use database storage</li>');
        writeOutput('<li>Update RealtimeChat.cfc to persist messages</li>');
        writeOutput('<li>Add reconnection methods to InstanceBridge</li>');
        writeOutput('<li>Implement session context storage</li>');
        writeOutput('<li>Add cleanup job for old instances</li>');
        writeOutput('</ol>');
        
    } catch (any e) {
        writeOutput('<p class="error">❌ Error: ' & e.message & '</p>');
        writeDump(e);
    }
    </cfscript>
</body>
</html>