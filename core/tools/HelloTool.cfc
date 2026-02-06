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

        var inputSchema = structNew("ordered");
        inputSchema["type"] = "object";
        inputSchema["properties"] = structNew("ordered");

        var nameSchema = structNew("ordered");
        nameSchema["type"] = "string";
        nameSchema["description"] = "The name to greet";
        inputSchema.properties["name"] = nameSchema;

        inputSchema["required"] = ["name"];
        setInputSchema(inputSchema);

        var outputSchema = structNew("ordered");
        outputSchema["type"] = "object";
        outputSchema["properties"] = structNew("ordered");

        var greetingSchema = structNew("ordered");
        greetingSchema["type"] = "string";
        greetingSchema["description"] = "The greeting message";
        outputSchema.properties["greeting"] = greetingSchema;

        setOutputSchema(outputSchema);

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
