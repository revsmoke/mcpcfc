/**
 * AbstractTool.cfc
 * Base class for all MCP tools
 * All tools must extend this class
 */
component output="false" accessors="true" {

    property name="name" type="string";
    property name="title" type="string";
    property name="description" type="string";
    property name="inputSchema" type="struct";
    property name="outputSchema" type="struct";

    /**
     * Initialize the tool
     * Subclasses should override this and call super.init()
     */
    public function init() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Tool init", { tool: getName() ?: "" });
        }
        return this;
    }

    /**
     * Execute the tool
     * Subclasses MUST override this method
     * @arguments The tool arguments struct
     * @return The tool result struct
     */
    public struct function execute(required struct toolArgs) {
        throw(type="AbstractMethod", message="Tool '#getName()#' must implement execute()");
    }

    /**
     * Get the tool definition for MCP tools/list
     * @return Struct conforming to MCP tool schema
     */
    public struct function getDefinition() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Building tool definition", { tool: getName() ?: "" });
        }
        var def = structNew("ordered");
        def["name"] = getName();

        // MCP: title is a human-readable display name (optional)
        if (len(getTitle() ?: "")) {
            def["title"] = getTitle();
        }

        if (len(getDescription() ?: "")) {
            def["description"] = getDescription();
        }

        var inputSchema = getInputSchema();
        if (isNull(inputSchema)) {
            inputSchema = structNew("ordered");
            inputSchema["type"] = "object";
            inputSchema["properties"] = structNew("ordered");
        }
        def["inputSchema"] = inputSchema;

        // MCP: outputSchema is optional but recommended
        if (!isNull(getOutputSchema())) {
            def["outputSchema"] = getOutputSchema();
        }

        return def;
    }

    /**
     * Create a text result
     * @text The text content
     * @return Struct with content array
     */
    public struct function textResult(required string text) {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Tool text result", { tool: getName() ?: "" });
        }
        var item = structNew("ordered");
        item["type"] = "text";
        item["text"] = arguments.text;

        var result = structNew("ordered");
        result["content"] = [item];
        return result;
    }

    /**
     * Create an error result
     * @message The error message
     * @return Struct with content array and isError flag
     */
    public struct function errorResult(required string message) {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Tool error result", {
                tool: getName() ?: "",
                message: arguments.message
            });
        }
        var item = structNew("ordered");
        item["type"] = "text";
        item["text"] = arguments.message;

        var result = structNew("ordered");
        result["content"] = [item];
        result["isError"] = true;
        return result;
    }

    /**
     * Create a JSON result
     * @data The data to serialize
     * @return Struct with content array
     */
    public struct function jsonResult(required any data) {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Tool json result", { tool: getName() ?: "" });
        }
        var item = structNew("ordered");
        item["type"] = "text";
        item["text"] = serializeJson(arguments.data);

        var result = structNew("ordered");
        result["content"] = [item];
        return result;
    }

    /**
     * Create an image result (base64 encoded)
     * @data The base64 image data
     * @mimeType The image MIME type (e.g., "image/png")
     * @return Struct with content array
     */
    public struct function imageResult(required string data, required string mimeType) {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Tool image result", { tool: getName() ?: "" });
        }
        var item = structNew("ordered");
        item["type"] = "image";
        item["data"] = arguments.data;
        item["mimeType"] = arguments.mimeType;

        var result = structNew("ordered");
        result["content"] = [item];
        return result;
    }

    /**
     * Create a resource result (embedded resource)
     * @uri The resource URI
     * @text The resource text content
     * @mimeType Optional MIME type
     * @return Struct with content array
     */
    public struct function resourceResult(required string uri, required string text, string mimeType = "text/plain") {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Tool resource result", {
                tool: getName() ?: "",
                uri: arguments.uri
            });
        }
        var resource = structNew("ordered");
        resource["uri"] = arguments.uri;
        resource["text"] = arguments.text;
        resource["mimeType"] = arguments.mimeType;

        var item = structNew("ordered");
        item["type"] = "resource";
        item["resource"] = resource;

        var result = structNew("ordered");
        result["content"] = [item];
        return result;
    }

    /**
     * Validate required parameters
     * @args The arguments struct
     * @params Array of required parameter names
     * @throws InvalidParams if any required parameter is missing
     */
    public void function validateRequired(required struct args, required array params) {
        for (var param in arguments.params) {
            if (!structKeyExists(arguments.args, param)) {
                if (structKeyExists(application, "logger")) {
                    application.logger.warn("Missing required parameter", {
                        tool: getName() ?: "",
                        param: param
                    });
                }
                throw(type="InvalidParams", message="Missing required parameter: #param#");
            }

            // Also check for empty strings
            if (isSimpleValue(arguments.args[param]) && !len(trim(arguments.args[param]))) {
                if (structKeyExists(application, "logger")) {
                    application.logger.warn("Empty required parameter", {
                        tool: getName() ?: "",
                        param: param
                    });
                }
                throw(type="InvalidParams", message="Parameter '#param#' cannot be empty");
            }
        }
    }

    /**
     * Validate parameter types
     * @args The arguments struct
     * @typeMap Struct mapping parameter names to expected types
     */
    public void function validateTypes(required struct args, required struct typeMap) {
        for (var param in arguments.typeMap) {
            if (structKeyExists(arguments.args, param)) {
                var expectedType = arguments.typeMap[param];
                var value = arguments.args[param];

                switch(expectedType) {
                    case "string":
                        if (!isSimpleValue(value)) {
                            if (structKeyExists(application, "logger")) {
                                application.logger.warn("Parameter type mismatch", {
                                    tool: getName() ?: "",
                                    param: param,
                                    expected: expectedType
                                });
                            }
                            throw(type="InvalidParams", message="Parameter '#param#' must be a string");
                        }
                        break;

                    case "numeric":
                    case "number":
                        if (!isNumeric(value)) {
                            if (structKeyExists(application, "logger")) {
                                application.logger.warn("Parameter type mismatch", {
                                    tool: getName() ?: "",
                                    param: param,
                                    expected: expectedType
                                });
                            }
                            throw(type="InvalidParams", message="Parameter '#param#' must be numeric");
                        }
                        break;

                    case "boolean":
                        if (!isBoolean(value)) {
                            if (structKeyExists(application, "logger")) {
                                application.logger.warn("Parameter type mismatch", {
                                    tool: getName() ?: "",
                                    param: param,
                                    expected: expectedType
                                });
                            }
                            throw(type="InvalidParams", message="Parameter '#param#' must be boolean");
                        }
                        break;

                    case "array":
                        if (!isArray(value)) {
                            if (structKeyExists(application, "logger")) {
                                application.logger.warn("Parameter type mismatch", {
                                    tool: getName() ?: "",
                                    param: param,
                                    expected: expectedType
                                });
                            }
                            throw(type="InvalidParams", message="Parameter '#param#' must be an array");
                        }
                        break;

                    case "struct":
                    case "object":
                        if (!isStruct(value)) {
                            if (structKeyExists(application, "logger")) {
                                application.logger.warn("Parameter type mismatch", {
                                    tool: getName() ?: "",
                                    param: param,
                                    expected: expectedType
                                });
                            }
                            throw(type="InvalidParams", message="Parameter '#param#' must be an object");
                        }
                        break;
                }
            }
        }
    }

    /**
     * Get a parameter value with a default
     * @args The arguments struct
     * @param The parameter name
     * @defaultValue The default value if not provided
     * @return The parameter value or default
     */
    public any function getParam(required struct args, required string param, any defaultValue = "") {
        if (structKeyExists(arguments.args, arguments.param)) {
            return arguments.args[arguments.param];
        }
        return arguments.defaultValue;
    }

    /**
     * Log tool execution
     * @message The log message
     * @data Optional data to include
     */
    public void function logExecution(required string message, struct data = {}) {
        if (structKeyExists(application, "logger")) {
            arguments.data.tool = getName();
            application.logger.debug(arguments.message, arguments.data);
        }
    }
}
