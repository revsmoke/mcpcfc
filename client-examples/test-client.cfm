<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ColdFusion MCP Server Test Client</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        .panel {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1, h2 {
            color: #333;
        }
        button {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        button:hover {
            background-color: #0056b3;
        }
        #status {
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
        }
        .connected { background-color: #d4edda; color: #155724; }
        .disconnected { background-color: #f8d7da; color: #721c24; }
        #log {
            height: 400px;
            overflow-y: auto;
            background: #f8f9fa;
            padding: 10px;
            border-radius: 4px;
            font-family: monospace;
            font-size: 12px;
        }        .log-entry {
            margin: 5px 0;
            padding: 5px;
            border-bottom: 1px solid #ddd;
        }
        input[type="text"] {
            width: 100%;
            padding: 8px;
            margin: 5px 0;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <h1>ColdFusion MCP Server Test Client</h1>
    
    <div id="status" class="disconnected">Disconnected</div>
    
    <div class="container">
        <div class="panel">
            <h2>Controls</h2>
            <button onclick="connect()">Connect</button>
            <button onclick="disconnect()">Disconnect</button>
            <button onclick="initialize()">Initialize</button>
            <button onclick="listTools()">List Tools</button>
            
            <h3>Test Hello Tool</h3>
            <input type="text" id="helloName" placeholder="Enter name" value="ColdFusion Developer">
            <button onclick="callHello()">Call Hello Tool</button>
            
            <h3>Test Database Tool</h3>
            <input type="text" id="dbQuery" placeholder="SQL Query" value="SELECT * FROM example_data LIMIT 10">
            <input type="text" id="dbDatasource" placeholder="Datasource" value="mcpcfc_ds">
            <button onclick="callDatabase()">Execute Query</button>
        </div>
        
        <div class="panel">
            <h2>Log</h2>
            <button onclick="clearLog()">Clear Log</button>
            <div id="log"></div>
        </div>
    </div>

    <script>
        let eventSource = null;
        let sessionId = null;

        function log(message, data = null) {
            const logDiv = document.getElementById('log');
            const entry = document.createElement('div');
            entry.className = 'log-entry';            const timestamp = new Date().toLocaleTimeString();
            entry.innerHTML = `<strong>[${timestamp}]</strong> ${message}`;
            if (data) {
                entry.innerHTML += '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            }
            logDiv.appendChild(entry);
            logDiv.scrollTop = logDiv.scrollHeight;
        }

        function updateStatus(connected) {
            const status = document.getElementById('status');
            if (connected) {
                status.className = 'connected';
                status.textContent = `Connected (Session: ${sessionId})`;
            } else {
                status.className = 'disconnected';
                status.textContent = 'Disconnected';
            }
        }

        function connect() {
            if (eventSource) {
                eventSource.close();
            }
            
            sessionId = crypto.randomUUID();
            const url = `/mcpcfc/endpoints/sse.cfm?sessionId=${sessionId}`;
            
            log(`Connecting to ${url}...`);
            eventSource = new EventSource(url);
            
            eventSource.addEventListener('connection', (event) => {
                const data = JSON.parse(event.data);
                log('Connection established', data);
                updateStatus(true);
            });
            
            eventSource.addEventListener('mcp', (event) => {
                const data = JSON.parse(event.data);
                log('MCP Response', data);
            });
            
            eventSource.addEventListener('heartbeat', (event) => {
                log('Heartbeat: ' + event.data);
            });
            
            eventSource.addEventListener('error', (event) => {
                log('SSE Error', event);
                updateStatus(false);
            });
        }
        function disconnect() {
            if (eventSource) {
                eventSource.close();
                eventSource = null;
                log('Disconnected');
                updateStatus(false);
            }
        }

        async function sendRequest(method, params = {}) {
            if (!sessionId) {
                log('Error: Not connected');
                return;
            }
            
            const url = `/mcpcfc/endpoints/messages.cfm?sessionId=${sessionId}`;
            const request = {
                jsonrpc: '2.0',
                id: crypto.randomUUID(),
                method: method,
                params: params
            };
            
            log(`Sending ${method} request`, request);
            
            try {
                const response = await fetch(url, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(request)
                });
                
                const data = await response.json();
                log(`${method} response`, data);
                return data;
            } catch (error) {
                log(`Error sending ${method}`, error);
            }
        }

        function initialize() {
            sendRequest('initialize');
        }

        function listTools() {
            sendRequest('tools/list');
        }
        function callHello() {
            const name = document.getElementById('helloName').value;
            sendRequest('tools/call', {
                name: 'hello',
                arguments: { name: name }
            });
        }

        function callDatabase() {
            const query = document.getElementById('dbQuery').value;
            const datasource = document.getElementById('dbDatasource').value;
            sendRequest('tools/call', {
                name: 'queryDatabase',
                arguments: { 
                    query: query,
                    datasource: datasource
                }
            });
        }

        function clearLog() {
            document.getElementById('log').innerHTML = '';
        }

        // Auto-connect on load
        window.addEventListener('load', () => {
            log('Test client ready. Click "Connect" to start.');
        });
    </script>
</body>
</html>