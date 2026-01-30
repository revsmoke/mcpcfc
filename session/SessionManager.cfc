/**
 * SessionManager.cfc
 * Thread-safe session management for MCP Server
 * Handles session creation, tracking, and cleanup
 */
component output="false" {

    variables.sessions = {};
    variables.lock = createObject("java", "java.util.concurrent.locks.ReentrantReadWriteLock").init();

    /**
     * Initialize the session manager
     */
    public function init() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("SessionManager init");
        }
        return this;
    }

    /**
     * Create a new session
     * @sessionId The session identifier
     * @return The created session struct
     */
    public struct function createSession(required string sessionId) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            var session = {
                id: arguments.sessionId,
                createdAt: now(),
                lastActivity: now(),
                capabilities: {},
                metadata: {},
                initialized: false
            };

            variables.sessions[arguments.sessionId] = session;

            if (structKeyExists(application, "logger")) {
                application.logger.debug("Session created", { sessionId: arguments.sessionId });
            }

            return session;
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Get a session by ID
     * @sessionId The session identifier
     * @return The session struct or null if not found
     */
    public any function getSession(required string sessionId) {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            if (structKeyExists(variables.sessions, arguments.sessionId)) {
                if (structKeyExists(application, "logger")) {
                    application.logger.debug("Session retrieved", { sessionId: arguments.sessionId });
                }
                return variables.sessions[arguments.sessionId];
            }
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Session not found", { sessionId: arguments.sessionId });
            }
            return javacast("null", "");
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Check if a session exists
     * @sessionId The session identifier
     * @return Boolean
     */
    public boolean function sessionExists(required string sessionId) {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var exists = structKeyExists(variables.sessions, arguments.sessionId);
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Session exists check", {
                    sessionId: arguments.sessionId,
                    exists: exists
                });
            }
            return exists;
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Update the last activity timestamp for a session
     * @sessionId The session identifier
     */
    public void function updateActivity(required string sessionId) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (structKeyExists(variables.sessions, arguments.sessionId)) {
                variables.sessions[arguments.sessionId].lastActivity = now();
                if (structKeyExists(application, "logger")) {
                    application.logger.debug("Session activity updated", { sessionId: arguments.sessionId });
                }
            } else if (structKeyExists(application, "logger")) {
                application.logger.debug("Session activity update skipped (not found)", {
                    sessionId: arguments.sessionId
                });
            }
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Mark a session as initialized
     * @sessionId The session identifier
     */
    public void function markInitialized(required string sessionId) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (structKeyExists(variables.sessions, arguments.sessionId)) {
                variables.sessions[arguments.sessionId].initialized = true;
                if (structKeyExists(application, "logger")) {
                    application.logger.debug("Session marked initialized", {
                        sessionId: arguments.sessionId
                    });
                }
            }
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Set session capabilities
     * @sessionId The session identifier
     * @capabilities The capabilities struct
     */
    public void function setCapabilities(required string sessionId, required struct capabilities) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (structKeyExists(variables.sessions, arguments.sessionId)) {
                variables.sessions[arguments.sessionId].capabilities = arguments.capabilities;
                if (structKeyExists(application, "logger")) {
                    application.logger.debug("Session capabilities set", {
                        sessionId: arguments.sessionId,
                        keys: structKeyArray(arguments.capabilities)
                    });
                }
            }
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Set session metadata
     * @sessionId The session identifier
     * @key The metadata key
     * @value The metadata value
     */
    public void function setMetadata(required string sessionId, required string key, required any value) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (structKeyExists(variables.sessions, arguments.sessionId)) {
                variables.sessions[arguments.sessionId].metadata[arguments.key] = arguments.value;
                if (structKeyExists(application, "logger")) {
                    application.logger.debug("Session metadata set", {
                        sessionId: arguments.sessionId,
                        key: arguments.key
                    });
                }
            }
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Remove a session
     * @sessionId The session identifier
     * @return Boolean indicating if session was found and removed
     */
    public boolean function removeSession(required string sessionId) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (structKeyExists(variables.sessions, arguments.sessionId)) {
                structDelete(variables.sessions, arguments.sessionId);

                if (structKeyExists(application, "logger")) {
                    application.logger.debug("Session removed", { sessionId: arguments.sessionId });
                }

                return true;
            }
            return false;
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Get the count of active sessions
     * @return Numeric count
     */
    public numeric function getSessionCount() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            return structCount(variables.sessions);
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Clean up expired sessions based on TTL
     * @ttlMs Time-to-live in milliseconds
     * @return Number of sessions cleaned up
     */
    public numeric function cleanupExpired(required numeric ttlMs) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            var expiredCount = 0;
            var now = now();
            var expireThreshold = dateAdd("l", -arguments.ttlMs, now);

            var sessionsToRemove = [];

            // Find expired sessions
            for (var sessionId in variables.sessions) {
                var session = variables.sessions[sessionId];
                if (dateCompare(session.lastActivity, expireThreshold) < 0) {
                    arrayAppend(sessionsToRemove, sessionId);
                }
            }

            // Remove expired sessions
            for (var sessionId in sessionsToRemove) {
                structDelete(variables.sessions, sessionId);
                expiredCount++;
            }

            if (expiredCount > 0 && structKeyExists(application, "logger")) {
                application.logger.info("Cleaned up expired sessions", { count: expiredCount });
            }

            return expiredCount;
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Get all session IDs
     * @return Array of session IDs
     */
    public array function getSessionIds() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            return structKeyArray(variables.sessions);
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Clear all sessions
     */
    public void function clearAll() {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            var count = structCount(variables.sessions);
            variables.sessions = {};

            if (count > 0 && structKeyExists(application, "logger")) {
                application.logger.info("Cleared all sessions", { count: count });
            }
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Get session statistics
     * @return Struct with session stats
     */
    public struct function getStats() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var stats = {
                totalSessions: structCount(variables.sessions),
                initializedSessions: 0,
                oldestSession: "",
                newestSession: ""
            };

            var oldestTime = "";
            var newestTime = "";

            for (var sessionId in variables.sessions) {
                var session = variables.sessions[sessionId];

                if (session.initialized) {
                    stats.initializedSessions++;
                }

                if (!isDate(oldestTime) || dateCompare(session.createdAt, oldestTime) < 0) {
                    oldestTime = session.createdAt;
                    stats.oldestSession = sessionId;
                }

                if (!isDate(newestTime) || dateCompare(session.createdAt, newestTime) > 0) {
                    newestTime = session.createdAt;
                    stats.newestSession = sessionId;
                }
            }

            if (structKeyExists(application, "logger")) {
                application.logger.debug("Session stats computed", stats);
            }
            return stats;
        } finally {
            readLock.unlock();
        }
    }
}
