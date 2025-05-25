<!DOCTYPE html>
<html>
<head>
    <title>Test Messages Endpoint</title>
</head>
<body>
    <h1>Test Messages Endpoint</h1>
    
    <script>
        async function testInitialize() {
            const request = {
                jsonrpc: '2.0',
                id: 'test-123',
                method: 'initialize',
                params: {}
            };
            
            console.log('Sending request:', request);
            
            try {
                const response = await fetch('/mcpcfc/endpoints/messages.cfm?sessionId=test&debug=1', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(request)
                });
                
                const text = await response.text();
                console.log('Raw response:', text);
                
                try {
                    const data = JSON.parse(text);
                    console.log('Parsed response:', data);
                    document.body.innerHTML += '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                } catch (e) {
                    console.error('Failed to parse JSON:', e);
                    document.body.innerHTML += '<pre>Raw response: ' + text + '</pre>';
                }
            } catch (error) {
                console.error('Request failed:', error);
            }
        }
        
        // Test immediately
        testInitialize();
    </script>
</body>
</html>