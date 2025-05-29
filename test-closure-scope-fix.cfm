<!--- Test file to demonstrate closure scope fix in DevWorkflowTool --->
<!DOCTYPE html>
<html>
<head>
    <title>DevWorkflowTool Closure Scope Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .success { color: green; }
        .info { color: blue; }
        .error { color: red; }
        .warning { color: orange; }
        pre { background: #f5f5f5; padding: 10px; overflow-x: auto; }
        code { background: #f0f0f0; padding: 2px 4px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>DevWorkflowTool Closure Scope Fix Test</h1>
    
    <div class="section">
        <h2>Background: The Closure Scope Issue</h2>
        <p>The original code had a potential closure scope issue in the <code>getFileStates()</code> function:</p>
        <pre>
// BEFORE - Potential Issue:
function(filePath) {
    var ext = listLast(arguments.filePath, ".");
    return arrayFindNoCase(extensions, ext) > 0;  // 'extensions' from outer scope
}
        </pre>
        
        <p class="warning">⚠️ The anonymous function was accessing <code>extensions</code> from the outer function's scope, which could fail in certain contexts:</p>
        <ul>
            <li>When executed inside threads (file watchers run in threads)</li>
            <li>During high memory pressure or garbage collection</li>
            <li>In complex nested scope scenarios</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>The Fix: Explicit Local Copy</h2>
        <pre>
// AFTER - Fixed:
var extensionsToFilter = arguments.extensions;  // Create local copy

function(filePath) {
    var ext = listLast(arguments.filePath, ".");
    return arrayFindNoCase(extensionsToFilter, ext) > 0;  // Use local copy
}
        </pre>
        
        <p class="success">✓ The fix creates a local copy of the extensions array before the closure, ensuring reliable access</p>
    </div>
    
    <div class="section">
        <h2>Test: File Watcher with Multiple Extensions</h2>
        <cfscript>
        try {
            var devTool = new mcpcfc.clitools.DevWorkflowTool();
            
            // Test with multiple extensions to ensure the filter works correctly
            var result = devTool.watchFiles(
                paths = ["./tests"],
                extensions = ["cfc", "cfm", "test"],  // Multiple extensions
                action = "test",
                debounce = 1000
            );
            
            var content = deserializeJSON(result.content[1].text);
            
            writeOutput('<p class="info">Watcher started with ID: <strong>' & content.watcherId & '</strong></p>');
            writeOutput('<p>Watching for extensions: <strong>' & arrayToList(content.extensions) & '</strong></p>');
            
            // Get status to verify it's working
            var statusResult = devTool.getWatcherStatus();
            var status = deserializeJSON(statusResult.content[1].text);
            
            if (arrayLen(status.watchers) > 0) {
                writeOutput('<p class="success">✓ Watcher is active and monitoring files</p>');
                
                var watcher = status.watchers[1];
                writeOutput('<h3>Watcher Details:</h3>');
                writeOutput('<ul>');
                writeOutput('<li>Extensions monitored: ' & arrayToList(watcher.extensions) & '</li>');
                writeOutput('<li>Paths: ' & arrayToList(watcher.paths) & '</li>');
                writeOutput('<li>Action: ' & watcher.action & '</li>');
                writeOutput('<li>Active: ' & watcher.active & '</li>');
                writeOutput('</ul>');
            }
            
            // Clean up
            devTool.stopWatcher(content.watcherId);
            writeOutput('<p class="info">Watcher stopped and cleaned up</p>');
            
        } catch (any e) {
            writeOutput('<p class="error">Error: ' & e.message & '</p>');
            if (structKeyExists(e, "detail")) {
                writeOutput('<p class="error">Details: ' & e.detail & '</p>');
            }
        }
        </cfscript>
    </div>
    
    <div class="section">
        <h2>Stress Test: Multiple Watchers with Different Extensions</h2>
        <cfscript>
        try {
            var devTool = new mcpcfc.clitools.DevWorkflowTool();
            var watcherIds = [];
            
            // Create multiple watchers with different extension sets
            var configs = [
                {paths: ["./"], extensions: ["cfc"], action: "test"},
                {paths: ["./tools"], extensions: ["cfc", "cfm"], action: "lint"},
                {paths: ["./tests"], extensions: ["test", "spec", "cfc"], action: "test"}
            ];
            
            writeOutput('<p>Creating multiple watchers to test closure scope...</p>');
            
            for (var config in configs) {
                var result = devTool.watchFiles(
                    paths = config.paths,
                    extensions = config.extensions,
                    action = config.action
                );
                
                var content = deserializeJSON(result.content[1].text);
                arrayAppend(watcherIds, content.watcherId);
                
                writeOutput('<p class="success">✓ Created watcher for ' & arrayToList(config.paths) & 
                           ' monitoring [' & arrayToList(config.extensions) & '] files</p>');
            }
            
            // Brief pause to let threads initialize
            sleep(100);
            
            // Verify all watchers are working
            var statusResult = devTool.getWatcherStatus();
            var status = deserializeJSON(statusResult.content[1].text);
            
            writeOutput('<h3>Active Watchers: ' & arrayLen(status.watchers) & '</h3>');
            
            // Clean up all watchers
            for (var watcherId in watcherIds) {
                devTool.stopWatcher(watcherId);
            }
            
            writeOutput('<p class="success">✓ All watchers cleaned up successfully</p>');
            
        } catch (any e) {
            writeOutput('<p class="error">Error in stress test: ' & e.message & '</p>');
            
            // Clean up any remaining watchers
            if (isDefined("watcherIds") && isArray(watcherIds)) {
                for (var id in watcherIds) {
                    try {
                        devTool.stopWatcher(id);
                    } catch (any cleanupError) {
                        // Ignore cleanup errors
                    }
                }
            }
        }
        </cfscript>
    </div>
    
    <div class="section">
        <h2>Why This Fix Matters</h2>
        <ul>
            <li><strong>Thread Safety:</strong> File watchers run in separate threads where scope capture can be unreliable</li>
            <li><strong>Memory Management:</strong> Explicit local copies prevent garbage collection issues</li>
            <li><strong>Predictability:</strong> Removes a potential source of "works sometimes" bugs</li>
            <li><strong>CF Version Compatibility:</strong> Works reliably across different ColdFusion versions</li>
        </ul>
        
        <div style="background: #f0f8ff; padding: 10px; border-radius: 5px; margin-top: 10px;">
            <p><strong>Best Practice:</strong> When using closures in ColdFusion, especially in threaded contexts:</p>
            <ol>
                <li>Create local copies of outer scope variables before the closure</li>
                <li>Use explicit scope prefixes (arguments., variables., etc.)</li>
                <li>Test in multi-threaded scenarios</li>
            </ol>
        </div>
    </div>
    
</body>
</html>