component output="false" {
    
    this.name = "MCPServer";
    this.applicationTimeout = createTimeSpan(1, 0, 0, 0);
    this.sessionManagement = false;
    
    public void function onApplicationStart() {
        // Initialize thread-safe message queue
        application.messageQueue = createObject("java", "java.util.concurrent.LinkedBlockingQueue").init();
        
        // Initialize session manager
        application.sessionManager = new components.SessionManager();
        
        // Initialize tool registry
        application.toolRegistry = new components.ToolRegistry();
        
        // Register default tools
        registerTools();
    }
    
    private void function registerTools() {
        // Register hello world tool
        application.toolRegistry.registerTool("hello", {
            "description": "A simple hello world tool",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Name to greet"
                    }
                },
                "required": ["name"]
            }
        });
        
        // Register database query tool
        application.toolRegistry.registerTool("queryDatabase", {
            "description": "Execute a database query",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "SQL query to execute"
                    },
                    "datasource": {
                        "type": "string",                        "description": "Database datasource name"
                    }
                },
                "required": ["query", "datasource"]
            }
        });
    }
}