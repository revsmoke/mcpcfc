component displayname="PackageManagerTool" hint="Package management tools for CF2023 MCP using CommandBox" {

    /**
     * Initialize the package manager tool
     */
    public PackageManagerTool function init() {
        return this;
    }

    /**
     * Get tool definitions for registration
     */
    public array function getToolDefinitions() {
        return [
            {
                name: "packageInstaller",
                description: "Install packages from ForgeBox or other sources using CommandBox",
                inputSchema: {
                    type: "object",
                    properties: {
                        packageName: {
                            type: "string",
                            description: "Package name or slug (e.g., 'coldbox', 'testbox@5.0.0')"
                        },
                        version: {
                            type: "string",
                            description: "Specific version to install (optional)"
                        },
                        saveDev: {
                            type: "boolean",
                            description: "Save as development dependency",
                            default: false
                        },
                        force: {
                            type: "boolean",
                            description: "Force reinstall even if already installed",
                            default: false
                        },
                        production: {
                            type: "boolean",
                            description: "Install production dependencies only",
                            default: false
                        }
                    },
                    required: ["packageName"]
                }
            },
            {
                name: "packageList",
                description: "List installed packages and their versions",
                inputSchema: {
                    type: "object",
                    properties: {
                        showDependencies: {
                            type: "boolean",
                            description: "Show package dependencies",
                            default: false
                        },
                        format: {
                            type: "string",
                            description: "Output format",
                            enum: ["json", "text", "tree"],
                            default: "json"
                        }
                    }
                }
            },
            {
                name: "packageSearch",
                description: "Search ForgeBox for packages",
                inputSchema: {
                    type: "object",
                    properties: {
                        query: {
                            type: "string",
                            description: "Search query"
                        },
                        type: {
                            type: "string",
                            description: "Package type filter",
                            enum: ["modules", "interceptors", "caching", "logging", "all"],
                            default: "all"
                        },
                        limit: {
                            type: "number",
                            description: "Maximum results to return",
                            default: 10
                        }
                    },
                    required: ["query"]
                }
            },
            {
                name: "packageUpdate",
                description: "Update installed packages to latest versions",
                inputSchema: {
                    type: "object",
                    properties: {
                        packageName: {
                            type: "string",
                            description: "Specific package to update (optional, updates all if not specified)"
                        },
                        force: {
                            type: "boolean",
                            description: "Force update even if up to date",
                            default: false
                        }
                    }
                }
            },
            {
                name: "packageRemove",
                description: "Remove installed packages",
                inputSchema: {
                    type: "object",
                    properties: {
                        packageName: {
                            type: "string",
                            description: "Package name to remove"
                        },
                        removeDependencies: {
                            type: "boolean",
                            description: "Also remove unused dependencies",
                            default: true
                        }
                    },
                    required: ["packageName"]
                }
            },
            {
                name: "moduleManager",
                description: "Load, unload, or reload ColdBox modules",
                inputSchema: {
                    type: "object",
                    properties: {
                        action: {
                            type: "string",
                            description: "Action to perform",
                            enum: ["load", "unload", "reload", "list"],
                            default: "list"
                        },
                        moduleName: {
                            type: "string",
                            description: "Module name (required for load/unload/reload)"
                        }
                    },
                    required: ["action"]
                }
            }
        ];
    }

    /**
     * Install a package using CommandBox
     */
    public struct function packageInstaller(
        required string packageName,
        string version = "",
        boolean saveDev = false,
        boolean force = false,
        boolean production = false
    ) {
        var result = {
            success: true,
            packageName: arguments.packageName,
            message: "",
            installedVersion: "",
            dependencies: [],
            error: ""
        };
        
        try {
            // Build the command arguments array
            var cmdArgs = ["install"];
            
            // Add package name with optional version
            if (len(arguments.version)) {
                arrayAppend(cmdArgs, arguments.packageName & "@" & arguments.version);
            } else {
                arrayAppend(cmdArgs, arguments.packageName);
            }
            
            if (arguments.saveDev) {
                arrayAppend(cmdArgs, "--saveDev");
            }
            
            if (arguments.force) {
                arrayAppend(cmdArgs, "--force");
            }
            
            if (arguments.production) {
                arrayAppend(cmdArgs, "--production");
            }
            
            // Execute the command with arguments array
            var exec = executeCommandWithArgs("box", cmdArgs);
            
            if (exec.success) {
                result.message = "Package installed successfully";
                result.installedVersion = getInstalledVersion(arguments.packageName);
                result.dependencies = getPackageDependencies(arguments.packageName);
            } else {
                result.success = false;
                result.error = exec.error;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * List installed packages
     */
    public struct function packageList(
        boolean showDependencies = false,
        string format = "json"
    ) {
        var result = {
            success: true,
            packages: [],
            error: ""
        };
        
        try {
            // Read box.json if it exists
            var boxJsonPath = expandPath("./box.json");
            
            if (fileExists(boxJsonPath)) {
                var boxJson = deserializeJSON(fileRead(boxJsonPath));
                
                // Get installed packages
                if (structKeyExists(boxJson, "installPaths")) {
                    for (var packageName in boxJson.installPaths) {
                        var packageInfo = {
                            name: packageName,
                            path: boxJson.installPaths[packageName],
                            version: getInstalledVersion(packageName)
                        };
                        
                        if (arguments.showDependencies && structKeyExists(boxJson, "dependencies")) {
                            packageInfo.dependencies = boxJson.dependencies[packageName] ?: [];
                        }
                        
                        arrayAppend(result.packages, packageInfo);
                    }
                }
            }
            
            // Format output based on requested format
            if (arguments.format == "text") {
                result.formatted = formatPackageListAsText(result.packages);
            } else if (arguments.format == "tree") {
                result.formatted = formatPackageListAsTree(result.packages);
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Search ForgeBox for packages
     */
    public struct function packageSearch(
        required string query,
        string type = "all",
        numeric limit = 10
    ) {
        var result = {
            success: true,
            query: arguments.query,
            results: [],
            totalFound: 0,
            error: ""
        };
        
        try {
            // Build command arguments array
            var cmdArgs = ["search", arguments.query];
            
            if (arguments.type != "all") {
                arrayAppend(cmdArgs, "--type=" & arguments.type);
            }
            
            arrayAppend(cmdArgs, "--json");
            
            var exec = executeCommandWithArgs("box", cmdArgs);
            
            if (exec.success) {
                var searchResults = deserializeJSON(exec.output);
                result.totalFound = arrayLen(searchResults);
                
                // Limit results
                var count = 0;
                for (var package in searchResults) {
                    if (++count > arguments.limit) break;
                    
                    arrayAppend(result.results, {
                        name: package.slug,
                        type: package.type,
                        version: package.version,
                        downloads: package.downloads,
                        description: package.summary
                    });
                }
            } else {
                result.success = false;
                result.error = exec.error;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Update packages
     */
    public struct function packageUpdate(
        string packageName = "",
        boolean force = false
    ) {
        var result = {
            success: true,
            updated: [],
            message: "",
            error: ""
        };
        
        try {
            // Build command arguments array
            var cmdArgs = ["update"];
            
            if (len(arguments.packageName)) {
                arrayAppend(cmdArgs, arguments.packageName);
            }
            
            if (arguments.force) {
                arrayAppend(cmdArgs, "--force");
            }
            
            // Add JSON flag for parseable output
            arrayAppend(cmdArgs, "--json");
            
            var exec = executeCommandWithArgs("box", cmdArgs);
            
            if (exec.success) {
                result.message = "Packages updated successfully";
                // Parse output to get list of updated packages
                result.updated = parseUpdateOutput(exec.output, arguments.packageName);
            } else {
                result.success = false;
                result.error = exec.error;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Remove a package
     */
    public struct function packageRemove(
        required string packageName,
        boolean removeDependencies = true
    ) {
        var result = {
            success: true,
            packageName: arguments.packageName,
            removed: [],
            message: "",
            error: ""
        };
        
        try {
            // Build command arguments array
            var cmdArgs = ["uninstall", arguments.packageName];
            
            if (!arguments.removeDependencies) {
                arrayAppend(cmdArgs, "--keep-dependencies");
            }
            
            var exec = executeCommandWithArgs("box", cmdArgs);
            
            if (exec.success) {
                result.message = "Package removed successfully";
                arrayAppend(result.removed, arguments.packageName);
            } else {
                result.success = false;
                result.error = exec.error;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Manage ColdBox modules
     */
    public struct function moduleManager(
        required string action,
        string moduleName = ""
    ) {
        var result = {
            success: true,
            action: arguments.action,
            modules: [],
            message: "",
            error: ""
        };
        
        try {
            switch(arguments.action) {
                case "list":
                    result.modules = listLoadedModules();
                    result.message = "Found " & arrayLen(result.modules) & " loaded modules";
                    break;
                    
                case "load":
                    if (!len(arguments.moduleName)) {
                        throw(message="Module name required for load action");
                    }
                    loadModule(arguments.moduleName);
                    result.message = "Module '" & arguments.moduleName & "' loaded successfully";
                    break;
                    
                case "unload":
                    if (!len(arguments.moduleName)) {
                        throw(message="Module name required for unload action");
                    }
                    unloadModule(arguments.moduleName);
                    result.message = "Module '" & arguments.moduleName & "' unloaded successfully";
                    break;
                    
                case "reload":
                    if (!len(arguments.moduleName)) {
                        throw(message="Module name required for reload action");
                    }
                    reloadModule(arguments.moduleName);
                    result.message = "Module '" & arguments.moduleName & "' reloaded successfully";
                    break;
                    
                default:
                    throw(message="Unsupported action: '" & arguments.action & "'. Valid actions are: list, load, unload, reload");
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    // Helper functions
    
    private struct function executeCommand(required string command) {
        var result = {
            success: true,
            output: "",
            error: ""
        };
        
        try {
            // Parse command string into executable and arguments
            var commandParts = listToArray(arguments.command, " ");
            
            if (arrayLen(commandParts) == 0) {
                throw(message="Empty command provided");
            }
            
            var executable = commandParts[1];
            var commandArgs = "";
            
            // Build arguments string from remaining parts
            if (arrayLen(commandParts) > 1) {
                commandArgs = arrayToList(arraySlice(commandParts, 2), " ");
            }
            
            // Execute command using cfexecute
            var executeResult = "";
            var executeError = "";
            
            cfexecute(
                name = executable,
                arguments = commandArgs,
                variable = "executeResult",
                errorVariable = "executeError",
                timeout = 60
            );
            
            result.output = executeResult;
            
            if (len(executeError)) {
                result.success = false;
                result.error = executeError;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
        }
        
        return result;
    }
    private struct function executeCommandWithArgs(required string executable, required array cmdArgs) {
        var result = {
            success: true,
            output: "",
            error: ""
        };
        
        try {
            // Execute command using cfexecute with arguments array
            var executeResult = "";
            var executeError = "";
            
            // Convert array of arguments to space-separated string
            // TODO: add proper shell escaping for security
 cfexecute( name        = arguments.executable,
            argumentsArray = arguments.cmdArgs,
             variable   = "executeResult",
             errorVariable = "executeError",
             timeout    = 60 );
                errorVariable = "executeError",
                timeout = 60
            );
            
            result.output = executeResult;
            
            if (len(executeError)) {
                result.success = false;
                result.error = executeError;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
        }
        
        return result;
    }

    private string function getInstalledVersion(required string packageName) {
        // Try to read version from package's box.json
        var possiblePaths = [
            expandPath("./modules/" & arguments.packageName & "/box.json"),
            expandPath("./modules_app/" & arguments.packageName & "/box.json"),
            expandPath("./" & arguments.packageName & "/box.json")
        ];
        
        for (var path in possiblePaths) {
            if (fileExists(path)) {
                try {
                    var packageBox = deserializeJSON(fileRead(path));
                    if (structKeyExists(packageBox, "version")) {
                        return packageBox.version;
                    }
                } catch (any e) {
                    // Continue to next path
                }
            }
        }
        
        return "Unknown";
    }

    private array function getPackageDependencies(required string packageName) {
        var dependencies = [];
        
        // Similar logic to getInstalledVersion but extract dependencies
        var possiblePaths = [
            expandPath("./modules/" & arguments.packageName & "/box.json"),
            expandPath("./modules_app/" & arguments.packageName & "/box.json"),
            expandPath("./" & arguments.packageName & "/box.json")
        ];
        
        for (var path in possiblePaths) {
            if (fileExists(path)) {
                try {
                    var packageBox = deserializeJSON(fileRead(path));
                    if (structKeyExists(packageBox, "dependencies")) {
                        for (var dep in packageBox.dependencies) {
                            arrayAppend(dependencies, {
                                name: dep,
                                version: packageBox.dependencies[dep]
                            });
                        }
                        break;
                    }
                } catch (any e) {
                    // Continue to next path
                }
            }
        }
        
        return dependencies;
    }

    private string function formatPackageListAsText(required array packages) {
        var output = "Installed Packages:" & chr(10) & chr(10);
        
        for (var package in arguments.packages) {
            output &= package.name & " (" & package.version & ")" & chr(10);
        }
        
        return output;
    }

    private string function formatPackageListAsTree(required array packages) {
        var output = "Package Tree:" & chr(10);
        
        for (var package in arguments.packages) {
            output &= "├── " & package.name & " @ " & package.version & chr(10);
            if (structKeyExists(package, "dependencies") && arrayLen(package.dependencies)) {
                for (var i = 1; i <= arrayLen(package.dependencies); i++) {
                    var dep = package.dependencies[i];
                    var prefix = (i == arrayLen(package.dependencies)) ? "    └── " : "    ├── ";
                    output &= prefix & dep.name & " @ " & dep.version & chr(10);
                }
            }
        }
        
        return output;
    }

    private array function parseUpdateOutput(required string output, string packageName = "") {
        var updated = [];
        
        try {
            // Try to parse JSON output first
            if (isJSON(trim(arguments.output))) {
                var jsonData = deserializeJSON(trim(arguments.output));
                
                // CommandBox update JSON structure varies, but typically includes package info
                if (isArray(jsonData)) {
                    for (var item in jsonData) {
                        if (structKeyExists(item, "name")) {
                            arrayAppend(updated, item.name);
                        }
                    }
                } else if (isStruct(jsonData)) {
                    // Sometimes returns a struct with package names as keys
                    for (var key in jsonData) {
                        arrayAppend(updated, key);
                    }
                }
            } else {
                // Fallback: Parse text output for common patterns
                var lines = listToArray(arguments.output, chr(10));
                for (var line in lines) {
                    // Look for lines that indicate package updates
                    // Common patterns: "✓ Updated packagename", "packagename updated to version X"
                    if (findNoCase("updated", line) > 0 || findNoCase("✓", line) > 0) {
                        // Extract package name from the line
                        var matches = reMatch("[\w\-\.]+@[\d\.]+", line);
                        if (arrayLen(matches) > 0) {
                            var pkgName = listFirst(matches[1], "@");
                            if (!arrayContains(updated, pkgName)) {
                                arrayAppend(updated, pkgName);
                            }
                        }
                    }
                }
            }
            
            // If no packages found in output but a specific package was requested
            // assume it was updated (CommandBox may not always list it explicitly)
            if (arrayLen(updated) == 0 && len(arguments.packageName)) {
                arrayAppend(updated, arguments.packageName);
            }
            
        } catch (any e) {
            // If parsing fails, return package name if specified
            if (len(arguments.packageName)) {
                arrayAppend(updated, arguments.packageName);
            }
        }
        
        return updated;
    }

    private array function listLoadedModules() {
        var modules = [];
        
        // Check if ColdBox is available
        if (structKeyExists(application, "cbController")) {
            var moduleService = application.cbController.getModuleService();
            var loadedModules = moduleService.getLoadedModules();
            
            for (var moduleName in loadedModules) {
                arrayAppend(modules, {
                    name: moduleName,
                    path: loadedModules[moduleName].path,
                    version: loadedModules[moduleName].version ?: "Unknown"
                });
            }
        }
        
        return modules;
    }

    private void function loadModule(required string moduleName) {
        if (structKeyExists(application, "cbController")) {
            var moduleService = application.cbController.getModuleService();
            moduleService.registerAndActivateModule(arguments.moduleName);
        } else {
            throw(message="ColdBox not available for module operations");
        }
    }

    private void function unloadModule(required string moduleName) {
        if (structKeyExists(application, "cbController")) {
            var moduleService = application.cbController.getModuleService();
            moduleService.unload(arguments.moduleName);
        } else {
            throw(message="ColdBox not available for module operations");
        }
    }

    private void function reloadModule(required string moduleName) {
        if (structKeyExists(application, "cbController")) {
            var moduleService = application.cbController.getModuleService();
            moduleService.reload(arguments.moduleName);
        } else {
            throw(message="ColdBox not available for module operations");
        }
    }

}