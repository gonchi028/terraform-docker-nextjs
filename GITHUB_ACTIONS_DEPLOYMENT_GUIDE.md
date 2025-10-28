# GitHub Actions Deployment Guide
## Oracle Cloud VM + Next.js Project Deployment

This guide provides step-by-step instructions to deploy an Oracle Cloud Infrastructure (OCI) VM using Terraform and deploy a Next.js application to it using GitHub Actions.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Structure](#project-structure)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Terraform Workflow Setup](#terraform-workflow-setup)
5. [Next.js Deployment Workflow Setup](#nextjs-deployment-workflow-setup)
6. [Complete Workflow Examples](#complete-workflow-examples)
7. [Deployment Process](#deployment-process)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

### 1. Oracle Cloud Infrastructure (OCI) Setup
- ✅ OCI account with proper permissions
- ✅ Tenancy OCID, User OCID, and Compartment OCID
- ✅ API key pair for OCI authentication (in `oci-keys/` folder)
- ✅ Subnet ID and Availability Domain
- ✅ Ubuntu 22.04 Image OCID for your region

### 2. SSH Keys for VM Access
- ✅ SSH key pair for VM access (in `vm-keys/` folder)
- ✅ Public key (`oci_vm_key.pub`) and private key (`oci_vm_key`)

### 3. GitHub Repository
- ✅ GitHub repository with your Terraform configuration
- ✅ Next.js project in the same or separate repository
- ✅ Admin access to configure GitHub Secrets and Actions

### 4. Local Tools (for testing)
- Terraform >= 1.0
- Git
- SSH client

---

## Project Structure

Your current Terraform structure:
```
.
├── main.tf                 # Main Terraform configuration
├── provider.tf             # OCI provider configuration
├── variables.tf            # Variable definitions
├── terraform.tfvars        # Variable values (DO NOT commit to GitHub)
├── cloud_init.sh           # VM initialization script (installs Docker)
├── oci-keys/               # OCI API keys (DO NOT commit to GitHub)
│   └── *.pem
└── vm-keys/                # SSH keys for VM access (DO NOT commit to GitHub)
    ├── oci_vm_key
    └── oci_vm_key.pub
```

**Recommended Next.js project structure:**
```
.
├── .github/
│   └── workflows/
│       ├── 1-terraform-deploy.yml
│       └── 2-nextjs-deploy.yml
├── terraform/              # Your Terraform files
│   ├── main.tf
│   ├── provider.tf
│   └── ...
├── nextjs-app/             # Your Next.js application
│   ├── package.json
│   ├── next.config.js
│   └── ...
└── deployment/
    └── docker-compose.yml  # Optional: for containerized deployment
```

---

## GitHub Secrets Configuration

### Step 1: Navigate to GitHub Secrets
1. Go to your GitHub repository
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### Step 2: Add OCI Credentials

Add the following secrets one by one:

| Secret Name | Description | Example/Source |
|-------------|-------------|----------------|
| `OCI_TENANCY_OCID` | Your OCI tenancy OCID | `ocid1.tenancy.oc1..aaa...` |
| `OCI_USER_OCID` | Your OCI user OCID | `ocid1.user.oc1..aaa...` |
| `OCI_FINGERPRINT` | API key fingerprint | `aa:bb:cc:dd:ee:...` |
| `OCI_PRIVATE_KEY` | OCI API private key content | Copy entire `.pem` file content |
| `OCI_REGION` | OCI region | `us-ashburn-1` or your region |
| `OCI_COMPARTMENT_OCID` | Compartment OCID | `ocid1.compartment.oc1..aaa...` |
| `OCI_SUBNET_ID` | Subnet OCID | `ocid1.subnet.oc1..aaa...` |
| `OCI_AVAILABILITY_DOMAIN` | Availability domain | `abCD:US-ASHBURN-AD-1` |
| `OCI_UBUNTU_IMAGE_OCID` | Ubuntu 22.04 image OCID | `ocid1.image.oc1..aaa...` |

### Step 3: Add SSH Keys for VM Access

| Secret Name | Description | Source |
|-------------|-------------|--------|
| `VM_SSH_PUBLIC_KEY` | Public SSH key for VM | Content of `vm-keys/oci_vm_key.pub` |
| `VM_SSH_PRIVATE_KEY` | Private SSH key for VM | Content of `vm-keys/oci_vm_key` |

### Step 4: Add GitHub Token (Optional)
If your workflows need to interact with GitHub API:

| Secret Name | Description |
|-------------|-------------|
| `GH_PAT` | GitHub Personal Access Token with repo permissions |

### How to Copy File Contents to Secrets

**For OCI Private Key:**
```bash
# Copy the OCI private key content
cat oci-keys/qcg3005741@est.univalle.edu-2025-10-14T13_40_00.291Z.pem | pbcopy
# Then paste into GitHub Secret
```

**For SSH Keys:**
```bash
# Public key
cat vm-keys/oci_vm_key.pub | pbcopy

# Private key
cat vm-keys/oci_vm_key | pbcopy
```

---

## Terraform Workflow Setup

### Step 1: Create `.github/workflows` Directory

In your repository root:
```bash
mkdir -p .github/workflows
```

### Step 2: Create Terraform Deployment Workflow

Create file: `.github/workflows/1-terraform-deploy.yml`

This workflow will:
- ✅ Initialize Terraform
- ✅ Plan infrastructure changes
- ✅ Apply changes to create/update OCI VM
- ✅ Output the public IP address

See the [Complete Workflow Examples](#complete-workflow-examples) section below for the full workflow file.

### Step 3: Protect Sensitive Files

Create/update `.gitignore` to prevent committing secrets:
```gitignore
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
.terraform.lock.hcl

# OCI Keys
oci-keys/
*.pem

# SSH Keys
vm-keys/
*_key
*_key.pub
*.pub

# Environment files
.env
.env.local

# Node.js
node_modules/
.next/
out/
build/
```

---

## Next.js Deployment Workflow Setup

### Option A: Direct Deployment (PM2)

This approach:
1. Builds the Next.js app
2. SSHs into the VM
3. Deploys using PM2 process manager

### Option B: Docker Deployment (Recommended)

This approach:
1. Builds Docker image
2. Pushes to container registry (Docker Hub/OCIR)
3. Pulls and runs on VM using Docker Compose

### Step 1: Prepare Next.js Application

Ensure your Next.js app has:
- `package.json` with proper scripts
- `.env.example` for environment variables
- Production-ready configuration

**Add deployment scripts to `package.json`:**
```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "export": "next export",
    "deploy": "pm2 restart ecosystem.config.js --env production"
  }
}
```

### Step 2: Create Dockerfile for Next.js

Create `Dockerfile` in your Next.js project root:
```dockerfile
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

**Update `next.config.js`:**
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  // Add other configurations as needed
}

module.exports = nextConfig
```

### Step 3: Create Docker Compose Configuration

Create `docker-compose.yml`:
```yaml
version: '3.8'

services:
  nextjs-app:
    image: your-dockerhub-username/nextjs-app:latest
    container_name: nextjs-production
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      # Add your environment variables here
      # - DATABASE_URL=${DATABASE_URL}
      # - API_KEY=${API_KEY}
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

### Step 4: Create Next.js Deployment Workflow

Create file: `.github/workflows/2-nextjs-deploy.yml`

See the [Complete Workflow Examples](#complete-workflow-examples) section below.

---

## Complete Workflow Examples

### Workflow 1: Terraform Infrastructure Deployment

File: `.github/workflows/1-terraform-deploy.yml`

```yaml
name: 1. Deploy OCI VM with Terraform

on:
  push:
    branches:
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/1-terraform-deploy.yml'
  workflow_dispatch:

jobs:
  terraform:
    name: 'Terraform Deploy'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./terraform
    
    outputs:
      vm_public_ip: ${{ steps.terraform_output.outputs.public_ip }}

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0
        terraform_wrapper: false

    - name: Create OCI private key file
      run: |
        mkdir -p oci-keys
        echo "${{ secrets.OCI_PRIVATE_KEY }}" > oci-keys/api_key.pem
        chmod 600 oci-keys/api_key.pem

    - name: Create SSH public key file
      run: |
        mkdir -p vm-keys
        echo "${{ secrets.VM_SSH_PUBLIC_KEY }}" > vm-keys/oci_vm_key.pub

    - name: Create terraform.tfvars
      run: |
        cat > terraform.tfvars << EOF
        tenancy_ocid = "${{ secrets.OCI_TENANCY_OCID }}"
        user_ocid = "${{ secrets.OCI_USER_OCID }}"
        fingerprint = "${{ secrets.OCI_FINGERPRINT }}"
        private_key_path = "oci-keys/api_key.pem"
        region = "${{ secrets.OCI_REGION }}"
        compartment_ocid = "${{ secrets.OCI_COMPARTMENT_OCID }}"
        subnet_id = "${{ secrets.OCI_SUBNET_ID }}"
        availability_domain = "${{ secrets.OCI_AVAILABILITY_DOMAIN }}"
        ubuntu_2204_image_ocid = "${{ secrets.OCI_UBUNTU_IMAGE_OCID }}"
        ssh_public_key = "${{ secrets.VM_SSH_PUBLIC_KEY }}"
        EOF

    - name: Terraform Init
      run: terraform init

    - name: Terraform Validate
      run: terraform validate

    - name: Terraform Plan
      run: terraform plan -out=tfplan

    - name: Terraform Apply
      run: terraform apply -auto-approve tfplan

    - name: Get Public IP
      id: terraform_output
      run: |
        PUBLIC_IP=$(terraform output -raw public_ip)
        echo "public_ip=$PUBLIC_IP" >> $GITHUB_OUTPUT
        echo "✅ VM Public IP: $PUBLIC_IP"

    - name: Wait for VM to be ready
      run: |
        echo "Waiting 60 seconds for VM initialization..."
        sleep 60

    - name: Test SSH Connection
      run: |
        mkdir -p ~/.ssh
        echo "${{ secrets.VM_SSH_PRIVATE_KEY }}" > ~/.ssh/oci_vm_key
        chmod 600 ~/.ssh/oci_vm_key
        
        # Add to known_hosts
        ssh-keyscan -H ${{ steps.terraform_output.outputs.public_ip }} >> ~/.ssh/known_hosts
        
        # Test connection (may need multiple attempts)
        for i in {1..5}; do
          if ssh -i ~/.ssh/oci_vm_key -o StrictHostKeyChecking=no ubuntu@${{ steps.terraform_output.outputs.public_ip }} "echo 'SSH Connection successful'"; then
            echo "✅ SSH connection established"
            break
          fi
          echo "Attempt $i failed, retrying in 30 seconds..."
          sleep 30
        done

    - name: Upload Terraform State
      uses: actions/upload-artifact@v4
      with:
        name: terraform-state
        path: terraform/terraform.tfstate
        retention-days: 30

    - name: Summary
      run: |
        echo "## Terraform Deployment Summary 🚀" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "✅ VM successfully created and configured" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Public IP:** \`${{ steps.terraform_output.outputs.public_ip }}\`" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Next Steps:**" >> $GITHUB_STEP_SUMMARY
        echo "1. Update your DNS records (if needed)" >> $GITHUB_STEP_SUMMARY
        echo "2. Run the Next.js deployment workflow" >> $GITHUB_STEP_SUMMARY
        echo "3. Access your application at: http://${{ steps.terraform_output.outputs.public_ip }}:3000" >> $GITHUB_STEP_SUMMARY
```

### Workflow 2: Next.js Application Deployment (Docker Method)

File: `.github/workflows/2-nextjs-deploy.yml`

```yaml
name: 2. Deploy Next.js to OCI VM

on:
  push:
    branches:
      - main
    paths:
      - 'nextjs-app/**'
      - '.github/workflows/2-nextjs-deploy.yml'
  workflow_dispatch:
    inputs:
      vm_ip:
        description: 'VM Public IP (optional - will use from terraform state if empty)'
        required: false
        type: string

jobs:
  build-and-deploy:
    name: 'Build and Deploy Next.js'
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Get VM IP from Terraform state
      id: get_ip
      run: |
        if [ -n "${{ github.event.inputs.vm_ip }}" ]; then
          echo "vm_ip=${{ github.event.inputs.vm_ip }}" >> $GITHUB_OUTPUT
        else
          # Download latest terraform state artifact
          # Note: This requires the terraform workflow to have run first
          # Alternatively, you can store the IP in a separate file or use Terraform Cloud
          echo "vm_ip=REPLACE_WITH_YOUR_VM_IP" >> $GITHUB_OUTPUT
        fi
        echo "Using VM IP: $(cat $GITHUB_OUTPUT | grep vm_ip | cut -d'=' -f2)"

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: ./nextjs-app
        push: true
        tags: |
          ${{ secrets.DOCKERHUB_USERNAME }}/nextjs-app:latest
          ${{ secrets.DOCKERHUB_USERNAME }}/nextjs-app:${{ github.sha }}
        cache-from: type=registry,ref=${{ secrets.DOCKERHUB_USERNAME }}/nextjs-app:buildcache
        cache-to: type=registry,ref=${{ secrets.DOCKERHUB_USERNAME }}/nextjs-app:buildcache,mode=max

    - name: Deploy to VM
      env:
        VM_IP: ${{ steps.get_ip.outputs.vm_ip }}
      run: |
        # Setup SSH
        mkdir -p ~/.ssh
        echo "${{ secrets.VM_SSH_PRIVATE_KEY }}" > ~/.ssh/oci_vm_key
        chmod 600 ~/.ssh/oci_vm_key
        ssh-keyscan -H $VM_IP >> ~/.ssh/known_hosts

        # Copy docker-compose file
        scp -i ~/.ssh/oci_vm_key docker-compose.yml ubuntu@$VM_IP:~/

        # Deploy on VM
        ssh -i ~/.ssh/oci_vm_key ubuntu@$VM_IP << 'ENDSSH'
          # Pull latest image
          docker pull ${{ secrets.DOCKERHUB_USERNAME }}/nextjs-app:latest
          
          # Stop and remove old container
          docker-compose down || true
          
          # Start new container
          docker-compose up -d
          
          # Clean up old images
          docker image prune -af
          
          # Show running containers
          docker ps
          
          echo "✅ Deployment completed successfully!"
ENDSSH

    - name: Health Check
      run: |
        VM_IP=${{ steps.get_ip.outputs.vm_ip }}
        echo "Waiting for application to start..."
        sleep 15
        
        # Check if app is responding
        for i in {1..5}; do
          if curl -f http://$VM_IP:3000 > /dev/null 2>&1; then
            echo "✅ Application is running!"
            exit 0
          fi
          echo "Attempt $i failed, retrying in 10 seconds..."
          sleep 10
        done
        
        echo "⚠️ Application health check failed, but deployment completed"

    - name: Summary
      run: |
        VM_IP=${{ steps.get_ip.outputs.vm_ip }}
        echo "## Next.js Deployment Summary 🚀" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "✅ Application successfully deployed!" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Application URL:** http://$VM_IP:3000" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Docker Image:** \`${{ secrets.DOCKERHUB_USERNAME }}/nextjs-app:latest\`" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Commit SHA:** \`${{ github.sha }}\`" >> $GITHUB_STEP_SUMMARY
```

### Alternative Workflow 2B: Next.js Deployment (Direct/PM2 Method)

File: `.github/workflows/2-nextjs-deploy-pm2.yml`

```yaml
name: 2B. Deploy Next.js with PM2

on:
  push:
    branches:
      - main
    paths:
      - 'nextjs-app/**'
  workflow_dispatch:

jobs:
  deploy:
    name: 'Deploy to VM with PM2'
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: nextjs-app/package-lock.json

    - name: Install dependencies
      working-directory: ./nextjs-app
      run: npm ci

    - name: Build application
      working-directory: ./nextjs-app
      run: npm run build

    - name: Deploy to VM
      env:
        VM_IP: ${{ secrets.VM_PUBLIC_IP }}  # Add this as a secret
      run: |
        # Setup SSH
        mkdir -p ~/.ssh
        echo "${{ secrets.VM_SSH_PRIVATE_KEY }}" > ~/.ssh/oci_vm_key
        chmod 600 ~/.ssh/oci_vm_key
        ssh-keyscan -H $VM_IP >> ~/.ssh/known_hosts

        # Create deployment directory on VM
        ssh -i ~/.ssh/oci_vm_key ubuntu@$VM_IP "mkdir -p ~/nextjs-app"

        # Sync files (excluding node_modules)
        rsync -avz -e "ssh -i ~/.ssh/oci_vm_key" \
          --exclude 'node_modules' \
          --exclude '.git' \
          ./nextjs-app/ ubuntu@$VM_IP:~/nextjs-app/

        # Install and start with PM2
        ssh -i ~/.ssh/oci_vm_key ubuntu@$VM_IP << 'ENDSSH'
          cd ~/nextjs-app
          
          # Install Node.js if not present
          if ! command -v node &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
          fi
          
          # Install PM2 globally if not present
          if ! command -v pm2 &> /dev/null; then
            sudo npm install -g pm2
          fi
          
          # Install production dependencies
          npm ci --production
          
          # Stop and delete old process
          pm2 delete nextjs-app || true
          
          # Start application with PM2
          pm2 start npm --name "nextjs-app" -- start
          
          # Save PM2 configuration
          pm2 save
          
          # Setup PM2 to start on system boot
          sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
          
          echo "✅ Deployment completed!"
          pm2 status
ENDSSH

    - name: Summary
      run: |
        echo "## PM2 Deployment Summary 🚀" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "✅ Application deployed with PM2" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Application URL:** http://\${{ secrets.VM_PUBLIC_IP }}:3000" >> $GITHUB_STEP_SUMMARY
```

---

## Deployment Process

### Initial Setup

1. **Clone your repository locally**
   ```bash
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
   ```

2. **Configure GitHub Secrets**
   - Follow the [GitHub Secrets Configuration](#github-secrets-configuration) section
   - Add all required secrets to your repository

3. **Create workflow files**
   ```bash
   mkdir -p .github/workflows
   # Copy the workflow files from this guide
   ```

4. **Update `.gitignore`**
   ```bash
   # Ensure sensitive files are ignored
   echo "terraform.tfvars" >> .gitignore
   echo "*.pem" >> .gitignore
   echo "oci-keys/" >> .gitignore
   echo "vm-keys/" >> .gitignore
   ```

5. **Commit and push workflows**
   ```bash
   git add .github/workflows/
   git add .gitignore
   git commit -m "Add GitHub Actions workflows for OCI deployment"
   git push origin main
   ```

### First Deployment

1. **Deploy Infrastructure**
   - Go to GitHub Actions tab
   - Select "1. Deploy OCI VM with Terraform" workflow
   - Click "Run workflow"
   - Wait for completion (3-5 minutes)
   - Note the Public IP from the workflow summary

2. **Configure Security Rules** (If needed)
   - Go to OCI Console → Networking → Virtual Cloud Networks
   - Select your VCN → Security Lists
   - Add ingress rule for port 3000:
     - Source CIDR: `0.0.0.0/0`
     - Destination Port: `3000`
     - Protocol: TCP

3. **Add VM IP as Secret** (For Option A)
   - Go to GitHub → Settings → Secrets
   - Add `VM_PUBLIC_IP` with the IP from step 1

4. **Deploy Next.js Application**
   - Select "2. Deploy Next.js to OCI VM" workflow
   - Click "Run workflow"
   - Wait for completion (2-5 minutes)
   - Access your app at: `http://YOUR_VM_IP:3000`

### Subsequent Deployments

**Automatic deployment** happens on push to main:
- Changes to `terraform/**` → Triggers infrastructure workflow
- Changes to `nextjs-app/**` → Triggers deployment workflow

**Manual deployment:**
- Go to Actions tab
- Select desired workflow
- Click "Run workflow" → "Run workflow"

---

## Additional Configurations

### Environment Variables for Next.js

If your Next.js app needs environment variables:

1. **Add secrets to GitHub:**
   ```
   DATABASE_URL
   API_KEY
   NEXT_PUBLIC_API_URL
   ```

2. **Update docker-compose.yml:**
   ```yaml
   environment:
     - DATABASE_URL=${{ secrets.DATABASE_URL }}
     - API_KEY=${{ secrets.API_KEY }}
   ```

3. **Or create `.env.production` on VM:**
   ```bash
   ssh ubuntu@VM_IP
   cd ~/nextjs-app
   nano .env.production
   # Add your variables
   ```

### Setting up Nginx Reverse Proxy (Optional)

To serve your app on port 80 with a domain:

```bash
# SSH into your VM
ssh -i vm-keys/oci_vm_key ubuntu@YOUR_VM_IP

# Install Nginx
sudo apt update
sudo apt install nginx -y

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/nextjs

# Add this configuration:
server {
    listen 80;
    server_name your-domain.com;  # or use _ for IP access

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Enable the site
sudo ln -s /etc/nginx/sites-available/nextjs /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Allow HTTP in firewall
sudo ufw allow 'Nginx Full'
```

### SSL Certificate with Let's Encrypt (Optional)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is set up automatically
```

### Monitoring and Logs

**View Docker logs:**
```bash
ssh ubuntu@YOUR_VM_IP
docker logs nextjs-production
docker logs -f nextjs-production  # Follow logs
```

**View PM2 logs:**
```bash
ssh ubuntu@YOUR_VM_IP
pm2 logs nextjs-app
```

**Monitor resources:**
```bash
# On VM
docker stats
# or
pm2 monit
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Terraform Apply Fails

**Error:** "Service error:NotAuthenticated"
- **Solution:** Check OCI credentials in GitHub Secrets
- Verify `OCI_FINGERPRINT` matches your API key
- Ensure private key format is correct (include BEGIN/END lines)

**Error:** "Subnet not found"
- **Solution:** Verify `OCI_SUBNET_ID` is correct and in the right compartment

#### 2. SSH Connection Fails

**Error:** "Permission denied (publickey)"
- **Solution:** 
  - Verify `VM_SSH_PUBLIC_KEY` and `VM_SSH_PRIVATE_KEY` are a matching pair
  - Check private key permissions (should be 600)
  - Ensure you're using the correct username (`ubuntu`)

**Error:** "Connection timed out"
- **Solution:**
  - Check OCI Security List allows ingress on port 22
  - Verify VM is running: `terraform show`
  - Wait longer - VM may still be initializing

#### 3. Docker Deployment Issues

**Error:** "Cannot connect to Docker daemon"
- **Solution:**
  - SSH to VM: `ssh ubuntu@VM_IP`
  - Check Docker: `sudo systemctl status docker`
  - Start Docker: `sudo systemctl start docker`
  - Add user to docker group: `sudo usermod -aG docker ubuntu`
  - Re-login or run: `newgrp docker`

**Error:** "Image pull failed"
- **Solution:**
  - Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets
  - Check image name in docker-compose.yml
  - Manually test: `docker pull your-username/nextjs-app:latest`

#### 4. Application Not Accessible

**Port 3000 not responding:**
- Check OCI Security List:
  - Go to OCI Console → VCN → Security Lists
  - Add ingress rule for port 3000
- Check container status: `docker ps`
- Check logs: `docker logs nextjs-production`
- Test locally on VM: `curl localhost:3000`

**Application errors:**
- Check logs: `docker logs nextjs-production`
- Verify environment variables are set correctly
- Check if Next.js build was successful

#### 5. Workflow Fails

**"terraform.tfstate: no such file"**
- **Solution:** First run will create state file
- For subsequent runs, consider using Terraform Cloud or S3 backend

**"Resource already exists"**
- **Solution:** 
  - Delete resource manually in OCI Console
  - Or import existing resource: `terraform import`
  - Or run `terraform destroy` first

#### 6. GitHub Actions Debugging

**Enable debug logging:**
1. Go to Settings → Secrets
2. Add secret: `ACTIONS_STEP_DEBUG` = `true`
3. Re-run workflow

**Check workflow logs:**
- Click on failed job → Expand failed step
- Look for error messages and stack traces

### Manual Testing Commands

**Test OCI connectivity:**
```bash
# Install OCI CLI locally
brew install oci-cli  # macOS
# or download from OCI website

# Configure
oci setup config

# Test
oci iam region list
```

**Test SSH to VM:**
```bash
ssh -i vm-keys/oci_vm_key ubuntu@YOUR_VM_IP

# Once connected, test Docker:
docker --version
docker ps
docker run hello-world
```

**Test Next.js build locally:**
```bash
cd nextjs-app
npm install
npm run build
npm start

# Test in browser: http://localhost:3000
```

**Test Docker image locally:**
```bash
cd nextjs-app
docker build -t nextjs-test .
docker run -p 3000:3000 nextjs-test

# Test in browser: http://localhost:3000
```

---

## Best Practices

### Security

1. **Never commit secrets** to version control
2. **Rotate keys** regularly (OCI API keys, SSH keys)
3. **Use least privilege** IAM policies in OCI
4. **Enable firewall** on VM: `sudo ufw enable`
5. **Keep software updated:** Regular security patches
6. **Use HTTPS** with SSL certificates in production

### Performance

1. **Use Docker multi-stage builds** to minimize image size
2. **Enable Next.js optimization:** Static generation, image optimization
3. **Configure proper caching** headers
4. **Monitor resource usage** and scale VM if needed
5. **Use CDN** for static assets

### Maintenance

1. **Set up monitoring** (Uptime Robot, Pingdom, or OCI Monitoring)
2. **Configure alerts** for downtime or errors
3. **Regular backups** of application data
4. **Document changes** in commit messages
5. **Tag releases** for easy rollbacks

### Cost Optimization

1. **Use Oracle Cloud Free Tier** when possible
2. **Stop/start VM** if not needed 24/7
3. **Monitor usage** in OCI billing dashboard
4. **Clean up old Docker images** regularly
5. **Use appropriate VM shape** for your workload

---

## Advanced Topics

### Using Terraform Backend (Recommended for Teams)

Store Terraform state remotely to enable collaboration:

**Option 1: Terraform Cloud**
```hcl
# In provider.tf
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "oci-nextjs"
    }
  }
}
```

**Option 2: S3-compatible Storage**
```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "oci-vm/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Blue-Green Deployment

For zero-downtime deployments:
1. Create new VM with Terraform workspace
2. Deploy application to new VM
3. Update load balancer to point to new VM
4. Destroy old VM

### Auto-scaling

For traffic spikes:
1. Create VM image with your application
2. Use OCI Instance Pools
3. Configure autoscaling policies
4. Add load balancer

### CI/CD Pipeline Enhancements

- Add testing stage before deployment
- Implement staging environment
- Add approval gates for production
- Set up rollback mechanisms
- Integrate Slack/Discord notifications

---

## Resources

### Documentation
- [Oracle Cloud Infrastructure Docs](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Next.js Deployment Docs](https://nextjs.org/docs/deployment)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)

### Useful Links
- [OCI Always Free Services](https://www.oracle.com/cloud/free/)
- [Next.js Examples](https://github.com/vercel/next.js/tree/canary/examples)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)

### Support
- GitHub Issues: Create an issue in your repository
- OCI Support: [support.oracle.com](https://support.oracle.com)
- Community: Stack Overflow, Reddit r/oraclecloud

---

## Conclusion

You now have a complete CI/CD pipeline that:
- ✅ Provisions infrastructure on Oracle Cloud with Terraform
- ✅ Deploys Next.js applications automatically
- ✅ Uses GitHub Actions for automation
- ✅ Includes monitoring and troubleshooting guides

**Next Steps:**
1. Configure all GitHub Secrets
2. Create workflow files
3. Push to GitHub and watch the magic happen! 🚀

**Questions or Issues?**
- Check the [Troubleshooting](#troubleshooting) section
- Review workflow logs in GitHub Actions
- Test components individually before full deployment

Good luck with your deployment! 🎉
