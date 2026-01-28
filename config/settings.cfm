<cfscript>
/**
 * MCPCFC Configuration Settings
 * ColdFusion 2025 MCP Server - Configuration File
 * Protocol Version: 2025-11-25
 */

// Server identity
application.config = {
    // Server identification
    serverName: "coldfusion-mcp-server",
    serverVersion: "2.0.0",
    protocolVersion: "2025-11-25",

    // URLs
    baseUrl: "https://mcpcfc.local",

    // Security settings
    authRequired: false,
    authToken: hash(createUUID() & now(), "SHA-256"),
    allowedOrigins: ["*"],

    // SendGrid configuration
    sendGridApiKey: server.system.environment.SENDGRID_API_KEY ?: "",
    sendGridApiUrl: "https://api.sendgrid.com/v3/mail/send",
    defaultFromEmail: "mcpcfc@yourdomain.com",
    defaultFromName: "MCPCFC Server",

    // Session management
    sessionTTL: 3600000,      // 1 hour in milliseconds
    cleanupInterval: 300000,   // 5 minutes in milliseconds

    // Resource limits
    maxPdfSize: 10485760,      // 10MB
    maxQueryResults: 1000,
    maxEmailsPerMinute: 10,
    maxFileSize: 5242880,      // 5MB for file operations
    httpClientTimeout: 30000,  // 30 seconds

    // Paths
    tempDirectory: expandPath("./temp/"),
    libDirectory: expandPath("./lib/"),
    sandboxDirectory: expandPath("./sandbox/"),

    // Database
    defaultDatasource: "mcpcfc_ds",

    // Logging
    logLevel: "INFO",  // DEBUG, INFO, WARN, ERROR
    logDirectory: expandPath("./logs/")
};

// Ensure log directory exists
if (!directoryExists(application.config.logDirectory)) {
    directoryCreate(application.config.logDirectory);
}
</cfscript>
