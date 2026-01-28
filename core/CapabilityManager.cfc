/**
 * CapabilityManager.cfc
 * Manages MCP Protocol Capability Negotiation
 * Protocol Version: 2025-11-25
 */
component output="false" {

    /**
     * Get the server's capabilities for the initialize response
     * @return Struct of server capabilities
     */
    public struct function getServerCapabilities() {
        var capabilities = structNew("ordered");

        // Tools capability
        capabilities["tools"] = structNew("ordered");
        capabilities.tools["listChanged"] = true;

        // Resources capability
        capabilities["resources"] = structNew("ordered");
        capabilities.resources["subscribe"] = false;
        capabilities.resources["listChanged"] = true;

        // Prompts capability
        capabilities["prompts"] = structNew("ordered");
        capabilities.prompts["listChanged"] = true;

        // Logging capability
        capabilities["logging"] = structNew("ordered");

        // Experimental features (MCP 2025-11-25)
        capabilities["experimental"] = structNew("ordered");

        return capabilities;
    }

    /**
     * Validate client capabilities during initialize
     * @clientCapabilities The capabilities sent by the client
     * @return Boolean indicating if capabilities are compatible
     */
    public boolean function validateClientCapabilities(struct clientCapabilities = {}) {
        // For now, accept any client capabilities
        // In the future, we could enforce minimum requirements

        if (structKeyExists(arguments.clientCapabilities, "experimental")) {
            application.logger.debug("Client supports experimental features", {
                experimental: arguments.clientCapabilities.experimental
            });
        }

        return true;
    }

    /**
     * Check if a specific capability is supported
     * @capability The capability name (e.g., "tools", "resources")
     * @feature The specific feature within the capability
     * @return Boolean indicating support
     */
    public boolean function supportsCapability(required string capability, string feature = "") {
        var caps = getServerCapabilities();

        if (!structKeyExists(caps, arguments.capability)) {
            return false;
        }

        if (len(arguments.feature)) {
            return structKeyExists(caps[arguments.capability], arguments.feature)
                && caps[arguments.capability][arguments.feature];
        }

        return true;
    }

    /**
     * Get supported protocol versions
     * @return Array of supported protocol version strings
     */
    public array function getSupportedProtocolVersions() {
        return ["2025-11-25"];
    }

    /**
     * Check if a protocol version is supported
     * @version The protocol version string to check
     * @return Boolean indicating support
     */
    public boolean function isProtocolVersionSupported(required string version) {
        return arrayFindNoCase(getSupportedProtocolVersions(), arguments.version) > 0;
    }

    /**
     * Negotiate the best protocol version with client
     * @clientVersion The client's requested protocol version
     * @return The negotiated protocol version or empty string if incompatible
     */
    public string function negotiateProtocolVersion(required string clientVersion) {
        var supported = getSupportedProtocolVersions();

        // If client version is directly supported, use it
        if (arrayFindNoCase(supported, arguments.clientVersion) > 0) {
            return arguments.clientVersion;
        }

        // Return our latest supported version as fallback
        // The spec says server should return its supported version
        return supported[1];
    }
}
