import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { WebSocketService } from '@/services/websocket-service'
import { getActiveConnectionsCount, getSessionParticipants, getSessionRealtimeInfo } from '@/websocket'

type Variables = {
  user: AuthContext
}

const websocketRoutes = new Hono<{ Variables: Variables }>()

// Get WebSocket connection statistics
websocketRoutes.get('/stats', async (c) => {
  try {
    const stats = {
      activeConnections: getActiveConnectionsCount(),
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      timestamp: new Date().toISOString(),
    }

    return c.json(stats)
  } catch (error) {
    console.error('Error getting WebSocket stats:', error)
    return c.json({ error: 'Failed to get WebSocket stats' }, 500)
  }
})

// Get real-time session information
websocketRoutes.get('/session/:sessionId/info', async (c) => {
  const sessionId = c.req.param('sessionId')

  try {
    const sessionInfo = await getSessionRealtimeInfo(sessionId)
    
    if (!sessionInfo) {
      return c.json({ error: 'Session not found' }, 404)
    }

    return c.json(sessionInfo)
  } catch (error) {
    console.error('Error getting session realtime info:', error)
    return c.json({ error: 'Failed to get session info' }, 500)
  }
})

// Get session participants (WebSocket connections)
websocketRoutes.get('/session/:sessionId/participants', async (c) => {
  const sessionId = c.req.param('sessionId')

  try {
    const participants = getSessionParticipants(sessionId)
    
    return c.json({
      sessionId,
      participantCount: participants.length,
      participants: participants.map(p => ({
        userId: p.userId,
        email: p.email,
        sessionId: p.sessionId,
      })),
    })
  } catch (error) {
    console.error('Error getting session participants:', error)
    return c.json({ error: 'Failed to get session participants' }, 500)
  }
})

// Broadcast a test message to a session (for testing purposes)
websocketRoutes.post('/session/:sessionId/broadcast', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('sessionId')
  const body = await c.req.json()

  try {
    if (!body.message || !body.type) {
      return c.json({ error: 'Message type and content are required' }, 400)
    }

    // Custom message broadcasting removed - not needed for Mode 1

    return c.json({ 
      message: 'Message broadcast functionality removed',
      sessionId,
      type: body.type,
    })
  } catch (error) {
    console.error('Error broadcasting test message:', error)
    return c.json({ error: 'Failed to broadcast message' }, 500)
  }
})

// Get WebSocket connection health check
websocketRoutes.get('/health', async (c) => {
  try {
    const connectionCount = getActiveConnectionsCount()
    const isHealthy = connectionCount >= 0

    return c.json({
      status: isHealthy ? 'healthy' : 'unhealthy',
      activeConnections: connectionCount,
      timestamp: new Date().toISOString(),
    })
  } catch (error) {
    console.error('Error checking WebSocket health:', error)
    return c.json({ error: 'Failed to check health' }, 500)
  }
})

// Get WebSocket connection health check
websocketRoutes.get('/health', async (c) => {
  try {
    const connectionCount = getActiveConnectionsCount()
    const isHealthy = connectionCount >= 0

    return c.json({
      status: isHealthy ? 'healthy' : 'unhealthy',
      activeConnections: connectionCount,
      timestamp: new Date().toISOString(),
    })
  } catch (error) {
    console.error('Error in WebSocket health check:', error)
    return c.json({ 
      status: 'unhealthy', 
      error: 'Health check failed',
      timestamp: new Date().toISOString(),
    }, 500)
  }
})

