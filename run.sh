#!/bin/bash
# Quick start script for Carbonio Mailbox

echo "========================================"
echo "🚀 Starting Carbonio Mailbox Service"
echo "========================================"
echo ""

# Check if already running
if lsof -i :8080 >/dev/null 2>&1; then
    echo "⚠️  Service already running on port 8080"
    echo ""
    echo "To stop it first:"
    echo "  kill \$(lsof -ti:8080)"
    echo ""
    exit 1
fi

# Check if built
if [ ! -f "store/target/zm-store.jar" ]; then
    echo "📦 Building project (first time)..."
    echo "This may take a few minutes..."
    mvn clean install -DskipTests
    if [ $? -ne 0 ]; then
        echo "❌ Build failed"
        exit 1
    fi
    echo "✅ Build complete"
    echo ""
fi

echo "Starting service..."
echo "Press Ctrl+C to stop"
echo ""
echo "Service will be available at:"
echo "  • User API:  http://localhost:8080/service/soap"
echo "  • Admin API: http://localhost:7071/service/admin/soap"
echo "  • HTTPS:     https://localhost:8443"
echo ""
echo "Test accounts:"
echo "  • test@test.com / password"
echo "  • admin@test.com / password"
echo ""
echo "========================================"
echo ""

mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test \
  -Dlog4j.configurationFile=docker/mailbox/log4j.properties
