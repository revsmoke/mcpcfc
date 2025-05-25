<!DOCTYPE html>
<html>
<head>
    <title>MCP CFC Debug Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .test-section { margin: 20px 0; border: 1px solid #ccc; padding: 15px; }
        .test-title { font-weight: bold; margin-bottom: 10px; }
        .response { background: #f0f0f0; padding: 10px; margin: 10px 0; white-space: pre-wrap; font-family: monospace; }
        .error { background: #fee; }
        .success { background: #efe; }
        button { margin: 5px; padding: 5px 10px; }
    </style>
</head>
<body>
    <h1>MCP CFC Debug Test Suite</h1>
    
    <cfscript>
    // Function to capture raw request body
    function getRawRequestBody() {
        try {
            var rawData = toString(getHttpRequestData().content);
            return rawData;
        } catch (any e) {
            return "Error getting raw body: " & e.message;
        }
    }
    
    // Display current request info
    writeOutput('<div class="test-section">');
    writeOutput('<div class="test-title">Current Request Information:</div>');
    writeOutput('<div class="response">');
    
    try {
        var requestData = getHttpRequestData();
        writeOutput("Method: " & requestData.method & chr(10));
        writeOutput("Headers:" & chr(10));
        for (var header in requestData.headers) {
            writeOutput("  " & header & ": " & requestData.headers[header] & chr(10));
        }
        writeOutput(chr(10) & "Raw Body: " & getRawRequestBody());
    } catch (any e) {
        writeOutput("Error: " & e.message);
    }
    
    writeOutput('</div></div>');
    </cfscript>
    
    <!-- Test 1: Direct POST with JSON -->
    <div class="test-section">
        <div class="test-title">Test 1: Direct POST to messages.cfm with JSON-RPC</div>
        <button onclick="testDirectPost()">Run Test</button>
        <div id="test1-response" class="response"></div>
    </div>
    
    <!-- Test 2: POST with different content types -->
    <div class="test-section">
        <div class="test-title">Test 2: POST with different Content-Types</div>
        <button onclick="testContentTypes()">Run Test</button>
        <div id="test2-response" class="response"></div>
    </div>
    
    <!-- Test 3: GET Request Test -->
    <div class="test-section">
        <div class="test-title">Test 3: GET Request (should fail)</div>
        <button onclick="testGetRequest()">Run Test</button>
        <div id="test3-response" class="response"></div>
    </div>
    
    <!-- Test 4: Raw XMLHttpRequest -->
    <div class="test-section">
        <div class="test-title">Test 4: Raw XMLHttpRequest</div>
        <button onclick="testRawXHR()">Run Test</button>
        <div id="test4-response" class="response"></div>
    </div>
    
    <!-- Test 5: Test with cfhttp -->
    <div class="test-section">
        <div class="test-title">Test 5: Server-side cfhttp test</div>
        <button onclick="testCfhttp()">Run Test</button>
        <div id="test5-response" class="response"></div>
    </div>
    
    <!-- Test 6: Form POST -->
    <div class="test-section">
        <div class="test-title">Test 6: Form POST (should fail with wrong content type)</div>
        <form action="endpoints/messages.cfm" method="POST" target="formFrame">
            <textarea name="body" style="width: 100%; height: 60px;">{"jsonrpc": "2.0", "method": "test", "params": {}, "id": 1}</textarea>
            <br>
            <input type="submit" value="Submit Form">
        </form>
        <iframe name="formFrame" style="width: 100%; height: 200px; border: 1px solid #ccc;"></iframe>
    </div>
    
    <script>
    // Test 1: Direct POST
    async function testDirectPost() {
        const responseDiv = document.getElementById('test1-response');
        responseDiv.innerHTML = 'Testing...';
        
        const requestBody = {
            jsonrpc: "2.0",
            method: "tools/list",
            params: {},
            id: 1
        };
        
        try {
            const response = await fetch('endpoints/messages.cfm', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestBody)
            });
            
            const responseText = await response.text();
            responseDiv.innerHTML = `Status: ${response.status}\nHeaders: ${JSON.stringify([...response.headers])}\nBody:\n${responseText}`;
            responseDiv.className = response.ok ? 'response success' : 'response error';
        } catch (error) {
            responseDiv.innerHTML = `Error: ${error.message}`;
            responseDiv.className = 'response error';
        }
    }
    
    // Test 2: Different content types
    async function testContentTypes() {
        const responseDiv = document.getElementById('test2-response');
        responseDiv.innerHTML = 'Testing...';
        
        const contentTypes = [
            'application/json',
            'application/json; charset=utf-8',
            'text/plain',
            'application/x-www-form-urlencoded'
        ];
        
        const requestBody = {
            jsonrpc: "2.0",
            method: "tools/list",
            params: {},
            id: 1
        };
        
        let results = '';
        
        for (const contentType of contentTypes) {
            try {
                const response = await fetch('endpoints/messages.cfm', {
                    method: 'POST',
                    headers: {
                        'Content-Type': contentType
                    },
                    body: JSON.stringify(requestBody)
                });
                
                const responseText = await response.text();
                results += `\n--- Content-Type: ${contentType} ---\n`;
                results += `Status: ${response.status}\n`;
                results += `Response: ${responseText}\n`;
            } catch (error) {
                results += `\n--- Content-Type: ${contentType} ---\n`;
                results += `Error: ${error.message}\n`;
            }
        }
        
        responseDiv.innerHTML = results;
    }
    
    // Test 3: GET request
    async function testGetRequest() {
        const responseDiv = document.getElementById('test3-response');
        responseDiv.innerHTML = 'Testing...';
        
        try {
            const response = await fetch('endpoints/messages.cfm', {
                method: 'GET'
            });
            
            const responseText = await response.text();
            responseDiv.innerHTML = `Status: ${response.status}\nBody:\n${responseText}`;
            responseDiv.className = 'response error';
        } catch (error) {
            responseDiv.innerHTML = `Error: ${error.message}`;
            responseDiv.className = 'response error';
        }
    }
    
    // Test 4: Raw XMLHttpRequest
    function testRawXHR() {
        const responseDiv = document.getElementById('test4-response');
        responseDiv.innerHTML = 'Testing...';
        
        const xhr = new XMLHttpRequest();
        xhr.open('POST', 'endpoints/messages.cfm', true);
        xhr.setRequestHeader('Content-Type', 'application/json');
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
                responseDiv.innerHTML = `Status: ${xhr.status}\nResponse Headers:\n${xhr.getAllResponseHeaders()}\nResponse Body:\n${xhr.responseText}`;
                responseDiv.className = xhr.status === 200 ? 'response success' : 'response error';
            }
        };
        
        const requestBody = {
            jsonrpc: "2.0",
            method: "tools/list",
            params: {},
            id: 1
        };
        
        xhr.send(JSON.stringify(requestBody));
    }
    
    // Test 5: Server-side cfhttp
    async function testCfhttp() {
        const responseDiv = document.getElementById('test5-response');
        responseDiv.innerHTML = 'Testing server-side request...';
        
        try {
            const response = await fetch('test-cfhttp.cfm');
            const responseText = await response.text();
            responseDiv.innerHTML = responseText;
        } catch (error) {
            responseDiv.innerHTML = `Error: ${error.message}`;
            responseDiv.className = 'response error';
        }
    }
    </script>
    
    <!-- Create companion cfhttp test file -->
    <cfif NOT fileExists(expandPath("test-cfhttp.cfm"))>
        <cffile action="write" file="#expandPath('test-cfhttp.cfm')#" output='
<cfscript>
// Server-side HTTP test
try {
    var requestBody = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 1
    };
    
    cfhttp(
        url="http://localhost:8500/mcpcfc/endpoints/messages.cfm",
        method="POST",
        result="httpResult"
    ) {
        cfhttpparam(type="header", name="Content-Type", value="application/json");
        cfhttpparam(type="body", value=serializeJSON(requestBody));
    }
    
    writeOutput("HTTP Status: " & httpResult.statusCode & chr(10));
    writeOutput("Response Headers:" & chr(10));
    for (var header in httpResult.responseHeader) {
        writeOutput("  " & header & ": " & httpResult.responseHeader[header] & chr(10));
    }
    writeOutput(chr(10) & "Response Body:" & chr(10));
    writeOutput(httpResult.fileContent);
} catch (any e) {
    writeOutput("Error: " & e.message & chr(10));
    writeOutput("Detail: " & e.detail);
}
</cfscript>
        '>
    </cfif>
</body>
</html>