#!/bin/bash
# Hub Registry v1.0 Installation Script
# Usage: ./install.sh

set -e

echo "========================================="
echo "   Hub Registry v1.0 Installation"
echo "========================================="

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo or as root"
    exit 1
fi

# 1. Load Docker images
echo ""
echo "[Step 1] Loading Docker images..."
for img in images/*.tar.gz; do
    if [ -f "$img" ]; then
        echo "Loading: $img"
        docker load < "$img"
    fi
done
echo "Images loaded successfully."

# 2. Verify images
echo ""
echo "[Step 2] Verifying loaded images..."
docker images --format "{{.Repository}}:{{.Tag}}" | grep "hub-registry" || {
    echo "Error: Images not loaded correctly"
    exit 1
}

# 3. Deploy containers
echo ""
echo "[Step 3] Deploying containers..."
cd config
docker-compose up -d
cd ..

# 4. Wait for services to be ready
echo ""
echo "[Step 4] Waiting for services to be ready..."
sleep 30

# 5. Check service status
echo ""
echo "[Step 5] Checking service status..."
docker-compose -f config/docker-compose.yml ps

echo ""
echo "========================================="
echo "   Installation Complete!"
echo "========================================="
echo ""
echo "Access the application at:"
echo "  - Web UI: http://localhost:3000"
echo "  - API Gateway: http://localhost:8080"
echo "  - Registry: http://localhost:5000"
echo ""
echo "Default admin credentials:"
echo "  - Username: admin"
echo "  - Password: admin123"
echo ""
echo "To manage the services:"
echo "  - Stop: docker-compose -f config/docker-compose.yml down"
echo "  - Restart: docker-compose -f config/docker-compose.yml restart"
echo ""