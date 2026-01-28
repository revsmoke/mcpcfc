/**
 * ResourceRegistry.cfc
 * Manages MCP resources (URIs that provide data to the client)
 * Protocol Version: 2025-11-25
 */
component output="false" {

    variables.resources = {};
    variables.resourceTemplates = {};
    variables.lock = createObject("java", "java.util.concurrent.locks.ReentrantReadWriteLock").init();

    /**
     * Initialize the registry
     */
    public function init() {
        return this;
    }

    /**
     * Register a resource
     * @resource Struct with uri, name, description, mimeType, and optional annotations
     */
    public void function register(required struct resource) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (!structKeyExists(arguments.resource, "uri")) {
                throw(type="InvalidResource", message="Resource must have a uri");
            }

            var uri = arguments.resource.uri;

            // Build the resource definition
            var def = structNew("ordered");
            def["uri"] = uri;
            def["name"] = arguments.resource.name ?: uri;

            if (structKeyExists(arguments.resource, "description")) {
                def["description"] = arguments.resource.description;
            }

            if (structKeyExists(arguments.resource, "mimeType")) {
                def["mimeType"] = arguments.resource.mimeType;
            }

            // MCP 2025-11-25: Resource annotations
            if (structKeyExists(arguments.resource, "annotations")) {
                def["annotations"] = arguments.resource.annotations;
            }

            variables.resources[uri] = def;

        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Register a resource template (RFC6570 URI template)
     * @template Struct with uriTemplate, name, description, mimeType
     */
    public void function registerTemplate(required struct template) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (!structKeyExists(arguments.template, "uriTemplate")) {
                throw(type="InvalidTemplate", message="Template must have a uriTemplate");
            }

            var uriTemplate = arguments.template.uriTemplate;

            var def = structNew("ordered");
            def["uriTemplate"] = uriTemplate;
            def["name"] = arguments.template.name ?: uriTemplate;

            if (structKeyExists(arguments.template, "description")) {
                def["description"] = arguments.template.description;
            }

            if (structKeyExists(arguments.template, "mimeType")) {
                def["mimeType"] = arguments.template.mimeType;
            }

            variables.resourceTemplates[uriTemplate] = def;

        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Unregister a resource
     * @uri The resource URI
     * @return Boolean indicating if found and removed
     */
    public boolean function unregister(required string uri) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (structKeyExists(variables.resources, arguments.uri)) {
                structDelete(variables.resources, arguments.uri);
                return true;
            }
            return false;
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * List all registered resources
     * @return Array of resource definitions
     */
    public array function list() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var resourceList = [];

            for (var uri in variables.resources) {
                arrayAppend(resourceList, variables.resources[uri]);
            }

            // Sort by URI for consistent output
            arraySort(resourceList, function(a, b) {
                return compareNoCase(a.uri, b.uri);
            });

            return resourceList;
        } finally {
            readLock.unlock();
        }
    }

    /**
     * List all resource templates
     * @return Array of template definitions
     */
    public array function listTemplates() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var templateList = [];

            for (var uriTemplate in variables.resourceTemplates) {
                arrayAppend(templateList, variables.resourceTemplates[uriTemplate]);
            }

            return templateList;
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Read a resource by URI
     * @uri The resource URI
     * @return Struct with contents array
     */
    public struct function read(required string uri) {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            if (!structKeyExists(variables.resources, arguments.uri)) {
                throw(type="ResourceNotFound", message="Resource not found: #arguments.uri#");
            }

            var resource = variables.resources[arguments.uri];
            var contents = [];

            // Handle different resource types
            if (arguments.uri == "mcpcfc://server/info") {
                arrayAppend(contents, {
                    uri: arguments.uri,
                    mimeType: "application/json",
                    text: serializeJson(application.mcpServer.getStatus())
                });
            } else if (arguments.uri == "mcpcfc://server/config") {
                // Return sanitized config (hide sensitive values)
                var safeConfig = duplicate(application.config);
                safeConfig.sendGridApiKey = len(safeConfig.sendGridApiKey) ? "[CONFIGURED]" : "[NOT SET]";
                safeConfig.authToken = "[HIDDEN]";

                arrayAppend(contents, {
                    uri: arguments.uri,
                    mimeType: "application/json",
                    text: serializeJson(safeConfig)
                });
            } else {
                // Generic resource - return metadata only
                arrayAppend(contents, {
                    uri: arguments.uri,
                    mimeType: resource.mimeType ?: "text/plain",
                    text: "Resource: #resource.name#"
                });
            }

            return { contents: contents };

        } finally {
            readLock.unlock();
        }
    }

    /**
     * Check if a resource exists
     * @uri The resource URI
     * @return Boolean
     */
    public boolean function resourceExists(required string uri) {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            return structKeyExists(variables.resources, arguments.uri);
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Get the count of registered resources
     * @return Numeric count
     */
    public numeric function getResourceCount() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            return structCount(variables.resources);
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Clear all registered resources
     */
    public void function clear() {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            variables.resources = {};
            variables.resourceTemplates = {};
        } finally {
            writeLock.unlock();
        }
    }
}
