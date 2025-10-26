#!/bin/bash
# Quick deployment script for Carbonio Mailbox with Docker

set -e

echo "========================================"
echo "🐳 Carbonio Mailbox - Docker Deployment"
echo "========================================"
echo ""

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed"
    echo "Install it first: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running"
    echo "Please start Docker Desktop or Docker daemon"
    exit 1
fi

echo "✅ Docker is ready"
echo ""

# Function to show help
show_help() {
    echo "Usage: ./docker-deploy.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start       - Build and start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  logs        - View logs"
    echo "  status      - Check status of services"
    echo "  clean       - Stop and remove all containers, networks, volumes"
    echo "  setup       - Initial setup with test accounts"
    echo "  help        - Show this help"
    echo ""
}

# Function to start services
start_services() {
    echo "📦 Building Docker images..."
    echo "This may take 10-15 minutes on first run..."
    echo ""

    docker-compose build

    echo ""
    echo "🚀 Starting services..."
    docker-compose up -d

    echo ""
    echo "⏳ Waiting for services to be ready..."
    echo "This may take 2-3 minutes..."
    sleep 10

    # Wait for mailbox to be healthy
    echo "Waiting for mailbox service..."
    for i in {1..30}; do
        if docker-compose exec -T mailbox curl -f http://localhost:8080/service/soap 2>/dev/null | grep -q "empty request"; then
            echo "✅ Mailbox service is ready!"
            break
        fi
        echo -n "."
        sleep 5
    done

    echo ""
    echo ""
    echo "=========================================="
    echo "✅ Carbonio Mailbox is running!"
    echo "=========================================="
    echo ""
    echo "Services:"
    echo "  • Mailbox API:  http://localhost:8080/service/soap"
    echo "  • Admin API:    http://localhost:7071/service/admin/soap"
    echo "  • HTTPS:        https://localhost:8443"
    echo "  • MariaDB:      localhost:3306"
    echo "  • OpenLDAP:     localhost:1389"
    echo ""
    echo "Next steps:"
    echo "  1. Create test accounts: ./docker-deploy.sh setup"
    echo "  2. View logs:           ./docker-deploy.sh logs"
    echo "  3. Check status:        ./docker-deploy.sh status"
    echo ""
}

# Function to stop services
stop_services() {
    echo "🛑 Stopping services..."
    docker-compose down
    echo "✅ Services stopped"
}

# Function to restart services
restart_services() {
    echo "🔄 Restarting services..."
    docker-compose restart
    echo "✅ Services restarted"
}

# Function to view logs
view_logs() {
    echo "📋 Viewing logs (Ctrl+C to exit)..."
    docker-compose logs -f
}

# Function to check status
check_status() {
    echo "📊 Service Status:"
    echo ""
    docker-compose ps
    echo ""

    # Check if mailbox is responding
    if curl -f http://localhost:8080/service/soap 2>/dev/null | grep -q "empty request"; then
        echo "✅ Mailbox API is responding"
    else
        echo "❌ Mailbox API is not responding"
    fi
}

# Function to clean everything
clean_all() {
    echo "⚠️  WARNING: This will remove all containers, networks, and volumes!"
    echo "All data will be lost!"
    read -p "Are you sure? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        echo "🧹 Cleaning up..."
        docker-compose down -v --rmi all
        echo "✅ All cleaned up"
    else
        echo "❌ Cancelled"
    fi
}

# Function to setup test accounts
setup_accounts() {
    echo "🔧 Setting up test accounts..."
    echo ""

    # Wait for service to be ready
    echo "Checking if mailbox is ready..."
    if ! docker-compose exec -T mailbox curl -f http://localhost:8080/service/soap 2>/dev/null | grep -q "empty request"; then
        echo "❌ Mailbox service is not ready yet"
        echo "Please wait a few minutes and try again"
        exit 1
    fi

    echo "✅ Mailbox is ready"
    echo ""

    echo "Creating domain: test.com"
    docker-compose exec -T mailbox zmprov createDomain test.com || echo "Domain may already exist"

    echo "Creating admin account: admin@test.com"
    docker-compose exec -T mailbox zmprov createAccount admin@test.com password zimbraIsAdminAccount TRUE || echo "Account may already exist"

    echo "Creating user account: user@test.com"
    docker-compose exec -T mailbox zmprov createAccount user@test.com password || echo "Account may already exist"

    echo ""
    echo "=========================================="
    echo "✅ Test accounts created!"
    echo "=========================================="
    echo ""
    echo "Accounts:"
    echo "  • admin@test.com / password (admin)"
    echo "  • user@test.com / password (user)"
    echo ""
    echo "Test authentication:"
    echo "  curl -X POST http://localhost:8080/service/soap \\"
    echo "    -H 'Content-Type: application/soap+xml' \\"
    echo "    -d '<?xml version=\"1.0\"?>"
    echo "  <soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\">"
    echo "    <soap:Body>"
    echo "      <AuthRequest xmlns=\"urn:zimbraAccount\">"
    echo "        <account by=\"name\">user@test.com</account>"
    echo "        <password>password</password>"
    echo "      </AuthRequest>"
    echo "    </soap:Body>"
    echo "  </soap:Envelope>'"
    echo ""
}

# Main script logic
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        view_logs
        ;;
    status)
        check_status
        ;;
    clean)
        clean_all
        ;;
    setup)
        setup_accounts
        ;;
    help|*)
        show_help
        ;;
esac
