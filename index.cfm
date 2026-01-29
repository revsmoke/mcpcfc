<!DOCTYPE html>
<html>
<head>
    <title>ColdFusion MCP Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .button {
            display: inline-block;
            padding: 10px 20px;
            margin: 10px 5px;
            background-color: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .button:hover {
            background-color: #0056b3;
        }
        code {
            background-color: #f8f9fa;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>ColdFusion MCP Server</h1>
        <p>Welcome to the ColdFusion implementation of the Model Context Protocol (MCP) server.</p>
        
        <h2>Quick Links</h2>
        <a href="client-examples/test-client.cfm" class="button">Test Client</a>
        <a href="README.md" class="button">Documentation</a>
        
        <h2>Endpoints</h2>
        <ul>
            <li>MCP Endpoint: <code>/mcpcfc/endpoints/mcp.cfm</code> (unified HTTP endpoint)</li>
        </ul>
        
        <h2>Status</h2>
        <p>Server is ready. Use the test client to connect and interact with the MCP server.</p>
    </div>
</body>
</html>