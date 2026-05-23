#!/bin/bash

# Deploy FastAPI + Streamlit to AWS EC2
# Usage: ./deploy-aws.sh <AWS_INSTANCE_IP> <KEY_FILE> <DOCKER_USERNAME> <DOCKER_PASSWORD>

set -e

AWS_IP=$1
KEY_FILE=$2
DOCKER_USER=$3
DOCKER_PASS=$4
IMAGE_NAME="fastapi-demo-api"

if [ -z "$AWS_IP" ] || [ -z "$KEY_FILE" ]; then
    echo "Usage: ./deploy-aws.sh <AWS_IP> <KEY_FILE> <DOCKER_USER> <DOCKER_PASS>"
    exit 1
fi

echo "🚀 Starting deployment..."

# Build Docker image
echo "📦 Building Docker image..."
docker build -t $DOCKER_USER/$IMAGE_NAME:latest .

# Login to Docker Hub
echo "🔐 Logging into Docker Hub..."
echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin

# Push to Docker Hub
echo "📤 Pushing image to Docker Hub..."
docker push $DOCKER_USER/$IMAGE_NAME:latest

# SSH into AWS and deploy
echo "🌐 Deploying to AWS EC2..."
ssh -i $KEY_FILE ubuntu@$AWS_IP << 'EOF'
    # Update system
    sudo apt update
    sudo apt install -y docker.io
    sudo usermod -aG docker ubuntu

    # Pull image
    docker pull $DOCKER_USER/$IMAGE_NAME:latest

    # Stop previous containers
    docker stop fastapi-api streamlit-frontend 2>/dev/null || true
    docker rm fastapi-api streamlit-frontend 2>/dev/null || true

    # Run containers
    docker run -d -p 8000:8000 --name fastapi-api $DOCKER_USER/$IMAGE_NAME:latest
    docker run -d -p 8501:8501 --name streamlit-frontend $DOCKER_USER/$IMAGE_NAME:latest streamlit run frontend.py --server.port 8501 --server.address 0.0.0.0

    echo "✅ Deployment complete!"
    echo "API: http://$AWS_IP:8000/docs"
    echo "Frontend: http://$AWS_IP:8501"
EOF

echo "✅ Deployment successful!"
echo "API Docs: http://$AWS_IP:8000/docs"
echo "Frontend: http://$AWS_IP:8501"
