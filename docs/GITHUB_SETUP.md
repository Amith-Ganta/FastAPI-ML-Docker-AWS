# 🚀 GitHub Actions Auto-Deployment Setup

## Step 1: Create GitHub Repository

1. Go to **https://github.com/new**
2. Enter Repository name: `FastAPI-ML-Docker-AWS`
3. Choose **Public** (easier for learning)
4. Click **"Create repository"**
5. Copy the repo URL

---

## Step 2: Initialize Git & Push Code

In your project folder:

```bash
cd C:\Users\HP\Desktop\Docker\fastapi-demo-api

# Initialize git
git init
git add .
git commit -m "Initial commit: FastAPI ML model with Streamlit"

# Add remote (replace USERNAME with your GitHub username)
git remote add origin https://github.com/Amith-Ganta/FastAPI-ML-Docker-AWS.git

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## Step 3: Add GitHub Secrets

This tells GitHub Actions your Docker & AWS credentials.

1. Go to your repo: **https://github.com/Amith-Ganta/FastAPI-ML-Docker-AWS**
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**

Add these 4 secrets:

| Name | Value |
|------|-------|
| `DOCKER_USERNAME` | `amith98480` |
| `DOCKER_TOKEN` | *(your Docker Hub Personal Access Token)* |
| `AWS_IP` | `44.205.0.187` |
| `AWS_KEY` | *(contents of aws-fast-api.pem file)* |

### How to add AWS_KEY:

1. Open: `C:\Users\HP\Desktop\Docker\fastapi-demo-api\aws-fast-api.pem`
2. Copy entire content (with `-----BEGIN PRIVATE KEY-----` etc)
3. Paste in GitHub secret `AWS_KEY`

---

## Step 4: Update frontend.py API URL

Edit `frontend.py` and change:

```python
API_URL = "http://44.205.0.187:8000/predict"
```

---

## Step 5: Test Auto-Deployment

Make a small change to your code:

```bash
# Edit any file (e.g., add a comment)
git add .
git commit -m "Test auto-deployment"
git push
```

Then:
1. Go to **GitHub repo** → **Actions** tab
2. Watch the workflow run in real-time
3. Wait for ✅ completion

---

## Step 6: Access Your App

Once deployment completes:

- **Backend API Docs:** http://44.205.0.187:8000/docs
- **Streamlit Frontend:** http://44.205.0.187:8501

---

## 🔧 Troubleshooting

### Workflow fails?
1. Check **Actions** tab → click failed run
2. See error message
3. Most common: AWS Security Groups not configured

### Add AWS Security Group Rules:
1. AWS Console → EC2 → Security Groups
2. Add inbound rules:
   - Port 8000 (API)
   - Port 8501 (Frontend)
   - Port 22 (SSH)
3. Source: 0.0.0.0/0

### Can't access URLs?
- Wait 30 seconds after deployment
- Check firewall
- Verify security group rules

---

## 🎉 How It Works

```
You push code → GitHub Actions automatically:
  1. Builds Docker image
  2. Pushes to Docker Hub
  3. Connects to AWS
  4. Deploys containers
  5. Returns URLs

You get your backend updated without doing anything!
```

---

## ⏭️ Next Steps

1. Complete all steps above
2. Make a test commit and push
3. Watch it deploy automatically
4. Access your Streamlit frontend

**That's it! Your deployment is fully automated!** 🚀
