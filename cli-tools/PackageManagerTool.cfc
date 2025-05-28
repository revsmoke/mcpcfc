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
            // Build the box install command
            var cmd = "box install " & arguments.packageName;
            
            if (len(arguments.version)) {
                cmd &= "@" & arguments.version;
            }
            
            if (arguments.saveDev) {
                cmd &= " --saveDev";
            }
            
            if (arguments.force) {
                cmd &= " --force";
            }
            
            if (arguments.production) {
                cmd &= " --production";
            }
            
            // Execute the command
            var exec = executeCommand(cmd);
            
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
            // Use box search command
            var cmd = "box search " & arguments.query;
            
            if (arguments.type != "all") {
                cmd &= " --type=" & arguments.type;
            }
            
            var exec = executeCommand(cmd & " --json");
            
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
            var cmd = "box update";
            
            if (len(arguments.packageName)) {
                cmd &= " " & arguments.packageName;
            }
            
            if (arguments.force) {
                cmd &= " --force";
            }
            
            var exec = executeCommand(cmd);
            
            if (exec.success) {
                result.message = "Packages updated successfully";
                // Parse output to get list of updated packages
                result.updated = parseUpdateOutput(exec.output);
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
            var cmd = "box uninstall " & arguments.packageName;
            
            if (!arguments.removeDependencies) {
                cmd &= " --keep-dependencies";
            }
            
            var exec = executeCommand(cmd);
            
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
            // Execute command using cfexecute
            var executeResult = "";
            var executeError = "";
            
            cfexecute(
                name = arguments.command,
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

    private array function parseUpdateOutput(required string output) {
        var updated = [];
        // Parse CommandBox output to extract updated packages
        // This is simplified - actual implementation would parse the output format
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