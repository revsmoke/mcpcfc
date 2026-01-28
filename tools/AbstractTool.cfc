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
        var def = structNew("ordered");
        def["name"] = getName();

        // MCP 2025-11-25: title is the human-readable name
        if (len(getTitle() ?: "")) {
            def["title"] = getTitle();
        }

        if (len(getDescription() ?: "")) {
            def["description"] = getDescription();
        }

        def["inputSchema"] = getInputSchema() ?: {
            type: "object",
            properties: {}
        };

        // MCP 2025-11-25: outputSchema is optional but recommended
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
        return {
            content: [{
                type: "text",
                text: arguments.text
            }]
        };
    }

    /**
     * Create an error result
     * @message The error message
     * @return Struct with content array and isError flag
     */
    public struct function errorResult(required string message) {
        return {
            content: [{
                type: "text",
                text: arguments.message
            }],
            isError: true
        };
    }

    /**
     * Create a JSON result
     * @data The data to serialize
     * @return Struct with content array
     */
    public struct function jsonResult(required any data) {
        return {
            content: [{
                type: "text",
                text: serializeJson(arguments.data)
            }]
        };
    }

    /**
     * Create an image result (base64 encoded)
     * @data The base64 image data
     * @mimeType The image MIME type (e.g., "image/png")
     * @return Struct with content array
     */
    public struct function imageResult(required string data, required string mimeType) {
        return {
            content: [{
                type: "image",
                data: arguments.data,
                mimeType: arguments.mimeType
            }]
        };
    }

    /**
     * Create a resource result (embedded resource)
     * @uri The resource URI
     * @text The resource text content
     * @mimeType Optional MIME type
     * @return Struct with content array
     */
    public struct function resourceResult(required string uri, required string text, string mimeType = "text/plain") {
        return {
            content: [{
                type: "resource",
                resource: {
                    uri: arguments.uri,
                    text: arguments.text,
                    mimeType: arguments.mimeType
                }
            }]
        };
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
                throw(type="InvalidParams", message="Missing required parameter: #param#");
            }

            // Also check for empty strings
            if (isSimpleValue(arguments.args[param]) && !len(trim(arguments.args[param]))) {
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
                            throw(type="InvalidParams", message="Parameter '#param#' must be a string");
                        }
                        break;

                    case "numeric":
                    case "number":
                        if (!isNumeric(value)) {
                            throw(type="InvalidParams", message="Parameter '#param#' must be numeric");
                        }
                        break;

                    case "boolean":
                        if (!isBoolean(value)) {
                            throw(type="InvalidParams", message="Parameter '#param#' must be boolean");
                        }
                        break;

                    case "array":
                        if (!isArray(value)) {
                            throw(type="InvalidParams", message="Parameter '#param#' must be an array");
                        }
                        break;

                    case "struct":
                    case "object":
                        if (!isStruct(value)) {
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
