# Port 8080 Not Accessible - Security List Fix Required

## The Issue

Your Next.js application is running on the VM on port 8080, but you can't access it from the internet because the **OCI Security List** doesn't have an ingress rule for port 8080.

## ✅ Current Status

- ✅ Docker is installed on VM
- ✅ Application is running on port 8080
- ✅ GitHub Actions workflow is updated to use port 8080
- ❌ OCI Security List blocks external access to port 8080

## 🔧 Solution: Add Ingress Rule in OCI Console

### Step 1: Navigate to Security Lists

1. Go to [OCI Console](https://cloud.oracle.com/)
2. Click on **Menu** ☰ (top left)
3. Select **Networking** → **Virtual Cloud Networks**
4. Click on your VCN (the one containing your subnet)
5. Click on **Security Lists** (left sidebar)
6. Click on the security list associated with your subnet

### Step 2: Add Ingress Rule for Port 8080

1. Click **Add Ingress Rules**
2. Fill in the following:
   - **Source CIDR**: `0.0.0.0/0` (allows access from anywhere)
   - **IP Protocol**: `TCP`
   - **Source Port Range**: Leave empty
   - **Destination Port Range**: `8080`
   - **Description**: `HTTP access for Next.js app`
3. Click **Add Ingress Rules**

### Step 3: Test Access

After adding the rule, wait 10-30 seconds and test:

```bash
curl http://159.112.131.69:8080
```

Or open in your browser:
```
http://159.112.131.69:8080
```

## 🚀 Alternative: Use Port 80 (Recommended for Production)

If you want to use the standard HTTP port (80) instead:

### Option A: Use Nginx Reverse Proxy

SSH into your VM and set up nginx:

```bash
ssh -i vm-keys/oci_vm_key ubuntu@159.112.131.69

# Install nginx
sudo apt update
sudo apt install nginx -y

# Create nginx configuration
sudo tee /etc/nginx/sites-available/nextjs << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the configuration
sudo ln -s /etc/nginx/sites-available/nextjs /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test and restart nginx
sudo nginx -t
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

Then add port 80 to OCI Security List and access at:
```
http://159.112.131.69
```

### Option B: Change Docker Port Mapping to 80

Update docker-compose.yml to map port 80:

```bash
ssh -i vm-keys/oci_vm_key ubuntu@159.112.131.69

# Update docker-compose.yml
cat > ~/docker-compose.yml << 'EOF'
version: '3.8'

services:
  nextjs-app:
    image: gonchi028/univalle-nextjs-docker:latest
    container_name: univalle-nextjs-production
    restart: unless-stopped
    ports:
      - "80:3000"
    environment:
      - NODE_ENV=production
EOF

# Restart container
sudo docker compose down
sudo docker compose up -d
```

Then add port 80 to OCI Security List.

## 📋 Quick Reference: Common Ports

| Port | Use Case | Security List Required |
|------|----------|------------------------|
| 22   | SSH      | ✅ Already configured |
| 80   | HTTP     | ❌ Need to add |
| 443  | HTTPS    | ❌ Need to add (for SSL) |
| 3000 | Next.js (direct) | ❌ Need to add |
| 8080 | Next.js (current) | ❌ Need to add |

## ✅ Recommended Setup for Production

1. **Add port 80 to OCI Security List**
2. **Use nginx as reverse proxy** (Option A above)
3. **Later: Add SSL with Let's Encrypt for HTTPS (port 443)**

## 🔍 Verify Your Setup

After configuring OCI Security List:

```bash
# Test from your local machine
curl http://159.112.131.69:8080

# Or test from the VM (should work already)
ssh -i vm-keys/oci_vm_key ubuntu@159.112.131.69 "curl localhost:8080"
```

## 📝 Summary of What's Needed

**Immediate fix**: Add ingress rule for port 8080 in OCI Security List

**Better production setup**:
1. Install nginx on VM
2. Configure nginx as reverse proxy to port 3000
3. Add port 80 ingress rule in OCI Security List
4. Access app at `http://159.112.131.69` (no port needed)
5. Later: Add SSL certificate for HTTPS

---

**Your app is running! Just needs the firewall opened in OCI Console** 🚀
