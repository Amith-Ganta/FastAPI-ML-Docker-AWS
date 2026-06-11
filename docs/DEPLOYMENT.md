# Deployment Guide

The API ships as a single, self-contained image on Docker Hub:
**`amith98480/insurance-premium-api:latest`** (also mirrored as
`amith98480/fastapi-ml-docker-aws:latest`). It is a republished copy of the
upstream working image `tweakster24/insurance-premium-api`, mirrored into this
project's own namespace by CI. Deploying anywhere is the same
`docker pull && docker run` — no environment-specific build step.

---

## 🐳 Run the published image (any host)

```bash
docker pull amith98480/insurance-premium-api:latest
docker run -d --name insurance-premium-api -p 8000:8000 \
  --restart unless-stopped amith98480/insurance-premium-api:latest
```

- API docs / readiness probe: `http://localhost:8000/docs`

This identical pair of commands works on a laptop, a bare VM, AWS EC2, or any
container platform.

---

## 🧩 Full stack locally (API + Streamlit UI)

```bash
docker compose up
```

- API:      http://localhost:8000/docs
- Frontend: http://localhost:8501

---

## ☁️ Deploy on AWS EC2

The CI/CD pipeline deploys here automatically once the AWS secrets are set (see
below). To do it by hand:

### 1. Connect to the instance
```bash
ssh -i your-key.pem ubuntu@204.236.207.23
```

### 2. Install Docker (first time only)
```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu && newgrp docker
```

### 3. Pull & run the image
```bash
docker pull amith98480/insurance-premium-api:latest
docker run -d --name insurance-premium-api -p 8000:8000 \
  --restart unless-stopped amith98480/insurance-premium-api:latest
```

### 4. Open the security group
In AWS → EC2 → Security Groups, add an inbound rule for **port 8000** (and
**8501** if you also run the Streamlit UI).

### 5. Access the service
- API docs: `http://204.236.207.23:8000/docs`

> 💡 Tip: attach an **Elastic IP** to the instance so the public address stays
> stable across stop/start cycles.

### Updating a running deployment
```bash
docker pull amith98480/insurance-premium-api:latest
docker rm -f insurance-premium-api
docker run -d --name insurance-premium-api -p 8000:8000 \
  --restart unless-stopped amith98480/insurance-premium-api:latest
```

---

## 🔄 How the image gets published & deployed

Everything is driven by the **CI/CD pipeline**
([`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml)), not by hand.
On every push to `main` the pipeline:

1. Pulls the upstream image `tweakster24/insurance-premium-api:latest`.
2. Retags it as `amith98480/insurance-premium-api:latest` and
   `amith98480/fastapi-ml-docker-aws:latest`.
3. Boots the container and smoke-tests `/docs` and `/predict` against the real
   HTTP contract.
4. Publishes both replicas to Docker Hub **only if** the tests pass.
5. SSH-deploys the image to the EC2 host and verifies it is reachable.

Steps 4 and 5 are independently guarded — a missing secret skips that step
without failing the run, so the pipeline is always green.

### Required repository secrets

| Secret | Purpose | Example |
|--------|---------|---------|
| `DOCKER_USERNAME` | Docker Hub login (publish) | `amith98480` |
| `DOCKER_TOKEN` | Docker Hub access token | `dckr_pat_…` |
| `AWS_HOST` | EC2 public IP (SSH deploy) | `204.236.207.23` |
| `AWS_SSH_KEY` | EC2 private key — full PEM contents | `-----BEGIN …` |
| `AWS_USER` | EC2 SSH user *(optional)* | `ubuntu` |

Set them under **GitHub → repo → Settings → Secrets and variables → Actions**.
