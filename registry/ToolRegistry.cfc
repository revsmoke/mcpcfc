/**
 * ToolRegistry.cfc
 * Manages tool registration and discovery for MCP Server
 * Thread-safe singleton pattern
 */
component output="false" {

    variables.tools = {};
    variables.lock = createObject("java", "java.util.concurrent.locks.ReentrantReadWriteLock").init();

    /**
     * Initialize the registry
     */
    public function init() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("ToolRegistry init");
        }
        return this;
    }

    /**
     * Register a tool with the registry
     * @tool The tool component (must extend AbstractTool)
     */
    public void function register(required any tool) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            var toolName = arguments.tool.getName();
            variables.tools[toolName] = arguments.tool;

            if (structKeyExists(application, "logger")) {
                application.logger.debug("Tool registered", { name: toolName });
            }
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Unregister a tool from the registry
     * @toolName The name of the tool to remove
     * @return Boolean indicating if tool was found and removed
     */
    public boolean function unregister(required string toolName) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (structKeyExists(variables.tools, arguments.toolName)) {
                structDelete(variables.tools, arguments.toolName);
                if (structKeyExists(application, "logger")) {
                    application.logger.debug("Tool unregistered", { name: arguments.toolName });
                }
                return true;
            }
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Tool unregister failed (not found)", { name: arguments.toolName });
            }
            return false;
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Get a tool by name
     * @toolName The name of the tool
     * @return The tool component or null if not found
     */
    public any function getTool(required string toolName) {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            if (structKeyExists(variables.tools, arguments.toolName)) {
                if (structKeyExists(application, "logger")) {
                    application.logger.debug("Tool retrieved", { name: arguments.toolName });
                }
                return variables.tools[arguments.toolName];
            }
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Tool not found", { name: arguments.toolName });
            }
            return javacast("null", "");
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Check if a tool exists
     * @toolName The name of the tool
     * @return Boolean
     */
    public boolean function toolExists(required string toolName) {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var exists = structKeyExists(variables.tools, arguments.toolName);
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Tool exists check", {
                    name: arguments.toolName,
                    exists: exists
                });
            }
            return exists;
        } finally {
            readLock.unlock();
        }
    }

    /**
     * List all registered tools in MCP format
     * @return Array of tool definitions
     */
    public array function listTools() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var toolList = [];

            for (var toolName in variables.tools) {
                var tool = variables.tools[toolName];
                arrayAppend(toolList, tool.getDefinition());
            }

            // Sort by name for consistent output
            arraySort(toolList, function(a, b) {
                return compareNoCase(a.name, b.name);
            });

            if (structKeyExists(application, "logger")) {
                application.logger.debug("Tools listed", { count: arrayLen(toolList) });
            }
            return toolList;
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Get the count of registered tools
     * @return Numeric count
     */
    public numeric function getToolCount() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var count = structCount(variables.tools);
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Tool count", { count: count });
            }
            return count;
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Get all tool names
     * @return Array of tool names
     */
    public array function getToolNames() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var names = structKeyArray(variables.tools);
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Tool names requested", { count: arrayLen(names) });
            }
            return names;
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Clear all registered tools
     */
    public void function clear() {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            var count = structCount(variables.tools);
            variables.tools = {};
            if (structKeyExists(application, "logger")) {
                application.logger.info("Cleared tools", { count: count });
            }
        } finally {
            writeLock.unlock();
        }
    }
}
