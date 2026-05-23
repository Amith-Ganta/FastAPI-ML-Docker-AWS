# System Architecture

## Overview

The Insurance Premium Predictor is a containerized full-stack application with automated CI/CD deployment to cloud infrastructure. The system follows a service-oriented architecture with clear separation between frontend, backend, and infrastructure layers.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  (Code, Workflows, Secrets Management)                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ [Push to main]
                     │
┌────────────────────▼────────────────────────────────────────┐
│              GitHub Actions CI/CD Pipeline                   │
│  (Build, Test, Push to Docker Hub, Deploy to AWS)           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ [Deploy via SSH]
                     │
┌────────────────────▼────────────────────────────────────────┐
│            AWS EC2 Instance (Ubuntu)                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Docker & Docker Compose                       │  │
│  │  ┌─────────────────┐    ┌──────────────────────┐    │  │
│  │  │  FastAPI        │    │  Streamlit Frontend  │    │  │
│  │  │  (Port 8000)    │◄──►│  (Port 8501)         │    │  │
│  │  │                 │    │                      │    │  │
│  │  │ - app.py        │    │ - frontend.py        │    │  │
│  │  │ - model.pkl     │    │ - Real-time UI       │    │  │
│  │  │ - REST API      │    │ - User Input         │    │  │
│  │  └─────────────────┘    └──────────────────────┘    │  │
│  │          │                                           │  │
│  │          │ [HTTP]                                    │  │
│  │          ▼                                           │  │
│  │       ┌──────────┐                                   │  │
│  │       │ ML Model │                                   │  │
│  │       │(Trained) │                                   │  │
│  │       └──────────┘                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Public IP: 44.205.0.187                                   │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              External Services                               │
│  ┌──────────────┐          ┌───────────────┐               │
│  │ Docker Hub   │          │ GitHub API    │               │
│  │ (Image Repo) │          │ (Secrets,     │               │
│  │              │          │  Workflows)   │               │
│  └──────────────┘          └───────────────┘               │
└──────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Frontend Layer (Streamlit)

**Location:** `frontend/`

**Responsibilities:**
- User-friendly web interface
- Form input collection and validation
- Real-time prediction results display
- API communication handling

**Technology:**
- Streamlit 1.43.0 for rapid UI development
- Requests library for HTTP calls
- Python 3.11

**Environment:**
- Port: 8501
- Container: streamlit-frontend

### 2. Backend Layer (FastAPI)

**Location:** `backend/`

**Responsibilities:**
- REST API for predictions
- Input validation using Pydantic models
- Machine learning model inference
- Feature computation (BMI, age groups, city tiers)

**Technology:**
- FastAPI 0.115.12 for high-performance async APIs
- Uvicorn 0.34.2 as ASGI server
- Pydantic 2.11.4 for data validation
- Scikit-learn 1.6.1 for ML model
- Pandas 2.2.3 for data processing
- Python 3.11

**API Endpoints:**
- `GET /docs` - Interactive Swagger documentation
- `GET /openapi.json` - OpenAPI specification
- `POST /predict` - Insurance category prediction

**Environment:**
- Port: 8000
- Container: fastapi-api

### 3. ML Model

**Type:** Classification model (Scikit-learn)

**Location:** `backend/model.pkl`

**Features Used:**
- BMI (calculated from height/weight)
- Age group (derived from age)
- Lifestyle risk (derived from smoker status and BMI)
- City tier (derived from city name)
- Income (LPA)
- Occupation

**Output:** Insurance premium category (discrete classification)

### 4. Data Layer

**Location:** `data/`

**Files:**
- `insurance.csv` - Training dataset
- `patients.json` - Sample patient data

### 5. Infrastructure Layer

**Containerization:**
- Docker containers for API and Frontend
- Docker Compose for multi-container orchestration
- `.dockerignore` for build optimization

**Deployment:**
- GitHub Actions for CI/CD automation
- AWS EC2 (t3.micro) for hosting
- SSH-based deployment via webfactory/ssh-agent
- Docker Hub as image registry

## Data Flow

### 1. Prediction Request Flow

```
User Input (Frontend)
         │
         ▼
   [Streamlit UI]
         │
         ├─ Validate input
         │
         ▼
  [HTTP POST to API]
         │
         ├─ /predict endpoint
         │
         ▼
 [Pydantic Validation]
         │
         ├─ Compute derived features
         │  - BMI = weight / height²
         │  - Age group classification
         │  - Lifestyle risk assessment
         │  - City tier mapping
         │
         ▼
   [ML Model Inference]
         │
         ├─ Load model.pkl
         │
         ├─ Prepare feature vector
         │
         ├─ model.predict()
         │
         ▼
  [JSON Response]
         │
         ▼
  [Display on Frontend]
```

### 2. Deployment Flow

```
Developer Push to GitHub (main branch)
         │
         ▼
GitHub Actions Triggered
         │
         ├─ [Build] Docker images
         │  - Backend image from backend/
         │  - Frontend image from frontend/
         │
         ├─ [Push] to Docker Hub
         │
         ├─ [Deploy] SSH to EC2
         │
         ├─ [Pull] latest images
         │
         ├─ [Restart] containers via docker-compose
         │
         ▼
Live on http://<AWS_IP>:8000 and :8501
```

## Security Considerations

### 1. Secrets Management

- GitHub Secrets store sensitive data:
  - `DOCKER_USERNAME`, `DOCKER_TOKEN` - Docker Hub authentication
  - `AWS_IP`, `AWS_KEY` - EC2 connection details
  - `GITHUB_TOKEN` - API access

- Secrets never logged or exposed in CI/CD logs
- SSH key management via `webfactory/ssh-agent@v0.9.0`

### 2. Network Security

- EC2 security groups control inbound/outbound traffic
- API runs on private container network
- Public ports: 8000 (API), 8501 (Frontend)

### 3. Input Validation

- Pydantic models enforce strict type checking
- Field constraints (ranges, valid values)
- Automatic API documentation prevents misuse

## Scaling Considerations

### Current Limitations

- Single EC2 instance (t3.micro)
- No load balancing
- No auto-scaling
- No database (stateless predictions)

### Future Improvements

- Kubernetes cluster for multi-container orchestration
- Load balancer (ELB/ALB) for traffic distribution
- Auto-scaling groups for dynamic capacity
- Cache layer (Redis) for frequently predicted categories
- Database for audit/analytics
- CDN for static assets

## Development Workflow

```
Feature Branch
     │
     ├─ Local development with docker-compose
     │
     ├─ Test with http://localhost:8000/docs
     │
     ├─ Push to feature branch
     │
     ▼
Pull Request
     │
     ├─ Code review
     │
     ├─ CI checks (if configured)
     │
     ▼
Merge to main
     │
     ├─ Automatic GitHub Actions deployment
     │
     ├─ Containers updated on EC2
     │
     ▼
Live deployment
```

## Technology Decisions

| Decision | Rationale |
|----------|-----------|
| FastAPI | High performance, async support, auto OpenAPI docs |
| Streamlit | Rapid UI development, good for data apps, minimal code |
| Docker Compose | Local dev matches production, easy setup |
| GitHub Actions | Integrated with repository, free tier sufficient |
| Scikit-learn | Lightweight, good for tabular data classification |
| Pydantic | Strong type validation, OpenAPI integration |

## Monitoring & Logging

**Current:** Manual log inspection via `docker logs`

**Future Considerations:**
- CloudWatch for EC2 metrics
- ELK stack for centralized logging
- Prometheus + Grafana for monitoring
- Error tracking (Sentry)
- Performance monitoring (New Relic, DataDog)
