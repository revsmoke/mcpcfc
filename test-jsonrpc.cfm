<!DOCTYPE html>
<html>
<head>
    <title>JSON-RPC Debug Test</title>
</head>
<body>
    <h1>JSON-RPC Debug Test</h1>
    <button onclick="testDebug()">Test Debug Endpoint</button>
    <button onclick="testOriginal()">Test Original Endpoint</button>
    <pre id="result"></pre>
    
    <script>
        async function testDebug() {
            const request = {
                jsonrpc: "2.0",
                id: "test-123",
                method: "initialize",
                params: {}
            };
            
            console.log('Sending:', request);
            document.getElementById('result').textContent = 'Sending: ' + JSON.stringify(request, null, 2);
            
            try {
                const response = await fetch('/mcpcfc/endpoints/debug-messages.cfm?sessionId=test', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(request)
                });
                
                const data = await response.json();
                console.log('Response:', data);
                document.getElementById('result').textContent += '\n\nResponse: ' + JSON.stringify(data, null, 2);
            } catch (error) {
                console.error('Error:', error);
                document.getElementById('result').textContent += '\n\nError: ' + error;
            }
        }
        
        async function testOriginal() {
            const request = {
                jsonrpc: "2.0",
                id: "test-456",
                method: "initialize",
                params: {}
            };
            
            console.log('Sending:', request);
            document.getElementById('result').textContent = 'Sending: ' + JSON.stringify(request, null, 2);
            
            try {
                const response = await fetch('/mcpcfc/endpoints/messages.cfm?sessionId=test', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(request)
                });
                
                const data = await response.json();
                console.log('Response:', data);
                document.getElementById('result').textContent += '\n\nResponse: ' + JSON.stringify(data, null, 2);
            } catch (error) {
                console.error('Error:', error);
                document.getElementById('result').textContent += '\n\nError: ' + error;
            }
        }
    </script>
</body>
</html>