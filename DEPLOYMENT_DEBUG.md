# GitHub Actions Deployment Issue - Handoff to Opus

## Problem Summary
GitHub Actions workflow fails at "Deploy to AWS" step with SSH authentication error: `Permission denied (publickey)`. All previous steps (Docker build, push to Docker Hub) succeed. Only AWS deployment fails.

## What We're Trying To Do
Automatically deploy FastAPI + Streamlit containers to AWS EC2 instance (44.205.0.187) via GitHub Actions CI/CD.

## Current Setup
- **Repository:** https://github.com/Amith-Ganta/FastAPI-ML-Docker-AWS
- **AWS Instance:** 44.205.0.187 (Ubuntu, t3.micro)
- **Key File:** aws-fast-api.pem (RSA private key, valid and working)
- **GitHub Secrets:** DOCKER_USERNAME, DOCKER_TOKEN, AWS_IP, AWS_KEY (base64 encoded)
- **Security Groups:** Ports 8000, 8501, 22 all open (0.0.0.0/0)

## Error Details
```
Line 55: Pseudo-terminal will not be allocated because stdin is not a terminal.
Line 56: ubuntu@44.205.0.187: Permission denied (publickey).
Line 57: Error: Process completed with exit code 255.
```

## What's Been Tried (All Failed Same Way)
1. ✗ Direct echo to file: `echo "${{ secrets.AWS_KEY }}" > ~/.ssh/aws-key.pem`
2. ✗ Printf with %b: `printf '%b' "${{ secrets.AWS_KEY }}" > ~/.ssh/aws-key.pem`
3. ✗ Here-document: `cat > ~/.ssh/aws-key.pem << 'EOF'...'EOF'`
4. ✗ Base64 decode (-d): `echo "${{ secrets.AWS_KEY }}" | base64 -d > ~/.ssh/aws-key.pem`
5. ✗ Base64 decode (--decode): `echo "${{ secrets.AWS_KEY }}" | base64 --decode > ~/.ssh/aws-key.pem`

## What's NOT The Issue (Verified)
- ✅ AWS_KEY secret is stored correctly in GitHub (user confirmed)
- ✅ Private key file is valid RSA format (-----BEGIN RSA PRIVATE KEY-----)
- ✅ SSH key works (manual SSH from local machine works fine: `ssh -i aws-fast-api.pem ubuntu@44.205.0.187`)
- ✅ AWS Security Groups allow port 22 from 0.0.0.0/0
- ✅ Docker Hub login succeeds (DOCKER_TOKEN verified working)
- ✅ Base64 encoding is valid (Python-encoded correctly)

## Current Workflow File
Located at: `.github/workflows/deploy.yml`

Key section:
```bash
mkdir -p ~/.ssh
echo "${{ secrets.AWS_KEY }}" | base64 --decode > ~/.ssh/aws-key.pem
chmod 600 ~/.ssh/aws-key.pem
cat ~/.ssh/aws-key.pem | head -1
ssh-keyscan -H ${{ secrets.AWS_IP }} >> ~/.ssh/known_hosts 2>/dev/null || true

ssh -i ~/.ssh/aws-key.pem ubuntu@${{ secrets.AWS_IP }} << 'EOF'
# deployment commands
EOF
```

## Hypothesis/Debugging Needed
The SSH connection fails despite the key being valid, which suggests:
1. The key file is being written with wrong format/encoding (likely)
2. The secret is not being interpolated correctly in GitHub Actions
3. There's an issue with how the multiline base64 is being handled
4. SSH is trying to use a different auth method before the key

## Questions for Opus
1. Is there a better way to store/pass multiline secrets in GitHub Actions?
2. Should we try a completely different approach (e.g., SSH with password, GitHub deployment keys, AWS Systems Manager Session Manager)?
3. Can we add debug output to see what's actually in the ~/.ssh/aws-key.pem file?
4. Is the issue with echo/pipe/base64 in GitHub Actions runner environment?

## Files to Check
- `.github/workflows/deploy.yml` - The workflow file
- `aws-fast-api.pem` - The actual private key (valid, tested locally)
- GitHub repo secrets: AWS_KEY, AWS_IP, DOCKER_USERNAME, DOCKER_TOKEN

## Previous Successful Deployments
None yet - this is the first attempt. Manual SSH to instance works perfectly.
