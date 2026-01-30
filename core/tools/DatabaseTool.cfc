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

        setInputSchema({
            type: "object",
            properties: {
                query: {
                    type: "string",
                    description: "SQL SELECT query to execute. Only SELECT statements are allowed."
                },
                datasource: {
                    type: "string",
                    description: "Database datasource name (optional, uses default if not provided)"
                }
            },
            required: ["query"]
        });

        setOutputSchema({
            type: "object",
            properties: {
                recordCount: {
                    type: "number",
                    description: "Number of records returned"
                },
                columns: {
                    type: "string",
                    description: "Comma-separated list of column names"
                },
                data: {
                    type: "array",
                    description: "Array of row objects"
                }
            }
        });

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
