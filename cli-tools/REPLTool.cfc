component displayname="REPLTool" hint="REPL integration tools for CF2023 MCP" {

    /**
     * Initialize the REPL tool
     */
    public REPLTool function init() {
        return this;
    }

    /**
     * Get tool definitions for registration
     */
    public array function getToolDefinitions() {
        return [
            {
                name: "executeCode",
                description: "Execute CFML code in an isolated context and return the result",
                inputSchema: {
                    type: "object",
                    properties: {
                        code: {
                            type: "string",
                            description: "The CFML code to execute (CFScript syntax)"
                        },
                        returnOutput: {
                            type: "boolean",
                            description: "Whether to capture and return output (default: true)",
                            default: true
                        },
                        timeout: {
                            type: "number",
                            description: "Maximum execution time in seconds (default: 30)",
                            default: 30
                        }
                    },
                    required: ["code"]
                }
            },
            {
                name: "evaluateExpression",
                description: "Evaluate a CFML expression and return its value",
                inputSchema: {
                    type: "object",
                    properties: {
                        expression: {
                            type: "string",
                            description: "The CFML expression to evaluate"
                        },
                        format: {
                            type: "string",
                            description: "Output format: json, string, or dump",
                            enum: ["json", "string", "dump"],
                            default: "json"
                        }
                    },
                    required: ["expression"]
                }
            },
            {
                name: "testSnippet",
                description: "Execute code with test assertions and return results",
                inputSchema: {
                    type: "object",
                    properties: {
                        code: {
                            type: "string",
                            description: "The CFML code to test"
                        },
                        assertions: {
                            type: "array",
                            description: "Array of assertions to verify",
                            items: {
                                type: "object",
                                properties: {
                                    expression: {
                                        type: "string",
                                        description: "Expression that should evaluate to true"
                                    },
                                    message: {
                                        type: "string",
                                        description: "Error message if assertion fails"
                                    }
                                }
                            }
                        },
                        measurePerformance: {
                            type: "boolean",
                            description: "Whether to measure execution time and memory",
                            default: false
                        }
                    },
                    required: ["code"]
                }
            },
            {
                name: "inspectVariable",
                description: "Inspect a variable's type, structure, and contents",
                inputSchema: {
                    type: "object",
                    properties: {
                        setupCode: {
                            type: "string",
                            description: "Code to set up the variable"
                        },
                        variableName: {
                            type: "string",
                            description: "Name of the variable to inspect"
                        },
                        depth: {
                            type: "number",
                            description: "Maximum depth for nested structures (default: 3)",
                            default: 3
                        }
                    },
                    required: ["setupCode", "variableName"]
                }
            }
        ];
    }

    /**
     * Execute CFML code in isolated context
     */
    public struct function executeCode(required string code, boolean returnOutput = true, numeric timeout = 30) {
        var result = {
            success: true,
            output: "",
            error: "",
            executionTime: 0
        };
        
        var startTime = getTickCount();
        
        try {
            // Create isolated context
            var executionContext = structNew();
            
            // Capture output if requested
            if (arguments.returnOutput) {
                savecontent variable="result.output" {
                    // Execute the code
                    evaluate(arguments.code);
                }
            } else {
                evaluate(arguments.code);
            }
            
            result.executionTime = getTickCount() - startTime;
            
        } catch (any e) {
            result.success = false;
            result.error = e.message & " (Line: " & e.tagContext[1].line & ")";
            result.errorDetail = e.detail;
            result.stackTrace = e.tagContext;
        }
        
        return result;
    }

    /**
     * Evaluate a CFML expression
     */
    public struct function evaluateExpression(required string expression, string format = "json") {
        var result = {
            success: true,
            value: "",
            type: "",
            error: ""
        };
        
        try {
            // Evaluate the expression
            var value = evaluate(arguments.expression);
            result.type = getMetadata(value).name ?: "unknown";
            
            // Format the output based on requested format
            switch(arguments.format) {
                case "json":
                    if (isSimpleValue(value)) {
                        result.value = value;
                    } else {
                        result.value = serializeJSON(value);
                    }
                    break;
                    
                case "string":
                    result.value = toString(value);
                    break;
                    
                case "dump":
                    savecontent variable="result.value" {
                        writeDump(value);
                    }
                    break;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Test code snippet with assertions
     */
    public struct function testSnippet(
        required string code, 
        array assertions = [], 
        boolean measurePerformance = false
    ) {
        var result = {
            success: true,
            output: "",
            assertions: [],
            performance: {},
            error: ""
        };
        
        var startTime = getTickCount();
        var startMemory = 0;
        
        if (arguments.measurePerformance) {
            startMemory = getJVMMemoryUsage().used;
        }
        
        try {
            // Execute the code
            savecontent variable="result.output" {
                evaluate(arguments.code);
            }
            
            // Run assertions
            for (var assertion in arguments.assertions) {
                var assertResult = {
                    expression: assertion.expression,
                    passed: false,
                    message: assertion.message ?: "Assertion failed"
                };
                
                try {
                    assertResult.passed = evaluate(assertion.expression) ? true : false;
                } catch (any e) {
                    assertResult.passed = false;
                    assertResult.error = e.message;
                }
                
                arrayAppend(result.assertions, assertResult);
                if (!assertResult.passed) {
                    result.success = false;
                }
            }
            
            // Measure performance if requested
            if (arguments.measurePerformance) {
                result.performance = {
                    executionTime: getTickCount() - startTime,
                    memoryUsed: getJVMMemoryUsage().used - startMemory
                };
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Inspect variable structure and contents
     */
    public struct function inspectVariable(
        required string setupCode, 
        required string variableName,
        numeric depth = 3
    ) {
        var result = {
            success: true,
            variable: {},
            error: ""
        };
        
        try {
            // Execute setup code
            evaluate(arguments.setupCode);
            
            // Check if variable exists
            if (!isDefined(arguments.variableName)) {
                throw(message="Variable '#arguments.variableName#' is not defined");
            }
            
            // Get the variable
            var varToInspect = evaluate(arguments.variableName);
            
            // Build inspection result
            result.variable = {
                name: arguments.variableName,
                type: getMetadata(varToInspect).name ?: "unknown",
                value: inspectValue(varToInspect, arguments.depth),
                isSimple: isSimpleValue(varToInspect),
                isObject: isObject(varToInspect),
                isStruct: isStruct(varToInspect),
                isArray: isArray(varToInspect),
                isQuery: isQuery(varToInspect)
            };
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Helper function to inspect values recursively
     */
    private any function inspectValue(any value, numeric depth) {
        if (arguments.depth <= 0) {
            return "[Max depth reached]";
        }
        
        if (isSimpleValue(arguments.value)) {
            return arguments.value;
        } else if (isArray(arguments.value)) {
            var arr = [];
            for (var item in arguments.value) {
                arrayAppend(arr, inspectValue(item, arguments.depth - 1));
            }
            return arr;
        } else if (isStruct(arguments.value)) {
            var str = structNew("ordered");
            for (var key in arguments.value) {
                str[key] = inspectValue(arguments.value[key], arguments.depth - 1);
            }
            return str;
        } else if (isQuery(arguments.value)) {
            return {
                recordCount: arguments.value.recordCount,
                columnList: arguments.value.columnList,
                data: queryToArray(arguments.value)
            };
        } else {
            return toString(arguments.value);
        }
    }

    /**
     * Helper function to get JVM memory usage
     */
    private struct function getJVMMemoryUsage() {
        var runtime = createObject("java", "java.lang.Runtime").getRuntime();
        return {
            total: runtime.totalMemory(),
            free: runtime.freeMemory(),
            used: runtime.totalMemory() - runtime.freeMemory(),
            max: runtime.maxMemory()
        };
    }

    /**
     * Helper function to convert query to array
     */
    private array function queryToArray(required query q) {
        var arr = [];
        for (var row in arguments.q) {
            arrayAppend(arr, row);
        }
        return arr;
    }

}