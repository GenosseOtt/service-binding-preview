require('dotenv').config();
const http = require('http');

const PORT = process.env.PORT || 3000;
const APP_NAME = process.env.APP_NAME || 'Service Binding Preview';
const ENVIRONMENT = process.env.ENVIRONMENT || 'development';
const API_KEY = process.env.API_KEY || 'not-set';
const DATABASE_URL = process.env.DATABASE_URL || 'not-set';
const VERSION = process.env.VERSION || '1.0.0';

const server = http.createServer((req, res) => {
  if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${APP_NAME}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 16px;
            padding: 40px;
            max-width: 600px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2.5rem;
        }
        .subtitle {
            color: #6b7280;
            margin-bottom: 30px;
            font-size: 1.1rem;
        }
        .env-section {
            background: #f9fafb;
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
        }
        .env-section h2 {
            color: #374151;
            font-size: 1.3rem;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .env-item {
            display: flex;
            justify-content: space-between;
            padding: 12px;
            margin-bottom: 8px;
            background: white;
            border-radius: 6px;
            border-left: 4px solid #667eea;
        }
        .env-key {
            font-weight: 600;
            color: #374151;
        }
        .env-value {
            color: #6b7280;
            font-family: 'Courier New', monospace;
            background: #f3f4f6;
            padding: 4px 8px;
            border-radius: 4px;
        }
        .status {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: 600;
            margin-top: 10px;
        }
        .status.production {
            background: #10b981;
            color: white;
        }
        .status.development {
            background: #f59e0b;
            color: white;
        }
        .emoji {
            font-size: 1.5rem;
        }
        @media (max-width: 600px) {
            .container {
                padding: 30px 20px;
            }
            h1 {
                font-size: 2rem;
            }
            .env-item {
                flex-direction: column;
                gap: 8px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>👋 Hello World!</h1>
        <p class="subtitle">Service Binding Preview Application</p>
        <span class="status ${ENVIRONMENT}">${ENVIRONMENT.toUpperCase()}</span>

        <div class="env-section">
            <h2><span class="emoji">⚙️</span> Environment Variables</h2>
            <div class="env-item">
                <span class="env-key">APP_NAME</span>
                <span class="env-value">${APP_NAME}</span>
            </div>
            <div class="env-item">
                <span class="env-key">ENVIRONMENT</span>
                <span class="env-value">${ENVIRONMENT}</span>
            </div>
            <div class="env-item">
                <span class="env-key">VERSION</span>
                <span class="env-value">${VERSION}</span>
            </div>
            <div class="env-item">
                <span class="env-key">PORT</span>
                <span class="env-value">${PORT}</span>
            </div>
            <div class="env-item">
                <span class="env-key">API_KEY</span>
                <span class="env-value">${API_KEY === 'not-set' ? '🔒 not-set' : '🔑 ****' + API_KEY.slice(-4)}</span>
            </div>
            <div class="env-item">
                <span class="env-key">DATABASE_URL</span>
                <span class="env-value">${DATABASE_URL === 'not-set' ? '🔒 not-set' : '🗄️ ' + DATABASE_URL.substring(0, 20) + '...'}</span>
            </div>
        </div>
    </div>
</body>
</html>
    `);
  } else if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      environment: ENVIRONMENT,
      version: VERSION
    }));
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📦 Environment: ${ENVIRONMENT}`);
  console.log(`📝 App Name: ${APP_NAME}`);
  console.log(`🔗 Visit: http://localhost:${PORT}`);
});
