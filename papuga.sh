#!/bin/bash

# Papuga - Powtarzacz Glosu - Start Script
# This script starts the HTTP server and creates an HTTPS tunnel with ngrok

PORT=8000
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🦜 Starting Papuga (Voice Parrot)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down..."
    if [ ! -z "$HTTP_PID" ]; then
        kill $HTTP_PID 2>/dev/null
    fi
    if [ ! -z "$NGROK_PID" ]; then
        kill $NGROK_PID 2>/dev/null
    fi
    exit 0
}

# Set up cleanup on script exit
trap cleanup EXIT INT TERM

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok is not installed!"
    echo ""
    echo "Please install ngrok:"
    echo "  brew install ngrok"
    echo ""
    echo "Or download from: https://ngrok.com/download"
    exit 1
fi

# Start HTTP server
cd "$SCRIPT_DIR"
echo "🌐 Starting HTTP server on port $PORT..."
python3 -m http.server $PORT > /dev/null 2>&1 &
HTTP_PID=$!

# Wait for server to start
sleep 2

# Check if server started successfully
if ! kill -0 $HTTP_PID 2>/dev/null; then
    echo "❌ Failed to start HTTP server"
    exit 1
fi

echo "✅ HTTP server running (PID: $HTTP_PID)"
echo ""

# Start ngrok tunnel
echo "🔒 Creating HTTPS tunnel with ngrok..."
ngrok http $PORT --log=stdout > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to start
sleep 3

# Get the public URL from ngrok API
NGROK_URL=""
for i in {1..10}; do
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | grep -o 'https://.*' | head -1)
    if [ ! -z "$NGROK_URL" ]; then
        break
    fi
    sleep 1
done

if [ -z "$NGROK_URL" ]; then
    echo "❌ Failed to get ngrok URL"
    echo "Check the ngrok dashboard at: http://localhost:4040"
    echo ""
    echo "Press Ctrl+C to stop the servers"
    wait
else
    echo "✅ HTTPS tunnel created!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 Access Papuga at:"
    echo ""
    echo "   $NGROK_URL/papuga.html"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 Local access: http://localhost:$PORT/papuga.html"
    echo "🌍 ngrok dashboard: http://localhost:4040"
    echo ""
    echo "Press Ctrl+C to stop the servers"
    echo ""

    # Wait for user to stop
    wait
fi
