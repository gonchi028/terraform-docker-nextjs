# Oracle Cloud + Next.js Automated Deployment

This project automates the deployment of a Next.js application to Oracle Cloud Infrastructure (OCI) using Terraform and GitHub Actions.

## 🚀 Features

- **Automated Infrastructure Provisioning**: Terraform creates and manages OCI VM instances
- **Continuous Deployment**: GitHub Actions automatically deploy your Next.js app on push to main
- **Docker-based Deployment**: Containerized application for consistency and reliability
- **Zero-downtime Updates**: Rolling updates with Docker Compose

## 📋 Prerequisites

Before you begin, ensure you have:

1. **OCI Account** with proper permissions
2. **GitHub Account** with repository access
3. **Docker Hub Account** for storing container images
4. **OCI Configuration**:
   - Tenancy OCID
   - User OCID
   - API Key Pair (Private & Public)
   - Compartment OCID
   - Subnet ID
   - Availability Domain
   - Ubuntu 22.04 Image OCID
5. **SSH Key Pair** for VM access

## 🔧 Setup Instructions

### Step 1: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

#### OCI Configuration Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `OCI_TENANCY_OCID` | Your OCI tenancy OCID | `ocid1.tenancy.oc1..aaa...` |
| `OCI_USER_OCID` | Your OCI user OCID | `ocid1.user.oc1..aaa...` |
| `OCI_FINGERPRINT` | API key fingerprint | `aa:bb:cc:dd:ee:...` |
| `OCI_PRIVATE_KEY` | Full content of OCI private key .pem file | Copy entire file |
| `OCI_REGION` | OCI region | `us-ashburn-1` |
| `OCI_COMPARTMENT_OCID` | Compartment OCID | `ocid1.compartment.oc1..aaa...` |
| `OCI_SUBNET_ID` | Subnet OCID | `ocid1.subnet.oc1..aaa...` |
| `OCI_AVAILABILITY_DOMAIN` | Availability domain | `abCD:US-ASHBURN-AD-1` |
| `OCI_UBUNTU_IMAGE_OCID` | Ubuntu 22.04 image OCID for your region | `ocid1.image.oc1..aaa...` |

#### SSH Keys for VM Access

| Secret Name | Description |
|-------------|-------------|
| `VM_SSH_PUBLIC_KEY` | Public SSH key content (from `vm-keys/oci_vm_key.pub`) |
| `VM_SSH_PRIVATE_KEY` | Private SSH key content (from `vm-keys/oci_vm_key`) |

#### Docker Hub Credentials

| Secret Name | Description |
|-------------|-------------|
| `DOCKER_USER` | Your Docker Hub username |
| `DOCKER_PAT` | Docker Hub Personal Access Token |

### Step 2: How to Copy Key Files to Secrets

**For OCI Private Key:**
```bash
cat oci-keys/your-key.pem | pbcopy  # macOS
cat oci-keys/your-key.pem | xclip -selection clipboard  # Linux
```

**For SSH Keys:**
```bash
# Public key
cat vm-keys/oci_vm_key.pub | pbcopy

# Private key
cat vm-keys/oci_vm_key | pbcopy
```

### Step 3: Configure OCI Security List

Ensure your subnet's security list allows:
- **Port 22** (SSH) - for deployment
- **Port 3000** (HTTP) - for Next.js application

Add ingress rule in OCI Console:
1. Navigate to: Networking → Virtual Cloud Networks → Your VCN → Security Lists
2. Add Ingress Rule:
   - Source CIDR: `0.0.0.0/0`
   - Destination Port Range: `3000`
   - IP Protocol: `TCP`

### Step 4: Create Docker Hub Token

