/**
 * HelloTool.cfc
 * Simple greeting tool for testing and demonstration
 */
component extends="AbstractTool" output="false" {

    /**
     * Initialize the tool
     */
    public function init() {
        setName("hello");
        setTitle("Hello Greeting");
        setDescription("Returns a friendly greeting for the specified name. Useful for testing the MCP connection.");

        setInputSchema({
            type: "object",
            properties: {
                name: {
                    type: "string",
                    description: "The name to greet"
                }
            },
            required: ["name"]
        });

        setOutputSchema({
            type: "object",
            properties: {
                greeting: {
                    type: "string",
                    description: "The greeting message"
                }
            }
        });

        return this;
    }

    /**
     * Execute the greeting
     * @toolArgs The tool arguments
     * @return The greeting result
     */
    public struct function execute(required struct toolArgs) {
        validateRequired(arguments.toolArgs, ["name"]);

        var name = trim(arguments.toolArgs.name);
        logExecution("Greeting requested", {
            nameLength: len(name)
        });

        // Sanitize the name (basic XSS prevention)
        name = encodeForHTML(name);

        // Generate greeting based on time of day
        var hour = hour(now());
        var timeGreeting = "Hello";

        if (hour >= 5 && hour < 12) {
            timeGreeting = "Good morning";
        } else if (hour >= 12 && hour < 17) {
            timeGreeting = "Good afternoon";
        } else if (hour >= 17 && hour < 21) {
            timeGreeting = "Good evening";
        } else {
            timeGreeting = "Hello";
        }

        var greeting = "#timeGreeting#, #name#! Welcome to the MCPCFC server.";

        logExecution("Generated greeting", { name: name });

        return textResult(greeting);
    }
}
