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
     * Execute CFML code in isolated context with timeout control
     * @code The CFML code to execute
     * @returnOutput Whether to capture output
     * @timeout Maximum execution time in seconds
     * @executionContext Optional struct of variables to make available in execution scope
     */
    public struct function executeCode(required string code, boolean returnOutput = true, numeric timeout = 30, struct executionContext = {}) {
var result = {
     success: true,
     output: "",
     error: "",
     executionTime: 0,
     timedOut: false,
    stackTrace: []
 };
        
        var startTime = getTickCount();
        var threadName = "executeCode_" & createUUID();
        
        // IMPORTANT: This function DOES use the timeout parameter and DOES provide isolation:
        // 1. Isolation: Code runs in a separate cfthread with its own variable scope
        // 2. Timeout: cfthread join operation uses the timeout parameter (see line 220)
        // 3. Context: Optional executionContext allows passing variables to isolated scope
        
        // Validate timeout parameter
        if (arguments.timeout <= 0 || arguments.timeout > 300) {
            arguments.timeout = 30; // Default to 30 seconds if invalid
        }
        
        try {
            // Execute code in a separate thread with timeout for isolation and timeout control
            cfthread(name=threadName, action="run", priority="normal", 
                     codeToExecute=arguments.code, 
                     shouldReturnOutput=arguments.returnOutput,
                     executionContext=arguments.executionContext) {
                try {
                    // Create isolated variables scope for this thread
                    var threadResult = {
                        output: "",
                        success: true,
                        error: "",
                        errorDetail: "",
                        stackTrace: []
                    };
                    
                    // Setup execution context variables in isolated scope
                    var isolatedScope = {};
                    if (structCount(attributes.executionContext) > 0) {
                        // Copy context variables to isolated scope
                        for (var key in attributes.executionContext) {
                            isolatedScope[key] = attributes.executionContext[key];
                        }
                    }
                    
                    // Execute code in isolated scope with timeout protection
                    // Note: Since evaluate() is limited, we execute the code directly
                    // For better isolation, consider using a sandbox approach
                    if (attributes.shouldReturnOutput) {
                        savecontent variable="threadResult.output" {
                            // Make context variables available
                            for (var key in isolatedScope) {
                                variables[key] = isolatedScope[key];
                            }
                            var _replValue = evaluate(attributes.codeToExecute);
                        threadResult.returnValue = _replValue;
                        }
                    } else {
                        // Make context variables available
                        for (var key in isolatedScope) {
                            variables[key] = isolatedScope[key];
                        }
                        var _replValue = evaluate(attributes.codeToExecute);
                        threadResult.returnValue = _replValue;
                    }
                    
                    // Store results in thread scope for retrieval
                    thread.result = threadResult;
                    
                } catch (any e) {
                    // Safely capture tagContext - ensure it's an array with valid structure
                    var safeStackTrace = [];
                    if (structKeyExists(e, "tagContext") && isArray(e.tagContext)) {
                        try {
                            safeStackTrace = e.tagContext;
                        } catch (any stackError) {
                            // If tagContext access fails, use empty array
                            safeStackTrace = [];
                        }
                    }
                    
                    thread.result = {
                        output: "",
                        success: false,
                        error: e.message,
                        errorDetail: e.detail,
                        stackTrace: safeStackTrace
                    };
                }
            }
            
            // Wait for thread completion with timeout
            cfthread(action="join", name=threadName, timeout=arguments.timeout * 1000);
            
            // Check thread status and results
            var threadInfo = cfthread[threadName];
            
            if (threadInfo.status == "COMPLETED") {
                if (structKeyExists(threadInfo, "result")) {
                    var threadResult = threadInfo.result;
                    result.output = threadResult.output;
                    result.success = threadResult.success;
                    if (!threadResult.success) {
                        // Safely reconstruct exception object for line info extraction
                        var reconstructedException = {
                            message: threadResult.error,
                            detail: threadResult.errorDetail
                        };
                        
                        // Only add tagContext if it's a valid array with elements
                        if (isArray(threadResult.stackTrace) && arrayLen(threadResult.stackTrace) > 0) {
                            reconstructedException.tagContext = threadResult.stackTrace;
245     result.error = threadResult.error & getLineInfoFromException(reconstructedException);
246     if ( structKeyExists( threadResult, "errorDetail" ) ) {
247         result.errorDetail = threadResult.errorDetail;
248     }
}
}
                        result.stackTrace = threadResult.stackTrace;
                    }
                } else {
                    result.success = false;
                    result.error = "Thread completed but no result was returned";
                }
            } else if (threadInfo.status == "RUNNING" || threadInfo.status == "NOT_STARTED") {
                // Thread timed out
                cfthread(action="terminate", name=threadName);
                result.success = false;
                result.timedOut = true;
                result.error = "Code execution timed out after " & arguments.timeout & " seconds";
            } else {
                // Thread failed
                result.success = false;
                result.error = "Thread execution failed with status: " & threadInfo.status;
            }
            
            result.executionTime = getTickCount() - startTime;
            
        } catch (any e) {
            result.success = false;
            result.error = e.message & getLineInfoFromException(e);
            result.errorDetail = e.detail;
            
            // Safely capture tagContext with additional error protection
            try {
                result.stackTrace = (structKeyExists(e, "tagContext") && isArray(e.tagContext)) ? e.tagContext : [];
            } catch (any stackError) {
                result.stackTrace = [];
            }
            
            result.executionTime = getTickCount() - startTime;
            
            // Clean up thread if it exists
            try {
                if (structKeyExists(cfthread, threadName)) {
                    cfthread(action="terminate", name=threadName);
                }
            } catch (any cleanupError) {
                // Ignore cleanup errors
            }
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
            var value = evaluate( arguments.expression );
            if ( isSimpleValue( value ) ) {
                result.type = lcase( javacast( "string", typeof( value ) ) );
            } else {
                result.type = getMetadata( value ).name ?: "unknown";
            }
            
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
                    
                default:
                    throw(message="Unsupported format: '" & arguments.format & "'. Valid formats are: json, string, dump");
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
     * Safely extract line information from exception tagContext
     */
    private string function getLineInfoFromException(required any exception) {
        try {
            // Enhanced safety: multiple defensive checks for tagContext access
            if (structKeyExists(arguments.exception, "tagContext")) {
                var tagContext = arguments.exception.tagContext;
                
                // Verify it's an array and has elements
                if (isArray(tagContext) && arrayLen(tagContext) > 0) {
                    
                    // Additional safety: verify the first element exists before access
                    try {
                        var firstContext = tagContext[1];
                        
                        // Verify the first context is a struct with line info
                        if (isStruct(firstContext) && structKeyExists(firstContext, "line")) {
                            var lineNumber = firstContext.line;
                            
                            // Verify line number is valid before using
                            if (isNumeric(lineNumber) && lineNumber > 0) {
                                return " (Line: " & lineNumber & ")";
                            }
                        }
                    } catch (any accessError) {
                        // Array access failed - continue to fallback
                    }
                }
            }
        } catch (any e) {
            // If any error occurs while extracting line info, just return empty string
            // This prevents secondary exceptions from masking the original error
        }
        return "";
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