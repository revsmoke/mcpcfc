<!DOCTYPE html>
<html>
<head>
    <title>MCPCFC Database Setup</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>MCPCFC Database Setup</h1>
    
    <cfscript>
    try {
        // Create tools table
        queryExecute("
            CREATE TABLE IF NOT EXISTS tools (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN DEFAULT TRUE
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<p class="success">✅ Created tools table</p>');
        
        // Create tool_executions table for logging
        queryExecute("
            CREATE TABLE IF NOT EXISTS tool_executions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                tool_name VARCHAR(100) NOT NULL,
                input_params TEXT,
                output_result TEXT,
                execution_time INT,
                executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                session_id VARCHAR(255)
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<p class="success">✅ Created tool_executions table</p>');
        
        // Create example_data table for testing
        queryExecute("
            CREATE TABLE IF NOT EXISTS example_data (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(255),
                department VARCHAR(100),
                salary DECIMAL(10,2),
                hire_date DATE,
                is_active BOOLEAN DEFAULT TRUE
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<p class="success">✅ Created example_data table</p>');
        
        // Insert sample data into tools table
        queryExecute("
            INSERT INTO tools (name, description) 
            SELECT * FROM (
                SELECT 'hello' as name, 'A simple greeting tool' as description
                UNION ALL
                SELECT 'queryDatabase', 'Execute database queries'
                UNION ALL
                SELECT 'pdfGenerator', 'Generate PDF documents'
                UNION ALL
                SELECT 'emailSender', 'Send emails'
            ) AS tmp
            WHERE NOT EXISTS (
                SELECT name FROM tools WHERE name = tmp.name
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<p class="success">✅ Inserted tool records</p>');
        
        // Insert sample data into example_data table
        queryExecute("
            INSERT INTO example_data (name, email, department, salary, hire_date) 
            SELECT * FROM (
                SELECT 'John Doe' as name, 'john.doe@example.com' as email, 'Engineering' as department, 
                       85000.00 as salary, '2020-01-15' as hire_date
                UNION ALL
                SELECT 'Jane Smith', 'jane.smith@example.com', 'Marketing', 
                       72000.00, '2021-03-22'
                UNION ALL
                SELECT 'Bob Johnson', 'bob.johnson@example.com', 'Sales', 
                       68000.00, '2019-11-08'
                UNION ALL
                SELECT 'Alice Williams', 'alice.williams@example.com', 'Engineering', 
                       92000.00, '2018-07-01'
                UNION ALL
                SELECT 'Charlie Brown', 'charlie.brown@example.com', 'HR', 
                       65000.00, '2022-02-14'
            ) AS tmp
            WHERE NOT EXISTS (
                SELECT email FROM example_data WHERE email = tmp.email
            )
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<p class="success">✅ Inserted example data</p>');
        
        // Show current data
        writeOutput('<h2>Current Database Contents:</h2>');
        
        // Show tools
        toolsQuery = queryExecute("SELECT * FROM tools ORDER BY id", {}, {datasource: "mcpcfc_ds"});
        writeOutput('<h3>Tools Table:</h3>');
        writeDump(toolsQuery);
        
        // Show example data
        exampleQuery = queryExecute("SELECT * FROM example_data ORDER BY id", {}, {datasource: "mcpcfc_ds"});
        writeOutput('<h3>Example Data Table:</h3>');
        writeDump(exampleQuery);
        
        writeOutput('<h2>Sample Queries to Test:</h2>');
        writeOutput('<pre>
SELECT * FROM tools WHERE is_active = true
SELECT name, department, salary FROM example_data WHERE department = "Engineering"
SELECT COUNT(*) as total, AVG(salary) as avg_salary FROM example_data
SELECT department, COUNT(*) as count, AVG(salary) as avg_salary FROM example_data GROUP BY department
        </pre>');
        
    } catch (any e) {
        writeOutput('<p class="error">❌ Error: ' & e.message & '</p>');
        writeDump(e);
    }
    </cfscript>
</body>
</html>