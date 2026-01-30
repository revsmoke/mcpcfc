/**
 * SQLValidator.cfc
 * SQL query validation for safe SELECT queries
 * Prevents SQL injection and dangerous operations
 */
component output="false" {

    // Dangerous keywords that indicate non-SELECT operations
    variables.dangerousKeywords = [
        "INSERT", "UPDATE", "DELETE", "DROP", "TRUNCATE", "ALTER",
        "CREATE", "REPLACE", "RENAME", "GRANT", "REVOKE", "EXEC",
        "EXECUTE", "CALL", "MERGE", "LOAD", "LOCK", "UNLOCK"
    ];

    // Patterns that might indicate SQL injection attempts
    variables.injectionPatterns = [
        ";\s*--",           // Comment after semicolon
        ";\s*/\*",          // Block comment after semicolon
        "'\s*OR\s+'",       // OR injection
        "'\s*AND\s+'",      // AND injection
        "--\s*$",           // Trailing comment
        "UNION\s+ALL\s+SELECT",  // UNION injection
        "INTO\s+OUTFILE",   // File write attempt
        "INTO\s+DUMPFILE",  // File write attempt
        "LOAD_FILE",        // File read attempt
        "@@",               // System variable access
        "CHAR\s*\(",        // Character encoding bypass
        "0x[0-9a-fA-F]+",   // Hex encoding
        "BENCHMARK\s*\(",   // Timing attack
        "SLEEP\s*\(",       // Timing attack
        "WAITFOR\s+DELAY",  // SQL Server timing
        "xp_",              // SQL Server extended procedures
        "sp_"               // SQL Server stored procedures
    ];

    /**
     * Validate that a query is a safe SELECT statement
     * @query The SQL query to validate
     * @return Struct with valid (boolean) and message (string)
     */
    public struct function validateSelectQuery(required string query) {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Validating SQL query", {
                queryPreview: left(arguments.query, 100)
            });
        }
        var normalizedQuery = normalizeQuery(arguments.query);

        // Check if it starts with SELECT
        if (!reFindNoCase("^\s*SELECT\s", normalizedQuery)) {
            if (structKeyExists(application, "logger")) {
                application.logger.warn("SQL validation failed (not SELECT)", {
                    queryPreview: left(arguments.query, 100)
                });
            }
            return {
                valid: false,
                message: "Only SELECT queries are allowed"
            };
        }

        // Check for dangerous keywords
        for (var keyword in variables.dangerousKeywords) {
            // Look for keyword as a whole word
            if (reFindNoCase("\b#keyword#\b", normalizedQuery)) {
                if (structKeyExists(application, "logger")) {
                    application.logger.warn("SQL validation failed (dangerous keyword)", {
                        keyword: keyword
                    });
                }
                return {
                    valid: false,
                    message: "Dangerous keyword detected: #keyword#. Only SELECT queries are allowed."
                };
            }
        }

        // Check for multiple statements (semicolon not in string)
        if (containsMultipleStatements(normalizedQuery)) {
            if (structKeyExists(application, "logger")) {
                application.logger.warn("SQL validation failed (multiple statements)");
            }
            return {
                valid: false,
                message: "Multiple SQL statements are not allowed"
            };
        }

        // Check for injection patterns
        for (var pattern in variables.injectionPatterns) {
            if (reFindNoCase(pattern, normalizedQuery)) {
                if (structKeyExists(application, "logger")) {
                    application.logger.warn("SQL validation failed (injection pattern)", {
                        pattern: pattern
                    });
                }
                return {
                    valid: false,
                    message: "Potentially dangerous SQL pattern detected"
                };
            }
        }

        // Check for subqueries with dangerous operations
        if (containsDangerousSubquery(normalizedQuery)) {
            if (structKeyExists(application, "logger")) {
                application.logger.warn("SQL validation failed (dangerous subquery)");
            }
            return {
                valid: false,
                message: "Subquery contains non-SELECT operation"
            };
        }

        if (structKeyExists(application, "logger")) {
            application.logger.debug("SQL query validated");
        }
        return {
            valid: true,
            message: "Query is valid"
        };
    }

    /**
     * Quick check if a query is a safe SELECT (boolean only)
     * @query The SQL query to validate
     * @return Boolean
     */
    public boolean function isSafeSelectQuery(required string query) {
        var valid = validateSelectQuery(arguments.query).valid;
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Safe SELECT check", {
                valid: valid
            });
        }
        return valid;
    }

    /**
     * Normalize a query for analysis
     */
    private string function normalizeQuery(required string query) {
        var normalized = trim(arguments.query);

        // Remove excessive whitespace
        normalized = reReplace(normalized, "\s+", " ", "all");

        return normalized;
    }

    /**
     * Check if query contains multiple statements
     */
    private boolean function containsMultipleStatements(required string query) {
        // Simple check: look for semicolons not inside quotes
        var inString = false;
        var stringChar = "";
        var chars = listToArray(arguments.query, "");

        for (var i = 1; i <= arrayLen(chars); i++) {
            var char = chars[i];

            if (!inString && (char == "'" || char == '"')) {
                inString = true;
                stringChar = char;
            } else if (inString && char == stringChar) {
                // Check for escaped quote
                if (i > 1 && chars[i-1] != "\") {
                    inString = false;
                }
            } else if (!inString && char == ";") {
                // Check if there's anything after the semicolon
                var remainder = trim(mid(arguments.query, i + 1, len(arguments.query)));
                if (len(remainder) > 0 && remainder != "--") {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Check if any subquery contains dangerous operations
     */
    private boolean function containsDangerousSubquery(required string query) {
        // Find subqueries (content within parentheses that contains SELECT)
        var subqueryPattern = "\(\s*SELECT[^)]+\)";
        var subqueries = reMatchNoCase(subqueryPattern, arguments.query);

        for (var subquery in subqueries) {
            // Remove outer parentheses
            var innerQuery = mid(subquery, 2, len(subquery) - 2);

            // Check for dangerous keywords in subquery
            for (var keyword in variables.dangerousKeywords) {
                if (reFindNoCase("\b#keyword#\b", innerQuery)) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Escape a value for safe SQL use (parameterized queries are still preferred)
     * @value The value to escape
     * @return Escaped string
     */
    public string function escapeValue(required string value) {
        var escaped = arguments.value;

        // Escape single quotes by doubling them
        escaped = replace(escaped, "'", "''", "all");

        // Remove null bytes
        escaped = replace(escaped, chr(0), "", "all");

        if (structKeyExists(application, "logger")) {
            application.logger.debug("Escaped SQL value", {
                length: len(arguments.value)
            });
        }
        return escaped;
    }

    /**
     * Validate a table name
     * @tableName The table name to validate
     * @return Boolean
     */
    public boolean function isValidTableName(required string tableName) {
        // Table names should be alphanumeric with underscores, no spaces or special chars
        var valid = reFindNoCase("^[a-zA-Z_][a-zA-Z0-9_]*$", arguments.tableName) > 0;
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Table name validation", {
                tableName: arguments.tableName,
                valid: valid
            });
        }
        return valid;
    }

    /**
     * Validate a column name
     * @columnName The column name to validate
     * @return Boolean
     */
    public boolean function isValidColumnName(required string columnName) {
        // Column names should be alphanumeric with underscores
        // Also allow qualified names like table.column
        var valid = reFindNoCase("^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)?$", arguments.columnName) > 0;
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Column name validation", {
                columnName: arguments.columnName,
                valid: valid
            });
        }
        return valid;
    }

    /**
     * Get list of dangerous keywords
     * @return Array
     */
    public array function getDangerousKeywords() {
        return variables.dangerousKeywords;
    }
}
