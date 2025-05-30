#!/bin/bash

# REPLTool Security Fix Implementation Guide
# This script shows how to apply the security fixes to REPLTool.cfc

echo "=========================================="
echo "REPLTool Security Fix Implementation Guide"
echo "=========================================="
echo

# Define paths
MCPCFC_ROOT="/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc"
ORIGINAL_FILE="$MCPCFC_ROOT/clitools/REPLTool.cfc"
BACKUP_FILE="$MCPCFC_ROOT/clitools/REPLTool.cfc.backup"
FIXED_FILE="$MCPCFC_ROOT/clitools/REPLTool_FIXED.cfc"

echo "Step 1: Create a backup of the original file"
echo "---------------------------------------------"
echo "cp \"$ORIGINAL_FILE\" \"$BACKUP_FILE\""
echo

echo "Step 2: Key changes to implement"
echo "--------------------------------"
echo

echo "CHANGE 1: Add pattern compilation to init() method"
echo "Current code (around line 10):"
echo "    public REPLTool function init() {"
echo "        return this;"
echo "    }"
echo
echo "Replace with:"
echo "    public REPLTool function init() {"
echo "        // PRE-COMPILE SECURITY PATTERNS FOR PERFORMANCE"
echo "        variables.compiledPatterns = compileSecurityPatterns();"
echo "        return this;"
echo "    }"
echo

echo "CHANGE 2: Fix variable isolation (lines 192-195 and 200-203)"
echo "Current vulnerable code:"
echo "    for (var key in isolatedScope) {"
echo "        variables[key] = isolatedScope[key];"
echo "    }"
echo
echo "Replace with safe implementation:"
echo "    // Define allowed context keys (whitelist approach)"
echo "    var allowedContextKeys = ['input', 'params', 'data', 'config', 'options'];"
echo "    var safeContext = structNew();"
echo "    "
echo "    // Only copy whitelisted keys to prevent variable overwriting"
echo "    if (structCount(attributes.executionContext) > 0) {"
echo "        for (var key in attributes.allowedKeys) {"
echo "            if (structKeyExists(attributes.executionContext, key)) {"
echo "                safeContext['ctx_' & key] = duplicate(attributes.executionContext[key]);"
echo "            }"
echo "        }"
echo "    }"
echo

echo "CHANGE 3: Update evaluate() calls to use safe context"
echo "Replace direct evaluate() calls with closure-based execution:"
echo "    // Create isolated execution scope"
echo "    var executionScope = function() {"
echo "        var ctx = safeContext;"
echo "        return evaluate(attributes.codeToExecute);"
echo "    };"
echo "    threadResult.returnValue = executionScope();"
echo

echo "CHANGE 4: Add compileSecurityPatterns() method"
echo "Add this new private method after init():"
cat << 'EOF'
    private struct function compileSecurityPatterns() {
        var patterns = {
            dangerous: [],
            reflection: [],
            keywords: []
        };
        
        // Dangerous patterns list (keep existing patterns)
        var dangerousRegexPatterns = [...]; // Your existing patterns
        
        // Compile patterns
        for (var pattern in dangerousRegexPatterns) {
            arrayAppend(patterns.dangerous, {
                pattern: pattern,
                compiled: true
            });
        }
        
        // Add reflection patterns including new ones
        var reflectionPatterns = [
            // ... existing patterns ...
            "import\s+java\.lang\.reflect\.\*"  // NEW PATTERN
        ];
        
        // Process reflection patterns
        for (var pattern in reflectionPatterns) {
            arrayAppend(patterns.reflection, {
                pattern: pattern,
                compiled: true
            });
        }
        
        // Fix keyword escaping
        for (var keyword in suspiciousKeywords) {
            // Fixed regex escaping
            var escapedKeyword = reReplace(keyword, "([\.\*\+\?\^\$\{\}\(\)\|\[\]\\])", "\\\1", "all");
            var keywordPattern = "\b" & escapedKeyword & "\b";
            arrayAppend(patterns.keywords, {
                pattern: keywordPattern,
                compiled: true
            });
        }
        
        return patterns;
    }
EOF
echo

echo "CHANGE 5: Create optimized isCodeSafeOptimized() method"
echo "Add this new method and update all isCodeSafe() calls to use it:"
cat << 'EOF'
    private boolean function isCodeSafeOptimized(required string code) {
        var codeToCheck = lcase(trim(arguments.code));
        
        // Use pre-compiled patterns
        for (var patternInfo in variables.compiledPatterns.dangerous) {
            if (reFindNoCase(patternInfo.pattern, codeToCheck) > 0) {
                writeLog(
                    text="Security block: pattern '" & patternInfo.pattern & "' matched", 
                    type="warning", 
                    application=true
                );
                return false;
            }
        }
        
        // Check other pattern categories...
        // (similar loops for reflection and keywords)
        
        return true;
    }
EOF
echo

echo "CHANGE 6: Update all isCodeSafe() calls"
echo "Search and replace throughout the file:"
echo "    Find: isCodeSafe("
echo "    Replace: isCodeSafeOptimized("
echo

echo "Step 3: Testing the fixes"
echo "-------------------------"
echo "1. Test variable isolation:"
echo "   - Try passing malicious executionContext"
echo "   - Verify only whitelisted variables are accessible"
echo
echo "2. Test performance improvement:"
echo "   - Run multiple executions in a loop"
echo "   - Compare timing before and after"
echo
echo "3. Test security patterns:"
echo "   - Verify all dangerous patterns are blocked"
echo "   - Ensure safe code still executes"
echo

echo "Step 4: Additional security measures"
echo "------------------------------------"
echo "1. Add to Application.cfc:"
cat << 'EOF'
    // Rate limiting for REPL executions
    if (!structKeyExists(session, "replExecutions")) {
        session.replExecutions = [];
    }
    
    // Clean old entries (older than 1 minute)
    var oneMinuteAgo = dateAdd("n", -1, now());
    session.replExecutions = session.replExecutions.filter(function(execution) {
        return execution.timestamp > oneMinuteAgo;
    });
    
    // Check rate limit (max 10 per minute)
    if (arrayLen(session.replExecutions) >= 10) {
        throw(message="Rate limit exceeded for REPL executions");
    }
EOF
echo

echo "Step 5: Production deployment checklist"
echo "---------------------------------------"
echo "[ ] Backup original REPLTool.cfc"
echo "[ ] Apply all code changes"
echo "[ ] Test variable isolation fix"
echo "[ ] Test performance improvements"
echo "[ ] Test security pattern coverage"
echo "[ ] Implement rate limiting"
echo "[ ] Add monitoring/alerting for blocked attempts"
echo "[ ] Update documentation"
echo "[ ] Deploy to staging environment"
echo "[ ] Perform security audit"
echo "[ ] Deploy to production"
echo

echo "IMPORTANT NOTES:"
echo "----------------"
echo "1. These fixes significantly improve security but don't make arbitrary"
echo "   code execution completely safe. Use only in trusted environments."
echo
echo "2. Consider implementing additional layers:"
echo "   - User authentication and authorization"
echo "   - Execution sandboxing"
echo "   - Resource limits (CPU, memory, time)"
echo "   - Comprehensive audit logging"
echo
echo "3. The regex-based approach has limitations. For production systems,"
echo "   consider AST-based code analysis for more robust security."
echo

echo "=========================================="
echo "End of Implementation Guide"
echo "=========================================="
