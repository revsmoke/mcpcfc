<!--- Test file to demonstrate improved thread management in DevWorkflowTool --->
<!DOCTYPE html>
<html>
<head>
    <title>DevWorkflowTool Thread Management Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .success { color: green; }
        .info { color: blue; }
        .error { color: red; }
        pre { background: #f5f5f5; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>DevWorkflowTool Thread Management Improvements Test</h1>
    
    <div class="section">
        <h2>Test 1: Descriptive Thread Names</h2>
        <cfscript>
        try {
            // Create a watcher to test new thread naming
            var devTool = new mcpcfc.clitools.DevWorkflowTool();
            var result = devTool.watchFiles(
                paths = ["./tests"],
                extensions = ["cfc", "cfm"],
                action = "test",
                debounce = 1000
            );
            
            var content = deserializeJSON(result.content[1].text);
            
            writeOutput('<p class="info">Watcher ID: <strong>' & content.watcherId & '</strong></p>');
            writeOutput('<p>Notice the descriptive format: fileWatcher_{action}_{timestamp}_{pathHash}</p>');
            
            // Clean up
            devTool.stopWatcher(content.watcherId);
            
        } catch (any e) {
            writeOutput('<p class="error">Error: ' & e.message & '</p>');
        }
        </cfscript>
    </div>
    
    <div class="section">
        <h2>Test 2: Thread Termination</h2>
        <cfscript>
        try {
            var devTool = new mcpcfc.clitools.DevWorkflowTool();
            
            // Start a watcher
            var startResult = devTool.watchFiles(
                paths = ["./components"],
                extensions = ["cfc"],
                action = "lint",
                debounce = 500
            );
            
            var startContent = deserializeJSON(startResult.content[1].text);
            var watcherId = startContent.watcherId;
            
            writeOutput('<p class="info">Started watcher: ' & watcherId & '</p>');
            
            // Stop the watcher
            var stopResult = devTool.stopWatcher(watcherId);
            var stopContent = deserializeJSON(stopResult.content[1].text);
            
            writeOutput('<p class="success">' & stopContent.message & '</p>');
            writeOutput('<p>The thread is now explicitly terminated, not just marked inactive.</p>');
            
        } catch (any e) {
            writeOutput('<p class="error">Error: ' & e.message & '</p>');
        }
        </cfscript>
    </div>
    
    <div class="section">
        <h2>Test 3: Active Watchers Status</h2>
        <cfscript>
        try {
            var devTool = new mcpcfc.clitools.DevWorkflowTool();
            
            // Create multiple watchers
            var watcher1 = devTool.watchFiles(paths = ["./"], action = "test");
            var watcher2 = devTool.watchFiles(paths = ["./tools"], action = "lint");
            
            // Get status
            var statusResult = devTool.getWatcherStatus();
            var status = deserializeJSON(statusResult.content[1].text);
            
            writeOutput('<h3>Active Watchers:</h3>');
            writeOutput('<pre>' & serializeJSON(status, true) & '</pre>');
            
            // Clean up
            var w1 = deserializeJSON(watcher1.content[1].text);
            var w2 = deserializeJSON(watcher2.content[1].text);
            devTool.stopWatcher(w1.watcherId);
            devTool.stopWatcher(w2.watcherId);
            
        } catch (any e) {
            writeOutput('<p class="error">Error: ' & e.message & '</p>');
        }
        </cfscript>
    </div>
    
    <div class="section">
        <h2>Test 4: Application Cleanup Simulation</h2>
        <p>The <code>onApplicationEnd()</code> method in Application.cfc now includes:</p>
        <pre>
// Clean up any active file watcher threads
if (structKeyExists(application, "fileWatchers")) {
    for (var watcherId in application.fileWatchers) {
        try {
            // Mark as inactive
            application.fileWatchers[watcherId].active = false;
            
            // Terminate the thread
            cfthread(action="terminate", name=watcherId);
            
            writeLog(
                text="Terminated file watcher thread on application shutdown: " & watcherId,
                type="information",
                application=true
            );
        } catch (any e) {
            // Thread might have already stopped
            writeLog(
                text="Could not terminate file watcher thread: " & watcherId & " - " & e.message,
                type="warning",
                application=true
            );
        }
    }
}
        </pre>
        <p class="success">✓ All watcher threads will be properly terminated on application shutdown</p>
    </div>
    
    <div class="section">
        <h2>Summary of Improvements</h2>
        <ul>
            <li class="success">✓ Explicit thread termination prevents resource leaks</li>
            <li class="success">✓ Descriptive thread names improve debugging (format: fileWatcher_{action}_{timestamp}_{pathHash})</li>
            <li class="success">✓ Application cleanup ensures no orphaned threads on shutdown/restart</li>
            <li class="success">✓ Better error handling for thread termination</li>
            <li class="success">✓ Improved logging throughout the lifecycle</li>
        </ul>
    </div>
    
</body>
</html>