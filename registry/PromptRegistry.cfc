/**
 * PromptRegistry.cfc
 * Manages MCP prompt templates
 * Protocol Version: 2025-11-25
 */
component output="false" {

    variables.prompts = {};
    variables.lock = createObject("java", "java.util.concurrent.locks.ReentrantReadWriteLock").init();

    /**
     * Initialize the registry
     */
    public function init() {
        return this;
    }

    /**
     * Register a prompt template
     * @prompt Struct with name, description, and optional arguments array
     */
    public void function register(required struct prompt) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (!structKeyExists(arguments.prompt, "name")) {
                throw(type="InvalidPrompt", message="Prompt must have a name");
            }

            var name = arguments.prompt.name;

            // Build the prompt definition
            var def = structNew("ordered");
            def["name"] = name;

            if (structKeyExists(arguments.prompt, "description")) {
                def["description"] = arguments.prompt.description;
            }

            if (structKeyExists(arguments.prompt, "arguments")) {
                def["arguments"] = [];
                for (var arg in arguments.prompt.arguments) {
                    var argDef = structNew("ordered");
                    argDef["name"] = arg.name;

                    if (structKeyExists(arg, "description")) {
                        argDef["description"] = arg.description;
                    }

                    if (structKeyExists(arg, "required")) {
                        argDef["required"] = arg.required;
                    }

                    arrayAppend(def.arguments, argDef);
                }
            }

            variables.prompts[name] = def;

        } finally {
            writeLock.unlock();
        }
    }

    /**
     * Unregister a prompt
     * @name The prompt name
     * @return Boolean indicating if found and removed
     */
    public boolean function unregister(required string name) {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            if (structKeyExists(variables.prompts, arguments.name)) {
                structDelete(variables.prompts, arguments.name);
                return true;
            }
            return false;
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * List all registered prompts
     * @return Array of prompt definitions
     */
    public array function list() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            var promptList = [];

            for (var name in variables.prompts) {
                arrayAppend(promptList, variables.prompts[name]);
            }

            // Sort by name for consistent output
            arraySort(promptList, function(a, b) {
                return compareNoCase(a.name, b.name);
            });

            return promptList;
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Get a prompt by name and render it with arguments
     * @name The prompt name
     * @arguments Struct of argument values
     * @return Struct with description and messages array
     */
    public struct function get(required string name, struct arguments = {}) {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            if (!structKeyExists(variables.prompts, arguments.name)) {
                throw(type="PromptNotFound", message="Prompt not found: #arguments.name#");
            }

            var prompt = variables.prompts[arguments.name];

            // Validate required arguments
            if (structKeyExists(prompt, "arguments")) {
                for (var argDef in prompt.arguments) {
                    if ((argDef.required ?: false) && !structKeyExists(arguments.arguments, argDef.name)) {
                        throw(type="InvalidParams", message="Missing required argument: #argDef.name#");
                    }
                }
            }

            // Generate the prompt content
            var result = structNew("ordered");

            if (structKeyExists(prompt, "description")) {
                result["description"] = prompt.description;
            }

            result["messages"] = generatePromptMessages(arguments.name, arguments.arguments);

            return result;

        } finally {
            readLock.unlock();
        }
    }

    /**
     * Generate prompt messages based on prompt name and arguments
     */
    private array function generatePromptMessages(required string promptName, struct args = {}) {
        var messages = [];

        switch(arguments.promptName) {
            case "sql_query_helper":
                var table = arguments.args.table ?: "table_name";
                var columns = arguments.args.columns ?: "*";

                arrayAppend(messages, {
                    role: "user",
                    content: {
                        type: "text",
                        text: "Help me write a safe SQL SELECT query for the table '#table#' selecting columns: #columns#. " &
                              "The query should be read-only and avoid any SQL injection vulnerabilities."
                    }
                });
                break;

            case "email_composer":
                var purpose = arguments.args.purpose ?: "general";
                var tone = arguments.args.tone ?: "professional";

                arrayAppend(messages, {
                    role: "user",
                    content: {
                        type: "text",
                        text: "Help me compose an email for the following purpose: #purpose#. " &
                              "The tone should be #tone#. Please provide a subject line and body."
                    }
                });
                break;

            default:
                // Generic prompt
                arrayAppend(messages, {
                    role: "user",
                    content: {
                        type: "text",
                        text: "Prompt: #arguments.promptName#"
                    }
                });
        }

        return messages;
    }

    /**
     * Check if a prompt exists
     * @name The prompt name
     * @return Boolean
     */
    public boolean function promptExists(required string name) {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            return structKeyExists(variables.prompts, arguments.name);
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Get the count of registered prompts
     * @return Numeric count
     */
    public numeric function getPromptCount() {
        var readLock = variables.lock.readLock();
        readLock.lock();

        try {
            return structCount(variables.prompts);
        } finally {
            readLock.unlock();
        }
    }

    /**
     * Clear all registered prompts
     */
    public void function clear() {
        var writeLock = variables.lock.writeLock();
        writeLock.lock();

        try {
            variables.prompts = {};
        } finally {
            writeLock.unlock();
        }
    }
}
