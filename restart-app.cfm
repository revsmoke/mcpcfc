<!DOCTYPE html>
<html>
<head>
    <title>Restart Application</title>
</head>
<body>
    <h1>Restarting MCP Server Application</h1>
    <cfscript>
        applicationStop();
        location("index.cfm", false);
    </cfscript>
</body>
</html>