/**
 * Application.cfc
 * MCPCFC - ColdFusion 2025 MCP Server
 * Protocol Version: 2025-11-25
 *
 * This application implements the Model Context Protocol for ColdFusion,
 * leveraging CF2025's modern features and capabilities.
 */
component output="false" {

    // Application settings
    this.name = "MCPCFC_2025";
    this.applicationTimeout = createTimeSpan(1, 0, 0, 0);
    this.sessionManagement = false;

    // CF2025: Configure Java settings for local JAR loading
    this.javaSettings = {
        loadPaths: [expandPath("./lib/")],
        loadColdFusionClassPath: true,
        reloadOnChange: false
    };

    // Custom tag paths
    this.customTagPaths = [expandPath("./customtags/")];

    // Mapping for component paths
    this.mappings["/core"] = expandPath("./core");
    this.mappings["/registry"] = expandPath("./registry");
    this.mappings["/logging"] = expandPath("./logging");
    this.mappings["/session"] = expandPath("./session");
    this.mappings["/config"] = expandPath("./config");

    /**
     * Application start handler
     * Initializes all server components and registries
     */
    public boolean function onApplicationStart() {
        // Record start time
        application.startTime = now();

        // Load external configuration
        include "config/settings.cfm";
        include "config/routes.cfm";

        // Ensure required directories exist
        ensureDirectories();

        // Initialize logger first (other components may use it)
        application.logger = new logging.Logger(
            level: application.config.logLevel,
            logDirectory: application.config.logDirectory
        );

        application.logger.info("MCPCFC Server starting", {
            version: application.config.serverVersion,
            protocol: application.config.protocolVersion
        });

        // Initialize session manager
        application.sessionManager = new session.SessionManager();

        // Initialize registries
        application.toolRegistry = new registry.ToolRegistry();
        application.resourceRegistry = new registry.ResourceRegistry();
        application.promptRegistry = new registry.PromptRegistry();

        // Initialize MCP server
        application.logger.info("About to create MCPServer");
        application.mcpServer = new core.MCPServer();
        application.logger.info("MCPServer created");

        // Register default tools, resources, and prompts
        application.logger.info("About to registerDefaultTools");
        application.mcpServer.registerDefaultTools();
        application.logger.info("registerDefaultTools complete");

        application.logger.info("About to registerDefaultResources");
        application.mcpServer.registerDefaultResources();
        application.logger.info("registerDefaultResources complete");

        application.logger.info("About to registerDefaultPrompts");
        application.mcpServer.registerDefaultPrompts();
        application.logger.info("registerDefaultPrompts complete");

        // Start session cleanup task
        startCleanupTask();

        application.logger.info("MCPCFC Server started successfully", {
            tools: application.toolRegistry.getToolCount(),
            resources: application.resourceRegistry.getResourceCount(),
            prompts: application.promptRegistry.getPromptCount()
        });

        return true;
    }

    /**
     * Application end handler
     * Clean shutdown of server components
     */
    public void function onApplicationEnd(required struct applicationScope) {
        try {
            if (structKeyExists(arguments.applicationScope, "logger")) {
                arguments.applicationScope.logger.info("MCPCFC Server shutting down");
            }

            // Stop cleanup thread
            if (structKeyExists(arguments.applicationScope, "cleanupThreadName")) {
                try {
                    cfthread(action="interrupt", name=arguments.applicationScope.cleanupThreadName);
                } catch (any e) {
                    // Thread may already be stopped
                }
            }

            // Clear sessions
            if (structKeyExists(arguments.applicationScope, "sessionManager")) {
                arguments.applicationScope.sessionManager.clearAll();
            }

        } catch (any e) {
            // Silently handle shutdown errors
        }
    }

    /**
     * Request start handler
     */
    public boolean function onRequestStart(required string targetPage) {
        // Handle application restart request
        if (structKeyExists(url, "reinit") || structKeyExists(url, "reload")) {
            onApplicationStart();
        }

        return true;
    }

    /**
     * Error handler
     */
    public void function onError(required any exception, required string eventName) {
        var errorData = {
            message: arguments.exception.message ?: "Unknown error",
            detail: arguments.exception.detail ?: "",
            type: arguments.exception.type ?: "",
            event: arguments.eventName
        };

        // Log the error
        if (structKeyExists(application, "logger")) {
            application.logger.error("Application error", errorData);
        }

        // For API requests, return JSON error
        if (findNoCase("/endpoints/", cgi.script_name)) {
            cfheader(statuscode=500);
            cfcontent(type="application/json", reset=true);
            writeOutput(serializeJson({
                jsonrpc: "2.0",
                error: {
                    code: -32603,
                    message: "Internal server error"
                },
                id: javacast("null", "")
            }));
            abort;
        }

        // For other requests, show error page
        cfheader(statuscode=500);
        cfcontent(type="text/html", reset=true);
        writeOutput("
            <!DOCTYPE html>
            <html>
            <head><title>MCPCFC Error</title></head>
            <body>
                <h1>Server Error</h1>
                <p>An error occurred processing your request.</p>
                <p>Error: #encodeForHTML(errorData.message)#</p>
                <p>Detail: #encodeForHTML(errorData.detail)#</p>
                <p>Type: #encodeForHTML(errorData.type)#</p>
            </body>
            </html>
        ");
        abort;
    }

    /**
     * Ensure all required directories exist
     */
    private void function ensureDirectories() {
        var directories = [
            application.config.tempDirectory,
            application.config.sandboxDirectory,
            application.config.logDirectory,
            application.config.libDirectory
        ];

        for (var dir in directories) {
            if (!directoryExists(dir)) {
                try {
                    directoryCreate(dir);
                } catch (any e) {
                    // Log but don't fail startup
                    if (structKeyExists(application, "logger")) {
                        application.logger.warn("Could not create directory", { path: dir, error: e.message });
                    }
                }
            }
        }
    }

    /**
     * Start the session cleanup background task
     * CF2025: Uses cfthread with action="interrupt" pattern (action="terminate" removed)
     */
    private void function startCleanupTask() {
        var threadName = "mcpcfc_session_cleanup_#createUUID()#";
        application.cleanupThreadName = threadName;

        var intervalMs = application.config.cleanupInterval;
        var ttlMs = application.config.sessionTTL;

        cfthread(
            name: threadName,
            action: "run",
            intervalMs: intervalMs,
            ttlMs: ttlMs
        ) {
            var running = true;

            while (running) {
                try {
                    // Sleep for the configured interval
                    sleep(attributes.intervalMs);

                    // Check if application scope still exists
                    if (!structKeyExists(application, "sessionManager")) {
                        running = false;
                        continue;
                    }

                    // Perform cleanup
                    var cleaned = application.sessionManager.cleanupExpired(attributes.ttlMs);

                    if (cleaned > 0 && structKeyExists(application, "logger")) {
                        application.logger.debug("Session cleanup completed", {
                            cleaned: cleaned,
                            remaining: application.sessionManager.getSessionCount()
                        });
                    }

                } catch (java.lang.InterruptedException e) {
                    // Thread was interrupted - exit gracefully
                    running = false;
                } catch (any e) {
                    // Log error but continue
                    if (structKeyExists(application, "logger")) {
                        application.logger.error("Session cleanup error", { error: e.message });
                    }
                }
            }
        }

        application.logger.debug("Session cleanup task started", {
            threadName: threadName,
            intervalMs: intervalMs,
            ttlMs: ttlMs
        });
    }
}
