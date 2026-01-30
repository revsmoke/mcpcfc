/**
 * InputValidator.cfc
 * General input validation utilities
 */
component output="false" {

    /**
     * Validate an email address
     * @email The email address to validate
     * @return Boolean
     */
    public boolean function isValidEmail(required string email) {
        // RFC 5322 compliant regex (simplified)
        var emailPattern = "^[a-zA-Z0-9.!##$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$";
        var valid = reFindNoCase(emailPattern, trim(arguments.email)) > 0;
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Email validation", {
                email: arguments.email,
                valid: valid
            });
        }
        return valid;
    }

    /**
     * Validate a URL
     * @url The URL to validate
     * @allowedSchemes Array of allowed schemes (default: ["http", "https"])
     * @return Boolean
     */
    public boolean function isValidUrl(required string url, array allowedSchemes = ["http", "https"]) {
        var urlPattern = "^(#arrayToList(arguments.allowedSchemes, '|')#)://[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+";
        var valid = reFindNoCase(urlPattern, trim(arguments.url)) > 0;
        if (structKeyExists(application, "logger")) {
            application.logger.debug("URL validation", {
                url: arguments.url,
                valid: valid
            });
        }
        return valid;
    }

    /**
     * Sanitize a string for safe output
     * @input The string to sanitize
     * @return Sanitized string
     */
    public string function sanitizeString(required string input) {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Sanitizing string", { length: len(arguments.input) });
        }
        return encodeForHTML(arguments.input);
    }

    /**
     * Validate string length
     * @input The string to validate
     * @minLength Minimum length (optional)
     * @maxLength Maximum length (optional)
     * @return Boolean
     */
    public boolean function isValidLength(required string input, numeric minLength = 0, numeric maxLength = 0) {
        var len = len(arguments.input);

        if (arguments.minLength > 0 && len < arguments.minLength) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Length validation failed (too short)", {
                    length: len,
                    minLength: arguments.minLength
                });
            }
            return false;
        }

        if (arguments.maxLength > 0 && len > arguments.maxLength) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Length validation failed (too long)", {
                    length: len,
                    maxLength: arguments.maxLength
                });
            }
            return false;
        }

        if (structKeyExists(application, "logger")) {
            application.logger.debug("Length validation passed", { length: len });
        }
        return true;
    }

    /**
     * Validate that a value is in an allowed list
     * @value The value to check
     * @allowedValues Array of allowed values
     * @caseSensitive Whether to do case-sensitive comparison
     * @return Boolean
     */
    public boolean function isAllowedValue(required any value, required array allowedValues, boolean caseSensitive = false) {
        if (arguments.caseSensitive) {
            var allowed = arrayFind(arguments.allowedValues, arguments.value) > 0;
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Allowed value check", {
                    value: arguments.value,
                    allowed: allowed
                });
            }
            return allowed;
        } else {
            var allowed = arrayFindNoCase(arguments.allowedValues, arguments.value) > 0;
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Allowed value check", {
                    value: arguments.value,
                    allowed: allowed
                });
            }
            return allowed;
        }
    }

    /**
     * Validate a filename (no path traversal, no dangerous characters)
     * @filename The filename to validate
     * @return Boolean
     */
    public boolean function isValidFilename(required string filename) {
        // Check for path traversal attempts
        if (findNoCase("..", arguments.filename)) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Filename validation failed (traversal)", {
                    filename: arguments.filename
                });
            }
            return false;
        }

        // Check for path separators
        if (find("/", arguments.filename) || find("\", arguments.filename)) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Filename validation failed (separator)", {
                    filename: arguments.filename
                });
            }
            return false;
        }

        // Check for valid characters (alphanumeric, dash, underscore, dot)
        var valid = reFindNoCase("^[a-zA-Z0-9._-]+$", arguments.filename) > 0;
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Filename validation", {
                filename: arguments.filename,
                valid: valid
            });
        }
        return valid;
    }

    /**
     * Validate numeric value is in range
     * @value The value to check
     * @min Minimum value (optional)
     * @max Maximum value (optional)
     * @return Boolean
     */
    public boolean function isInRange(required numeric value, numeric min = "", numeric max = "") {
        if (isNumeric(arguments.min) && arguments.value < arguments.min) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Range validation failed (below min)", {
                    value: arguments.value,
                    min: arguments.min
                });
            }
            return false;
        }

        if (isNumeric(arguments.max) && arguments.value > arguments.max) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Range validation failed (above max)", {
                    value: arguments.value,
                    max: arguments.max
                });
            }
            return false;
        }

        if (structKeyExists(application, "logger")) {
            application.logger.debug("Range validation passed", { value: arguments.value });
        }
        return true;
    }

    /**
     * Validate a UUID
     * @uuid The UUID to validate
     * @return Boolean
     */
    public boolean function isValidUUID(required string uuid) {
        var uuidPattern = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$";
        var valid = reFindNoCase(uuidPattern, trim(arguments.uuid)) > 0;
        if (structKeyExists(application, "logger")) {
            application.logger.debug("UUID validation", {
                uuid: arguments.uuid,
                valid: valid
            });
        }
        return valid;
    }

    /**
     * Validate JSON string
     * @json The JSON string to validate
     * @return Boolean
     */
    public boolean function isValidJson(required string json) {
        try {
            deserializeJson(arguments.json);
            if (structKeyExists(application, "logger")) {
                application.logger.debug("JSON validation passed", {
                    length: len(arguments.json)
                });
            }
            return true;
        } catch (any e) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("JSON validation failed", {
                    error: e.message
                });
            }
            return false;
        }
    }

    /**
     * Strip potentially dangerous HTML tags
     * @input The HTML to clean
     * @allowedTags Array of allowed tag names
     * @return Cleaned string
     */
    public string function stripDangerousTags(required string input, array allowedTags = []) {
        var result = arguments.input;

        // Remove script tags
        result = reReplaceNoCase(result, "<script[^>]*>.*?</script>", "", "all");

        // Remove style tags
        result = reReplaceNoCase(result, "<style[^>]*>.*?</style>", "", "all");

        // Remove event handlers
        result = reReplaceNoCase(result, "\s+on\w+\s*=\s*[""'][^""']*[""']", "", "all");

        // Remove javascript: URLs
        result = reReplaceNoCase(result, "javascript:", "", "all");

        if (structKeyExists(application, "logger")) {
            application.logger.debug("Stripped dangerous tags", { length: len(result) });
        }
        return result;
    }

    /**
     * Validate IP address (IPv4)
     * @ip The IP address to validate
     * @return Boolean
     */
    public boolean function isValidIPv4(required string ip) {
        var ipPattern = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
        var valid = reFindNoCase(ipPattern, trim(arguments.ip)) > 0;
        if (structKeyExists(application, "logger")) {
            application.logger.debug("IPv4 validation", {
                ip: arguments.ip,
                valid: valid
            });
        }
        return valid;
    }

    /**
     * Check if IP is private/internal
     * @ip The IP address to check
     * @return Boolean
     */
    public boolean function isPrivateIP(required string ip) {
        // Localhost
        if (arguments.ip == "127.0.0.1" || arguments.ip == "localhost") {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Private IP check", {
                    ip: arguments.ip,
                    isPrivate: true
                });
            }
            return true;
        }

        // 10.x.x.x
        if (reFindNoCase("^10\.\d+\.\d+\.\d+$", arguments.ip)) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Private IP check", {
                    ip: arguments.ip,
                    isPrivate: true
                });
            }
            return true;
        }

        // 172.16-31.x.x
        if (reFindNoCase("^172\.(1[6-9]|2[0-9]|3[0-1])\.\d+\.\d+$", arguments.ip)) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Private IP check", {
                    ip: arguments.ip,
                    isPrivate: true
                });
            }
            return true;
        }

        // 192.168.x.x
        if (reFindNoCase("^192\.168\.\d+\.\d+$", arguments.ip)) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Private IP check", {
                    ip: arguments.ip,
                    isPrivate: true
                });
            }
            return true;
        }

        if (structKeyExists(application, "logger")) {
            application.logger.debug("Private IP check", {
                ip: arguments.ip,
                isPrivate: false
            });
        }
        return false;
    }
}
