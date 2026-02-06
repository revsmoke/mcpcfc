/**
 * FileTool.cfc
 * Sandboxed file operations for reading, writing, and listing files
 * All operations are restricted to the sandbox directory
 */
component extends="AbstractTool" output="false" {

    /**
     * Initialize the tool
     */
    public function init() {
        setName("fileOperations");
        setTitle("File Operations");
        setDescription("Read, write, list, and delete files within a sandboxed directory. Path traversal is prevented.");

        var inputSchema = structNew("ordered");
        inputSchema["type"] = "object";
        inputSchema["properties"] = structNew("ordered");

        var actionSchema = structNew("ordered");
        actionSchema["type"] = "string";
        actionSchema["enum"] = ["read", "write", "list", "delete", "exists", "info"];
        actionSchema["description"] = "The file operation to perform";
        inputSchema.properties["action"] = actionSchema;

        var pathSchema = structNew("ordered");
        pathSchema["type"] = "string";
        pathSchema["description"] = "Relative path within the sandbox directory";
        inputSchema.properties["path"] = pathSchema;

        var contentSchema = structNew("ordered");
        contentSchema["type"] = "string";
        contentSchema["description"] = "Content to write (required for 'write' action)";
        inputSchema.properties["content"] = contentSchema;

        var encodingSchema = structNew("ordered");
        encodingSchema["type"] = "string";
        encodingSchema["description"] = "File encoding for read/write (default: UTF-8)";
        inputSchema.properties["encoding"] = encodingSchema;

        inputSchema["required"] = ["action"];
        setInputSchema(inputSchema);

        return this;
    }

    /**
     * Execute the file operation
     * @toolArgs The tool arguments
     * @return The operation result
     */
    public struct function execute(required struct toolArgs) {
        validateRequired(arguments.toolArgs, ["action"]);

        var action = lCase(arguments.toolArgs.action);
        var sandboxDir = application.config.sandboxDirectory;
        logExecution("File operation requested", {
            action: action,
            path: arguments.toolArgs.path ?: ""
        });

        // Ensure sandbox directory exists
        if (!directoryExists(sandboxDir)) {
            directoryCreate(sandboxDir);
        }

        switch(action) {
            case "list":
                return listFiles(sandboxDir, getParam(arguments.toolArgs, "path", ""));

            case "read":
                validateRequired(arguments.toolArgs, ["path"]);
                return readFile(sandboxDir, arguments.toolArgs.path, getParam(arguments.toolArgs, "encoding", "UTF-8"));

            case "write":
                validateRequired(arguments.toolArgs, ["path", "content"]);
                return writeFile(sandboxDir, arguments.toolArgs.path, arguments.toolArgs.content, getParam(arguments.toolArgs, "encoding", "UTF-8"));

            case "delete":
                validateRequired(arguments.toolArgs, ["path"]);
                return deleteFile(sandboxDir, arguments.toolArgs.path);

            case "exists":
                validateRequired(arguments.toolArgs, ["path"]);
                return checkExists(sandboxDir, arguments.toolArgs.path);

            case "info":
                validateRequired(arguments.toolArgs, ["path"]);
                return getFileInfoResult(sandboxDir, arguments.toolArgs.path);

            default:
                return errorResult("Unknown action: #action#. Valid actions: read, write, list, delete, exists, info");
        }
    }

    /**
     * List files in a directory
     */
    private struct function listFiles(required string sandboxDir, string subPath = "") {
        var targetDir = arguments.sandboxDir;

        if (len(arguments.subPath)) {
            targetDir = resolveSafePath(arguments.sandboxDir, arguments.subPath);
        }

        if (!directoryExists(targetDir)) {
            logExecution("List directory failed", { path: arguments.subPath });
            return errorResult("Directory not found: #arguments.subPath#");
        }

        try {
            var files = directoryList(targetDir, false, "query");
            var result = [];

            for (var file in files) {
                arrayAppend(result, {
                    name: file.name,
                    type: file.type,
                    size: file.size,
                    modified: dateTimeFormat(file.dateLastModified, "yyyy-mm-dd HH:nn:ss")
                });
            }

            // Sort by name
            arraySort(result, function(a, b) {
                // Directories first, then by name
                if (a.type != b.type) {
                    return a.type == "Dir" ? -1 : 1;
                }
                return compareNoCase(a.name, b.name);
            });

            logExecution("Listed directory", { path: arguments.subPath, count: arrayLen(result) });

            return jsonResult({
                path: arguments.subPath ?: "/",
                count: arrayLen(result),
                files: result
            });

        } catch (any e) {
            logExecution("List directory failed", { error: e.message, path: arguments.subPath });
            return errorResult("Failed to list directory: #e.message#");
        }
    }

    /**
     * Read a file
     */
    private struct function readFile(required string sandboxDir, required string path, string encoding = "UTF-8") {
        var fullPath = resolveSafePath(arguments.sandboxDir, arguments.path);

        if (!fileExists(fullPath)) {
            logExecution("Read file failed", { path: arguments.path });
            return errorResult("File not found: #arguments.path#");
        }

        // Check file size
        var fileInfo = getFileInfo(fullPath);
        if (fileInfo.size > application.config.maxFileSize) {
            logExecution("Read file blocked (too large)", {
                path: arguments.path,
                size: fileInfo.size
            });
            return errorResult("File too large. Maximum size: #application.config.maxFileSize# bytes");
        }

        try {
            var content = fileRead(fullPath, arguments.encoding);

            logExecution("Read file", { path: arguments.path, size: fileInfo.size });

            return textResult(content);

        } catch (any e) {
            logExecution("Read file failed", { error: e.message, path: arguments.path });
            return errorResult("Failed to read file: #e.message#");
        }
    }

    /**
     * Write a file
     */
    private struct function writeFile(required string sandboxDir, required string path, required string content, string encoding = "UTF-8") {
        // Check content size
        if (len(arguments.content) > application.config.maxFileSize) {
            logExecution("Write blocked (content too large)", {
                path: arguments.path,
                size: len(arguments.content)
            });
            return errorResult("Content too large. Maximum size: #application.config.maxFileSize# bytes");
        }

        var fullPath = resolveSafePath(arguments.sandboxDir, arguments.path);

        try {
            // Ensure parent directory exists
            var parentDir = getDirectoryFromPath(fullPath);
            if (!directoryExists(parentDir)) {
                directoryCreate(parentDir);
            }

            fileWrite(fullPath, arguments.content, arguments.encoding);

            logExecution("Wrote file", { path: arguments.path, size: len(arguments.content) });

            return textResult("File written successfully: #arguments.path# (#len(arguments.content)# bytes)");

        } catch (any e) {
            logExecution("Write file failed", { error: e.message, path: arguments.path });
            return errorResult("Failed to write file: #e.message#");
        }
    }

    /**
     * Delete a file
     */
    private struct function deleteFile(required string sandboxDir, required string path) {
        var fullPath = resolveSafePath(arguments.sandboxDir, arguments.path);

        if (!fileExists(fullPath)) {
            logExecution("Delete file failed", { path: arguments.path });
            return errorResult("File not found: #arguments.path#");
        }

        try {
            fileDelete(fullPath);

            logExecution("Deleted file", { path: arguments.path });

            return textResult("File deleted successfully: #arguments.path#");

        } catch (any e) {
            logExecution("Delete file failed", { error: e.message, path: arguments.path });
            return errorResult("Failed to delete file: #e.message#");
        }
    }

    /**
     * Check if a file exists
     */
    private struct function checkExists(required string sandboxDir, required string path) {
        var fullPath = resolveSafePath(arguments.sandboxDir, arguments.path);

        return jsonResult({
            path: arguments.path,
            exists: fileExists(fullPath) || directoryExists(fullPath),
            isFile: fileExists(fullPath),
            isDirectory: directoryExists(fullPath)
        });
    }

    /**
     * Get file info
     */
    private struct function getFileInfoResult(required string sandboxDir, required string path) {
        var fullPath = resolveSafePath(arguments.sandboxDir, arguments.path);

        if (!fileExists(fullPath)) {
            logExecution("File info failed", { path: arguments.path });
            return errorResult("File not found: #arguments.path#");
        }

        try {
            var info = getFileInfo(fullPath);

            return jsonResult({
                path: arguments.path,
                name: listLast(arguments.path, "/\"),
                size: info.size,
                type: info.type,
                canRead: info.canRead,
                canWrite: info.canWrite,
                lastModified: dateTimeFormat(info.lastModified, "yyyy-mm-dd HH:nn:ss")
            });

        } catch (any e) {
            logExecution("File info failed", { error: e.message, path: arguments.path });
            return errorResult("Failed to get file info: #e.message#");
        }
    }

    /**
     * Resolve a path safely within the sandbox
     * Prevents path traversal attacks
     */
    private string function resolveSafePath(required string sandboxDir, required string relativePath) {
        // Normalize path separators
        var normalized = replace(arguments.relativePath, "\", "/", "all");

        // Remove dangerous patterns
        normalized = reReplace(normalized, "\.\./?", "", "all");  // Remove ../
        normalized = reReplace(normalized, "^/+", "");            // Remove leading slashes

        // Build full path
        var fullPath = arguments.sandboxDir & normalized;

        // Ensure the resolved path is within the sandbox
        var canonicalSandbox = canonicalizePath(arguments.sandboxDir);
        var canonicalPath = canonicalizePath(fullPath);

        if (findNoCase(canonicalSandbox, canonicalPath) != 1) {
            logExecution("Path traversal blocked", { path: arguments.relativePath });
            throw(type="SecurityError", message="Path traversal attempt blocked: #arguments.relativePath#");
        }

        return fullPath;
    }

    /**
     * Canonicalize a path for comparison
     */
    private string function canonicalizePath(required string path) {
        // Use Java to get canonical path
        var file = createObject("java", "java.io.File").init(arguments.path);
        return file.getCanonicalPath();
    }
}
