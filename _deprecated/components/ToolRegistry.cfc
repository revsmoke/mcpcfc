component displayname="ToolRegistry" {
    
    variables.tools = {};
    
    public void function registerTool(required string name, required struct definition) {
        variables.tools[arguments.name] = arguments.definition;
    }
    
    public array function listTools() {
        var toolList = [];
        for (var toolName in variables.tools) {
            var tool = duplicate(variables.tools[toolName]);
            tool.name = toolName;
            arrayAppend(toolList, tool);
        }
        return toolList;
    }
    
    public struct function getTool(required string name) {
        if (structKeyExists(variables.tools, arguments.name)) {
            return duplicate(variables.tools[arguments.name]);
        }
        throw(type="ToolNotFound", message="Tool not found: #arguments.name#");
    }
}