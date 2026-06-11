# Deployment Guide

The API ships as a single, self-contained image on Docker Hub:
**`tweakster24/insurance-premium-api:latest`**. Deploying anywhere is the same
`docker pull && docker run` — there is no environment-specific build step and no
SSH-orchestration to break.

---

## 🐳 Run the published image (any host)

```bash
docker pull tweakster24/insurance-premium-api:latest
docker run -d --name insurance-premium-api -p 8000:8000 \
  --restart unless-stopped tweakster24/insurance-premium-api:latest
```

- API docs: `http://localhost:8000/docs`
- Health probe: `http://localhost:8000/health`

This identical pair of commands works on a laptop, a bare VM, AWS EC2, or any
container platform.

---

## 🧩 Full stack locally (API + Streamlit UI)

```bash
docker compose up --build
```

- API:      http://localhost:8000/docs
- Frontend: http://localhost:8501

---

## ☁️ Deploy on AWS EC2

### 1. Connect to the instance
```bash
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

### 2. Install Docker (first time only)
```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu && newgrp docker
```

### 3. Pull & run the image
```bash
docker pull tweakster24/insurance-premium-api:latest
docker run -d --name insurance-premium-api -p 8000:8000 \
  --restart unless-stopped tweakster24/insurance-premium-api:latest
```

### 4. Open the security group
In AWS → EC2 → Security Groups, add an inbound rule for **port 8000** (and
**8501** if you also run the Streamlit UI).

### 5. Access the service
- API docs: `http://<EC2_PUBLIC_IP>:8000/docs`

> 💡 Tip: attach an **Elastic IP** to the instance so the public address stays
> stable across stop/start cycles.

### Updating a running deployment
```bash
docker pull tweakster24/insurance-premium-api:latest
docker rm -f insurance-premium-api
docker run -d --name insurance-premium-api -p 8000:8000 \
  --restart unless-stopped tweakster24/insurance-premium-api:latest
```

---

## 🔄 How the image gets published

The image is produced by the **CI/CD pipeline** ([`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml)),
not by hand. On every push to `main` the pipeline:

1. Builds the image from `backend/Dockerfile`.
2. Boots the container and smoke-tests `/health` and `/predict` against the real
   HTTP contract.
3. Publishes to Docker Hub **only if** the tests pass.

A broken build never reaches the registry, so a `docker pull` always retrieves a
verified, runnable image.

### Required repository secrets (for the publish step)

| Secret | Purpose |
|--------|---------|
| `DOCKER_USERNAME` | Docker Hub username (`tweakster24`) |
| `DOCKER_TOKEN` | Docker Hub access token |

If these secrets are absent the pipeline still builds and tests the image — it
simply skips the publish step and stays green.