// WebSocket test page (simple HTML page for testing WebSocket connections)
websocketRoutes.get('/test', async (c) => {
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WebSocket Test - Quizzy</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .status {
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
        }
        .connected {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .disconnected {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .messages {
            height: 300px;
            overflow-y: auto;
            border: 1px solid #ddd;
            padding: 10px;
            margin: 10px 0;
            background-color: #f9f9f9;
        }
        .message {
            margin: 5px 0;
            padding: 5px;
            border-radius: 3px;
        }
        .sent {
            background-color: #e3f2fd;
            text-align: right;
        }
        .received {
            background-color: #f3e5f5;
        }
        input, button, select {
            padding: 8px;
            margin: 5px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        button {
            background-color: #007bff;
            color: white;
            cursor: pointer;
        }
        button:disabled {
            background-color: #ccc;
            cursor: not-allowed;
        }
        .form-group {
            margin: 10px 0;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>WebSocket Test - Quizzy</h1>
        
        <div class="form-group">
            <label for="token">JWT Token:</label>
            <input type="text" id="token" placeholder="Enter your JWT token" style="width: 100%;">
        </div>
        
        <div class="form-group">
            <label for="sessionId">Session ID:</label>
            <input type="text" id="sessionId" placeholder="Enter session ID to join">
        </div>
        
        <button id="connect" onclick="connectWebSocket()">Connect</button>
        <button id="disconnect" onclick="disconnectWebSocket()" disabled>Disconnect</button>
        <button id="join" onclick="joinSession()" disabled>Join Session</button>
        <button id="leave" onclick="leaveSession()" disabled>Leave Session</button>
        <button id="ping" onclick="sendPing()" disabled>Send Ping</button>
        
        <div id="status" class="status disconnected">Disconnected</div>
        
        <h3>Messages:</h3>
        <div id="messages" class="messages"></div>
        
        <div class="form-group">
            <label for="messageType">Message Type:</label>
            <select id="messageType">
                <option value="ping">Ping</option>
                <option value="join_session">Join Session</option>
                <option value="leave_session">Leave Session</option>
            </select>
        </div>
        
        <div class="form-group">
            <label for="customMessage">Custom Message (JSON):</label>
            <input type="text" id="customMessage" placeholder='{"type":"custom","data":"test"}'>
            <button onclick="sendCustomMessage()">Send Custom</button>
        </div>
    </div>

    <script>
        let ws = null;
        const messagesDiv = document.getElementById('messages');
        const statusDiv = document.getElementById('status');
        const connectBtn = document.getElementById('connect');
        const disconnectBtn = document.getElementById('disconnect');
        const joinBtn = document.getElementById('join');
        const leaveBtn = document.getElementById('leave');
        const pingBtn = document.getElementById('ping');

        function addMessage(message, type = 'received') {
            const messageDiv = document.createElement('div');
            messageDiv.className = \`message \${type}\`;
            messageDiv.textContent = \`\${new Date().toLocaleTimeString()}: \${message}\`;
            messagesDiv.appendChild(messageDiv);
            messagesDiv.scrollTop = messagesDiv.scrollHeight;
        }

        function updateStatus(connected) {
            if (connected) {
                statusDiv.textContent = 'Connected';
                statusDiv.className = 'status connected';
                connectBtn.disabled = true;
                disconnectBtn.disabled = false;
                joinBtn.disabled = false;
                leaveBtn.disabled = false;
                pingBtn.disabled = false;
            } else {
                statusDiv.textContent = 'Disconnected';
                statusDiv.className = 'status disconnected';
                connectBtn.disabled = false;
                disconnectBtn.disabled = true;
                joinBtn.disabled = true;
                leaveBtn.disabled = true;
                pingBtn.disabled = true;
            }
        }

        function connectWebSocket() {
            const token = document.getElementById('token').value.trim();
            if (!token) {
                alert('Please enter a JWT token');
                return;
            }

            const wsUrl = \`ws://localhost:8000/ws\`;
            ws = new WebSocket(wsUrl);

            ws.onopen = function() {
                addMessage('WebSocket connection opened', 'sent');
                updateStatus(true);
                
                // Send authentication token
                ws.send(JSON.stringify({
                    type: 'auth',
                    token: token
                }));
                addMessage('Authentication token sent', 'sent');
            };

            ws.onmessage = function(event) {
                try {
                    const data = JSON.parse(event.data);
                    addMessage(\`Received: \${JSON.stringify(data, null, 2)}\`, 'received');
                } catch (e) {
                    addMessage(\`Received raw: \${event.data}\`, 'received');
                }
            };

            ws.onclose = function() {
                addMessage('WebSocket connection closed', 'received');
                updateStatus(false);
            };

            ws.onerror = function(error) {
                addMessage(\`WebSocket error: \${error}\`, 'received');
                updateStatus(false);
            };
        }

        function disconnectWebSocket() {
            if (ws) {
                ws.close();
                ws = null;
            }
        }

        function joinSession() {
            const sessionId = document.getElementById('sessionId').value.trim();
            if (!sessionId) {
                alert('Please enter a session ID');
                return;
            }

            if (ws && ws.readyState === WebSocket.OPEN) {
                const message = {
                    type: 'join_session',
                    sessionId: sessionId
                };
                ws.send(JSON.stringify(message));
                addMessage(\`Sent: \${JSON.stringify(message)}\`, 'sent');
            }
        }

        function leaveSession() {
            const sessionId = document.getElementById('sessionId').value.trim();
            if (!sessionId) {
                alert('Please enter a session ID');
                return;
            }

            if (ws && ws.readyState === WebSocket.OPEN) {
                const message = {
                    type: 'leave_session',
                    sessionId: sessionId
                };
                ws.send(JSON.stringify(message));
                addMessage(\`Sent: \${JSON.stringify(message)}\`, 'sent');
            }
        }

        function sendPing() {
            if (ws && ws.readyState === WebSocket.OPEN) {
                const message = { type: 'ping' };
                ws.send(JSON.stringify(message));
                addMessage(\`Sent: \${JSON.stringify(message)}\`, 'sent');
            }
        }

        function sendCustomMessage() {
            const customMessage = document.getElementById('customMessage').value.trim();
            if (!customMessage) {
                alert('Please enter a custom message');
                return;
            }

            if (ws && ws.readyState === WebSocket.OPEN) {
                try {
                    const message = JSON.parse(customMessage);
                    ws.send(JSON.stringify(message));
                    addMessage(\`Sent: \${JSON.stringify(message)}\`, 'sent');
                } catch (e) {
                    alert('Invalid JSON format');
                }
            }
        }

        // Initialize
        updateStatus(false);
    </script>
</body>
</html>
  `

  return c.html(html)
})

export default websocketRoutes