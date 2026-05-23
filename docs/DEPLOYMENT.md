# Deployment Guide

## 📦 Files Added

- `requirements.txt` - Python dependencies
- `Dockerfile` - API container
- `Dockerfile.streamlit` - Frontend container
- `docker-compose.yml` - Run both together
- `.dockerignore` - Exclude files from build
- `deploy-aws.sh` - Automated AWS deployment script

## 🐳 Local Testing

### Option 1: Docker Compose (API + Frontend)
```bash
docker-compose up
```
- API: http://localhost:8000/docs
- Frontend: http://localhost:8501

### Option 2: Individual Docker Containers
```bash
# Build API
docker build -t fastapi-demo-api .

# Build Frontend
docker build -f Dockerfile.streamlit -t streamlit-demo .

# Run API
docker run -p 8000:8000 fastapi-demo-api

# Run Frontend (in another terminal)
docker run -p 8501:8501 streamlit-demo
```

## ☁️ Deploy to AWS

### Step 1: Build & Push to Docker Hub
```bash
docker build -t YOUR_USERNAME/fastapi-demo-api .
docker login
docker push YOUR_USERNAME/fastapi-demo-api
```

### Step 2: Connect to AWS EC2
Get your instance IP from AWS console, then:
```bash
ssh -i your-key.pem ubuntu@YOUR_AWS_IP
```

### Step 3: Run on AWS
```bash
# Install Docker
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker ubuntu

# Pull and run
docker pull YOUR_USERNAME/fastapi-demo-api
docker run -d -p 8000:8000 --name api YOUR_USERNAME/fastapi-demo-api
docker run -d -p 8501:8501 --name frontend YOUR_USERNAME/fastapi-demo-api streamlit run frontend.py --server.port 8501 --server.address 0.0.0.0
```

### Step 4: Open Security Groups
- Go to AWS → EC2 → Security Groups
- Add inbound rules for ports 8000 (API) and 8501 (Frontend)

### Access Your App
- API Docs: http://YOUR_AWS_IP:8000/docs
- Frontend: http://YOUR_AWS_IP:8501

## 🚀 Quick Deploy Script
```bash
chmod +x deploy-aws.sh
./deploy-aws.sh YOUR_AWS_IP /path/to/key.pem YOUR_DOCKER_USER YOUR_DOCKER_PASSWORD
```

Done! Your app is live on AWS.
