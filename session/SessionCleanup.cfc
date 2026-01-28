/**
 * SessionCleanup.cfc
 * Handles scheduled cleanup of expired sessions
 * Uses CF2025 thread management
 */
component output="false" {

    /**
     * Initialize the cleanup handler
     */
    public function init() {
        return this;
    }

    /**
     * Start the cleanup thread
     * @intervalMs Cleanup interval in milliseconds
     * @ttlMs Session time-to-live in milliseconds
     * @return The thread name
     */
    public string function startCleanupThread(required numeric intervalMs, required numeric ttlMs) {
        var threadName = "mcpcfc_session_cleanup_#createUUID()#";

        // Store thread name in application scope for management
        application.cleanupThreadName = threadName;

        cfthread(name=threadName, action="run", intervalMs=arguments.intervalMs, ttlMs=arguments.ttlMs) {
            var running = true;

            while (running) {
                try {
                    // Sleep for the interval
                    sleep(attributes.intervalMs);

                    // Check if we should continue
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
                    if (structKeyExists(application, "logger")) {
                        application.logger.info("Session cleanup thread interrupted, stopping");
                    }
                } catch (any e) {
                    // Log error but continue
                    if (structKeyExists(application, "logger")) {
                        application.logger.error("Session cleanup error", {
                            error: e.message,
                            detail: e.detail ?: ""
                        });
                    }
                }
            }
        }

        if (structKeyExists(application, "logger")) {
            application.logger.info("Session cleanup thread started", {
                threadName: threadName,
                intervalMs: arguments.intervalMs,
                ttlMs: arguments.ttlMs
            });
        }

        return threadName;
    }

    /**
     * Stop the cleanup thread
     * CF2025: Uses action="interrupt" (action="terminate" was removed)
     */
    public void function stopCleanupThread() {
        if (structKeyExists(application, "cleanupThreadName")) {
            try {
                cfthread(action="interrupt", name=application.cleanupThreadName);

                if (structKeyExists(application, "logger")) {
                    application.logger.info("Session cleanup thread interrupted", {
                        threadName: application.cleanupThreadName
                    });
                }
            } catch (any e) {
                // Thread may already be stopped or doesn't exist
                if (structKeyExists(application, "logger")) {
                    application.logger.warn("Could not interrupt cleanup thread", {
                        error: e.message
                    });
                }
            }

            structDelete(application, "cleanupThreadName");
        }
    }

    /**
     * Check if the cleanup thread is running
     * @return Boolean
     */
    public boolean function isCleanupThreadRunning() {
        if (!structKeyExists(application, "cleanupThreadName")) {
            return false;
        }

        try {
            var threadStatus = cfthread[application.cleanupThreadName].status ?: "";
            return threadStatus == "RUNNING";
        } catch (any e) {
            return false;
        }
    }

    /**
     * Run a single cleanup cycle (for manual invocation)
     * @ttlMs Session time-to-live in milliseconds
     * @return Number of sessions cleaned
     */
    public numeric function runCleanupNow(required numeric ttlMs) {
        if (structKeyExists(application, "sessionManager")) {
            return application.sessionManager.cleanupExpired(arguments.ttlMs);
        }
        return 0;
    }

    /**
     * Get cleanup statistics
     * @return Struct with cleanup stats
     */
    public struct function getStats() {
        return {
            threadRunning: isCleanupThreadRunning(),
            threadName: application.cleanupThreadName ?: "",
            currentSessionCount: structKeyExists(application, "sessionManager")
                ? application.sessionManager.getSessionCount()
                : 0
        };
    }
}
