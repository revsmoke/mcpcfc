/**
 * DatabaseTool.cfc
 * Execute safe SELECT queries against the database
 * Implements SQL injection prevention
 */
component extends="AbstractTool" output="false" {

    /**
     * Initialize the tool
     */
    public function init() {
        setName("queryDatabase");
        setTitle("Query Database");
        setDescription("Execute SELECT queries against the database. Only read operations are allowed for safety.");

        var inputSchema = structNew("ordered");
        inputSchema["type"] = "object";
        inputSchema["properties"] = structNew("ordered");

        var querySchema = structNew("ordered");
        querySchema["type"] = "string";
        querySchema["description"] = "SQL SELECT query to execute. Only SELECT statements are allowed.";
        inputSchema.properties["query"] = querySchema;

        var datasourceSchema = structNew("ordered");
        datasourceSchema["type"] = "string";
        datasourceSchema["description"] = "Database datasource name (optional, uses default if not provided)";
        inputSchema.properties["datasource"] = datasourceSchema;

        inputSchema["required"] = ["query"];
        setInputSchema(inputSchema);

        var outputSchema = structNew("ordered");
        outputSchema["type"] = "object";
        outputSchema["properties"] = structNew("ordered");

        var recordCountSchema = structNew("ordered");
        recordCountSchema["type"] = "number";
        recordCountSchema["description"] = "Number of records returned";
        outputSchema.properties["recordCount"] = recordCountSchema;

        var columnsSchema = structNew("ordered");
        columnsSchema["type"] = "string";
        columnsSchema["description"] = "Comma-separated list of column names";
        outputSchema.properties["columns"] = columnsSchema;

        var dataSchema = structNew("ordered");
        dataSchema["type"] = "array";
        dataSchema["description"] = "Array of row objects";
        outputSchema.properties["data"] = dataSchema;

        setOutputSchema(outputSchema);

        return this;
    }

    /**
     * Execute the query
     * @toolArgs The tool arguments
     * @return The query result
     */
    public struct function execute(required struct toolArgs) {
        validateRequired(arguments.toolArgs, ["query"]);

        var sqlQuery = trim(arguments.toolArgs.query);
        logExecution("Database query received", { queryPreview: left(sqlQuery, 100) });

        // Validate the query is safe
        var sqlValidator = new validators.SQLValidator();
        var validation = sqlValidator.validateSelectQuery(sqlQuery);

        if (!validation.valid) {
            logExecution("Database query rejected", { reason: validation.message });
            return errorResult(validation.message);
        }

        // Get datasource
        var ds = getParam(arguments.toolArgs, "datasource", application.config.defaultDatasource);
        logExecution("Executing database query", { datasource: ds });

        try {
            // Execute the query with max rows limit
            var queryResult = queryExecute(
                sqlQuery,
                {},
                {
                    datasource: ds,
                    maxrows: application.config.maxQueryResults
                }
            );

            // Convert query to array of structs
            var results = [];
            for (var row in queryResult) {
                arrayAppend(results, row);
            }

            // Check if results were truncated
            var truncated = queryResult.recordCount >= application.config.maxQueryResults;

            var resultData = {
                recordCount: queryResult.recordCount,
                columns: queryResult.columnList,
                data: results
            };

            if (truncated) {
                resultData.warning = "Results truncated to #application.config.maxQueryResults# rows";
            }

            logExecution("Query executed", {
                recordCount: queryResult.recordCount,
                truncated: truncated,
                queryPreview: left(sqlQuery, 100)
            });

            return jsonResult(resultData);

        } catch (database e) {
            logExecution("Query failed", {
                error: e.message,
                queryPreview: left(sqlQuery, 100)
            });
            return errorResult("Database error: #e.message#");

        } catch (any e) {
            logExecution("Query failed", {
                error: e.message,
                type: e.type
            });
            return errorResult("Query failed: #e.message#");
        }
    }
}
