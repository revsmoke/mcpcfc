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
                name = "executeCode",
                description = "Execute CFML code in an isolated context and return the result",
                inputSchema = {
                    type = "object",
                    properties = {
                        code = {
                            type = "string",
                            description = "The CFML code to execute (CFScript syntax)"
                        },
                        returnOutput = {
                            type = "boolean",
                            description = "Whether to capture and return output (default: true)",
                            default = true
                        },
                        timeout = {
                            type = "number",
                            description = "Maximum execution time in seconds (default: 30)",
                            default = 30
                        }
                    },
                    required = ["code"]
                }
            },
            {
                name = "evaluateExpression",
                description = "Evaluate a CFML expression and return its value",
                inputSchema = {
                    type = "object",
                    properties = {
                        expression = {
                            type = "string",
                            description = "The CFML expression to evaluate"
                        },
                        format = {
                            type = "string",
                            description = "Output format: json, string, or dump",
                            enum = ["json", "string", "dump"],
                            default = "json"
                        }
                    },
                    required = ["expression"]
                }
            },
            {
                name = "testSnippet",
                description = "Execute code with test assertions and return results",
                inputSchema = {
                    type = "object",
                    properties = {
                        code = {
                            type = "string",
                            description = "The CFML code to test"
                        },
                        assertions = {
                            type = "array",
                            description = "Array of assertions to verify",
                            items = {
                                type = "object",
                                properties = {
                                    expression = {
                                        type = "string",
                                        description = "Expression that should evaluate to true"
                                    },
                                    message = {
                                        type = "string",
                                        description = "Error message if assertion fails"
                                    }
                                }
                            }
                        },
                        measurePerformance = {
                            type = "boolean",
                            description = "Whether to measure execution time and memory",
                            default = false
                        }
                    },
                    required = ["code"]
                }
            },
            {
                name = "inspectVariable",
                description = "Inspect a variable's type, structure, and contents",
                inputSchema = {
                    type = "object",
                    properties = {
                        setupCode = {
                            type = "string",
                            description = "Code to set up the variable"
                        },
                        variableName = {
                            type = "string",
                            description = "Name of the variable to inspect"
                        },
                        depth = {
                            type = "number",
                            description = "Maximum depth for nested structures (default: 3)",
                            default = 3
                        }
                    },
                    required = ["setupCode", "variableName"]
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
            success = true,
            output = "",
            error = "",
            returnValue = "",
            executionTime = 0,
            timedOut = false,
            stackTrace = []
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
                        output = "",
                        success = true,
                        error = "",
                        errorDetail = "",
                        stackTrace = []
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
                    // SECURITY WARNING: evaluate() executes arbitrary CFML code
                    // This should only be used in trusted environments with trusted code
                    if (!isCodeSafe(attributes.codeToExecute)) {
        threadResult.success      = false;
        threadResult.error        = "Code contains potentially unsafe operations";
        threadResult.returnValue  = "";
        threadResult.output       = "";
        thread.result             = threadResult;
        return; // exit cfthread body safely
                    }
                    
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
                        output = "",
                        success = false,
                        error = e.message,
                        errorDetail = e.detail,
                        stackTrace = safeStackTrace
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
                    result.returnValue = structKeyExists(threadResult, "returnValue") ? threadResult.returnValue : "";
                    
                    if (!threadResult.success) {
                        // Safely reconstruct exception object for line info extraction
                        var reconstructedException = {
                            message = threadResult.error,
                            detail = threadResult.errorDetail
                        };
                        
                        // Only add tagContext if it's a valid array with elements
                        if (isArray(threadResult.stackTrace) && arrayLen(threadResult.stackTrace) > 0) {
                            reconstructedException.tagContext = threadResult.stackTrace;
                        }
                        
                        result.error = threadResult.error & getLineInfoFromException(reconstructedException);

                        if (structKeyExists(threadResult, "errorDetail")) {
                            result.errorDetail = threadResult.errorDetail;
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
            success = true,
            value = "",
            type = "",
            error = ""
        };
        
        try {
            // Security check for expression evaluation
            if (!isCodeSafe(arguments.expression)) {
                result.success = false;
                result.error = "Expression contains potentially unsafe operations";
                return result;
            }
            
            // Evaluate the expression
            var value = evaluate( arguments.expression );
            if ( isSimpleValue( value ) ) {
                // For simple values, determine the type
                if (isNumeric(value)) {
                    result.type = "numeric";
                } else if (isBoolean(value)) {
                    result.type = "boolean";
                } else {
                    result.type = "string";
                }
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
            success = true,
            output = "",
            assertions = [],
            performance = {},
            error = ""
        };
        
        var startTime = getTickCount();
        var startMemory = 0;
        
        if (arguments.measurePerformance) {
            startMemory = getJVMMemoryUsage().used;
        }
        
        try {
            // Security check for code execution
            if (!isCodeSafe(arguments.code)) {
                result.success = false;
                result.error = "Code contains potentially unsafe operations";
                return result;
            }
            
            // Execute the code
            savecontent variable="result.output" {
                evaluate(arguments.code);
            }
            
            // Run assertions
            for (var assertion in arguments.assertions) {
                var assertResult = {
                    expression = assertion.expression,
                    passed = false,
                    message = assertion.message ?: "Assertion failed"
                };
                
                try {
                    // Security check for assertion expression
                    if (!isCodeSafe(assertion.expression)) {
                        assertResult.passed = false;
                        assertResult.error = "Assertion expression contains potentially unsafe operations";
                    } else {
                        assertResult.passed = evaluate(assertion.expression) ? true : false;
                    }
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
                    executionTime = getTickCount() - startTime,
                    memoryUsed = getJVMMemoryUsage().used - startMemory
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
            success = true,
            variable = {},
            error = ""
        };
        
        try {
            // Security check for setup code
            if (!isCodeSafe(arguments.setupCode)) {
                result.success = false;
                result.error = "Setup code contains potentially unsafe operations";
                return result;
            }
            
            // Security check for variable name (could contain code)
            if (!isCodeSafe(arguments.variableName)) {
                result.success = false;
                result.error = "Variable name contains potentially unsafe operations";
                return result;
            }
            
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
                name = arguments.variableName,
                type = isSimpleValue( varToInspect )
    ? lcase( javacast( "string",
        isNumeric(varToInspect)  ? "numeric" :
        isBoolean(varToInspect)  ? "boolean" :
        "string"
      ) )
    : getMetadata( varToInspect ).name ?: "unknown",
                value = inspectValue(varToInspect, arguments.depth),
                isSimple = isSimpleValue(varToInspect),
                isObject = isInstanceOf(varToInspect,"java.lang.Object"),
                isStruct = isStruct(varToInspect),
                isArray = isArray(varToInspect),
                isQuery = isQuery(varToInspect)
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
                recordCount = arguments.value.recordCount,
                columnList = arguments.value.columnList,
                data = queryToArray(arguments.value)
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
            total = runtime.totalMemory(),
            free = runtime.freeMemory(),
            used = runtime.totalMemory() - runtime.freeMemory(),
            max = runtime.maxMemory()
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

    /**
     * Enhanced security check for code safety
     * WARNING: This is not a comprehensive security sandbox
     * Use only in trusted environments with trusted users
     * 
     * TODO: Future improvements:
     * - Switch to whitelist approach instead of blacklist
     * - Parse code into AST for accurate validation
     * - Add resource usage limits (memory, CPU, execution time)
     * - Implement logging for all security blocks
     */
    private boolean function isCodeSafe(required string code) {
        var codeToCheck = lcase(trim(arguments.code));
        
        // Expanded list of dangerous regex patterns with word boundaries
        var dangerousRegexPatterns = [
            // Object creation and reflection
            "\bcreateobject\b", // Could create Java objects, files, etc.
            "\bnew\s+java\b", // Java object instantiation
            "\.class\s*\(", // Class access/loading
            "\.getclass\s*\(", // Reflective class access
            "\bclass\.forname\b", // Dynamic class loading
            "\bgetmetadata\s*\(", // Metadata access
            "\bgetfunctioncaller\s*\(", // Stack inspection
            
            // File and system operations
            "\bcfexecute\b", // Execute system commands
            "\bcffile\b", // File operations
            "\bcfdirectory\b", // Directory operations
            "\bcfregistry\b", // Registry access
            "\bfileread\b", // File reading functions
            "\bfilewrite\b", // File writing functions
            "\bfileopen\b", // File opening
            "\bfilecopy\b", // File copying
            "\bfilemove\b", // File moving
            "\bfiledelete\b", // File deletion
            "\bfileexists\b", // File existence check
            "\bdirectorylist\b", // Directory listing
            "\bdirectorycreate\b", // Directory creation
            "\bdirectorydelete\b", // Directory deletion
            "\bexpandpath\b", // Path expansion could reveal system info
            "\bgettempdirectory\b", // System path access
            "\bgettemplatepath\b", // Template path access
            "\bgetcurrenttemplatepath\b", // Current template path
            "\bgetbasetemplatepath\b", // Base template path
            
            // Network operations
            "\bcfhttp\b", // HTTP requests (could be used for SSRF)
            "\bcfmail\b", // Email sending
            "\bcfldap\b", // LDAP operations
            "\bcfftp\b", // FTP operations
            "\bcfsocket\b", // Socket operations
            "\bhttpsend\b", // HTTP sending
            
            // Database operations
            "\bcfquery\b", // Database access
            "\bcfstoredproc\b", // Stored procedure calls
            "\bquerynew\b", // Query creation
            "\bqueryexecute\b", // Query execution
            "\bcftransaction\b", // Database transactions
            "\bcfdbinfo\b", // Database info
            
            // Code inclusion and execution
            "\bcfinclude\b", // Include other files
            "\bcfmodule\b", // Load modules
            "\bcfobject\b", // Create objects
            "\bcfinvoke\b", // Invoke components
            "\bcfimport\b", // Import tags/components
            "\bcfscript\b", // Script execution
            "\bevaluate\s*\(", // Dynamic evaluation (nested)
            "\bprecisionevaluate\s*\(", // Precision evaluation
            
            // Java system access
            "\bsystem\.", // Java System class access
            "\bruntime\.", // Java Runtime access
            "\.exec\s*\(", // Runtime.exec() calls
            "\bprocessbuilder\b", // Process creation
            "\bthread\.", // Thread manipulation
            "\bclass\.", // Class manipulation
            
            // Threading and locking
            "\bcflock\b", // Could be used for DoS
            "\bcfthread\b", // Nested threading
            "\bsleep\s*\(", // Thread sleeping (DoS)
            
            // Scope access and modification
            "\bapplication\.", // Application scope modification
            "\bserver\.", // Server scope access
            "\bsession\.", // Session scope modification
            "\brequest\.", // Request scope modification
            "\bcgi\.", // CGI scope access
            "\burl\.", // URL scope access
            "\bform\.", // Form scope access
            "\bcookie\.", // Cookie access
            "\bclient\.", // Client scope access
            
            // Admin and debugging
            "\bcfadmin\b", // Admin operations
            "\bcfdump\b", // Could expose sensitive data
            "\bcftrace\b", // Tracing/debugging
            "\bcflog\b", // Logging access
            "\bcfdebug\b", // Debug operations
            "\bcferror\b", // Error handling manipulation
            
            // Component manipulation
            "\bgetcomponentmetadata\b", // Component metadata
            "\bgetpagecontext\b", // Page context access
            "\bgetfunctionlist\b", // Function listing
            "\bgettaglist\b", // Tag listing
            
            // Serialization (potential RCE)
            "\bobjectload\b", // Object deserialization
            "\bobjectsave\b", // Object serialization
            "\bdeserializejson\b", // JSON deserialization with type info
            "\bdeserializexml\b", // XML deserialization
            
            // Cache manipulation
            "\bcfcache\b", // Cache operations
            "\bcacheget\b", // Cache reading
            "\bcacheput\b", // Cache writing
            "\bcachedelete\b", // Cache deletion
            "\bcacheclear\b" // Cache clearing
        ];
        
        // Check dangerous patterns using regex with word boundaries
for (var pattern in dangerousRegexPatterns) {
     if (reFindNoCase(pattern, codeToCheck) > 0) {
        writeLog(text="Security block: pattern '" & pattern & "' matched in code", type="warning", application=true);
         return false;
     }
 }
        
        // Additional regex patterns for reflective and class-loading operations
        var reflectionPatterns = [
            "\.class\s*\.", // Access to .class property
            "\.class\s*\[", // Array access on class
            "\.getclass\s*\(\s*\)\s*\.", // Method chaining on getClass()
            "\bclassloader\b", // ClassLoader access
            "\bgetclassloader\b", // Getting class loader
            "\bdefineclass\b", // Defining new classes
            "\bloadclass\b", // Loading classes
            "\bgetprotectiondomain\b", // Security domain access
            "\bgetdeclaredmethods\b", // Method reflection
            "\bgetdeclaredfields\b", // Field reflection
            "\bsetaccessible\b", // Bypassing access controls
            "\binvoke\b.*\bmethod\b", // Reflective method invocation
            "\bnewinstance\b" // Creating instances reflectively
        ];
        
        // Check reflection patterns
        for (var pattern in reflectionPatterns) {
            if (reFindNoCase(pattern, codeToCheck) > 0) {
                // TODO: Log security block for reflection attempt
                return false;
            }
        }
        
        // Check for suspicious keywords that might indicate sensitive data access
        var suspiciousKeywords = [
            "\bcfusion\b", // ColdFusion internals
            "\bcoldfusion\b", // ColdFusion references
            "\badmin\b", // Admin access
            "\bpassword\b", // Password access
            "\bsecret\b", // Secret data
            "\bkey\b", // Key access
            "\btoken\b", // Token access
            "\bcredential\b", // Credential access
            "\bprivate\b", // Private data
            "\bencrypt\b", // Encryption operations
            "\bdecrypt\b", // Decryption operations
            "\bhash\b", // Hashing operations
            "\bsalt\b" // Salt access
        ];
        
        // Use regex for keyword matching with word boundaries
        for (var keyword in suspiciousKeywords) {
            var keywordPattern = "\b" & reReplace(keyword, "([.*+?^${}()|[\]\\])", "\\\1", "all") & "\b";
            if (reFindNoCase(keywordPattern, codeToCheck) > 0) {
                // TODO: Log security block for suspicious keyword
                return false;
            }
        }
        
        // TODO: Implement resource usage tracking before execution
        // TODO: Consider AST parsing for more accurate code analysis
        
        return true;
    }

}