1. Go to [Docker Hub](https://hub.docker.com/)
2. Account Settings → Security → New Access Token
3. Copy the token and add it as `DOCKER_PAT` secret in GitHub

## 🎯 How It Works

### Workflow Triggers

The GitHub Actions workflow triggers automatically on:
- Push to `main` branch
- Manual trigger via GitHub Actions UI

### Deployment Process

1. **Infrastructure Phase**:
   - Terraform checks if VM exists
   - Creates new VM or updates existing one
   - Installs Docker via cloud-init
   - Outputs public IP address

2. **Application Phase**:
   - Builds Docker image for Next.js app
   - Pushes image to Docker Hub
   - SSHs into VM
   - Pulls latest image
   - Updates running container with zero downtime
   - Performs health check

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml              # Main deployment workflow
├── univalle-nextjs-docker/         # Next.js application
│   ├── Dockerfile                  # Production-optimized container
│   ├── next.config.ts              # Next.js configuration
│   └── src/                        # Application source code
├── main.tf                         # Terraform VM configuration
├── provider.tf                     # OCI provider setup
├── variables.tf                    # Terraform variables
├── cloud_init.sh                   # VM initialization script
└── README.md                       # This file
```

## 🚀 Deploying Your Application

### First Deployment

1. Configure all GitHub Secrets (see Step 1 above)
2. Push your code to the `main` branch:
   ```bash
   git add .
   git commit -m "Initial deployment setup"
   git push origin main
   ```
3. Go to GitHub Actions tab and watch the workflow run
4. Once complete, access your app at: `http://YOUR_VM_IP:3000`

### Subsequent Deployments

Simply push changes to `main`:
```bash
git add .
git commit -m "Update application"
git push origin main
```

The workflow will:
- ✅ Check if infrastructure needs updates
- ✅ Build and push new Docker image
- ✅ Deploy to VM with zero downtime
- ✅ Run health checks

### Manual Deployment

You can also trigger deployment manually:
1. Go to Actions tab in GitHub
2. Select "Deploy Infrastructure and Next.js App"
3. Click "Run workflow" → "Run workflow"

## 🔍 Monitoring and Debugging

### View Workflow Logs

1. Go to GitHub Actions tab
2. Click on the latest workflow run
3. Expand steps to see detailed logs

### SSH into VM

```bash
ssh -i vm-keys/oci_vm_key ubuntu@YOUR_VM_IP
```

### View Application Logs

```bash
# SSH into VM first
sudo docker logs univalle-nextjs-production

# Follow logs in real-time
sudo docker logs -f univalle-nextjs-production
```

### Check Container Status

```bash
sudo docker ps
sudo docker stats
```

### Restart Application

```bash
sudo docker compose restart
```

## 🛠️ Troubleshooting

### Workflow Fails at Terraform Step

**Issue**: Authentication errors
- Verify all OCI secrets are correctly copied
- Check that `OCI_FINGERPRINT` matches your API key
- Ensure private key includes BEGIN/END lines

**Issue**: Resource not found
- Verify OCIDs are correct and in the right region
- Check compartment permissions

### Workflow Fails at Deployment Step

**Issue**: SSH connection fails
- Verify `VM_SSH_PRIVATE_KEY` and `VM_SSH_PUBLIC_KEY` are a matching pair
- Check OCI Security List allows port 22
- Wait longer - VM may still be initializing

**Issue**: Docker commands fail
- SSH into VM and check: `sudo systemctl status docker`
- Restart Docker: `sudo systemctl restart docker`

### Application Not Accessible

**Issue**: Cannot reach http://VM_IP:3000
- Check OCI Security List has ingress rule for port 3000
- Verify container is running: `sudo docker ps`
- Check logs: `sudo docker logs univalle-nextjs-production`
- Test locally on VM: `curl localhost:3000`

### Health Check Fails

This is usually not critical. The app may still be working. Check:
```bash
ssh ubuntu@YOUR_VM_IP
curl localhost:3000
```

## 🎨 Customization

### Change Application Port

1. Update `main.tf` to open different port in security rules
2. Update port mapping in workflow's docker-compose section
3. Update health check URL in workflow

### Add Environment Variables

Edit the docker-compose section in `.github/workflows/deploy.yml`:
```yaml
environment:
  - NODE_ENV=production
  - DATABASE_URL=${{ secrets.DATABASE_URL }}
  - API_KEY=${{ secrets.API_KEY }}
```

Then add these secrets to GitHub.

### Change VM Configuration

Edit `main.tf`:
```terraform
shape_config {
  ocpus         = 2      # Change CPU count
  memory_in_gbs = 16     # Change memory
}
```

## 📚 Additional Resources

- [OCI Documentation](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues or questions:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review GitHub Actions logs
3. Open an issue in the repository

---

**Made with ❤️ for automated cloud deployments**
