<!DOCTYPE html>
<html>
<head>
    <title>Simple JSON-RPC Test</title>
</head>
<body>
    <h1>Simple JSON-RPC Test</h1>
    <button onclick="testOriginal()">Test Original Endpoint</button>
    <button onclick="testDebug()">Test Debug Endpoint</button>
    <pre id="result"></pre>
    
    <script>
    async function testOriginal() {
        await runTest('/mcpcfc/endpoints/messages.cfm');
    }
    
    async function testDebug() {
        await runTest('/mcpcfc/endpoints/messages-debug.cfm');
    }
    
    async function runTest(endpoint) {
        const resultDiv = document.getElementById('result');
        
        const request = {
            jsonrpc: "2.0",
            id: "test-" + Date.now(),
            method: "initialize",
            params: {}
        };
        
        resultDiv.textContent = 'Sending to ' + endpoint + ':\n' + JSON.stringify(request, null, 2) + '\n\n';
        
        try {
            const response = await fetch(endpoint + '?sessionId=test-session', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(request)
            });
            
            const responseText = await response.text();
            resultDiv.textContent += 'Response Status: ' + response.status + '\n';
            resultDiv.textContent += 'Response Headers:\n';
            response.headers.forEach((value, key) => {
                resultDiv.textContent += '  ' + key + ': ' + value + '\n';
            });
            resultDiv.textContent += '\nResponse Body:\n';
            
            try {
                const jsonResponse = JSON.parse(responseText);
                resultDiv.textContent += JSON.stringify(jsonResponse, null, 2);
            } catch (e) {
                resultDiv.textContent += responseText;
            }
        } catch (error) {
            resultDiv.textContent += '\nError: ' + error.message;
        }
    }
    </script>
</body>
</html>