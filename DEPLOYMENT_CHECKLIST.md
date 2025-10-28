# 📋 Deployment Checklist

Use this checklist to ensure everything is configured correctly before deploying.

## Pre-Deployment Checklist

### 1. Local Files ✓
- [x] OCI private key exists: `oci-keys/*.pem`
- [x] SSH public key exists: `vm-keys/oci_vm_key.pub`
- [x] SSH private key exists: `vm-keys/oci_vm_key`
- [x] Terraform variables exist: `terraform.tfvars`
- [x] GitHub workflow exists: `.github/workflows/deploy.yml`
- [x] Dockerfile configured: `univalle-nextjs-docker/Dockerfile`
- [x] Next.js config updated: `univalle-nextjs-docker/next.config.ts`

### 2. GitHub Repository Setup
- [ ] Repository is pushed to GitHub
- [ ] You have admin access to the repository
- [ ] Main branch is protected (optional but recommended)

### 3. GitHub Secrets Configuration (13 total)

#### OCI Configuration (9 secrets)
- [ ] `OCI_TENANCY_OCID` - Added to GitHub Secrets
- [ ] `OCI_USER_OCID` - Added to GitHub Secrets
- [ ] `OCI_FINGERPRINT` - Added to GitHub Secrets
- [ ] `OCI_PRIVATE_KEY` - Copied from .pem file and added
- [ ] `OCI_REGION` - Set to `sa-santiago-1`
- [ ] `OCI_COMPARTMENT_OCID` - Added to GitHub Secrets
- [ ] `OCI_SUBNET_ID` - Added to GitHub Secrets
- [ ] `OCI_AVAILABILITY_DOMAIN` - Set to `CTPA:SA-SANTIAGO-1-AD-1`
- [ ] `OCI_UBUNTU_IMAGE_OCID` - Added to GitHub Secrets

#### SSH Keys (2 secrets)
- [ ] `VM_SSH_PUBLIC_KEY` - Copied from `vm-keys/oci_vm_key.pub`
- [ ] `VM_SSH_PRIVATE_KEY` - Copied from `vm-keys/oci_vm_key`

#### Docker Hub (2 secrets)
- [ ] `DOCKER_USER` - Your Docker Hub username
- [ ] `DOCKER_PAT` - Personal Access Token from Docker Hub

### 4. Docker Hub Setup
- [ ] Docker Hub account created
- [ ] Personal Access Token generated
- [ ] Token added to GitHub Secrets

### 5. OCI Network Configuration
- [ ] VCN (Virtual Cloud Network) is configured
- [ ] Subnet is available in correct availability domain
- [ ] Security List configured with required ingress rules:
  - [ ] Port 22 (SSH) - `0.0.0.0/0` or your IP
  - [ ] Port 3000 (Next.js) - `0.0.0.0/0`

### 6. OCI Permissions
- [ ] User has permission to create compute instances
- [ ] User has permission to manage VCN resources
- [ ] API key is properly configured
- [ ] Fingerprint matches API key

### 7. Local Testing (Optional)
- [ ] Run `./setup-secrets-check.sh` - All checks pass
- [ ] `terraform init` - Successful
- [ ] `terraform validate` - No errors
- [ ] Next.js app builds locally - `cd univalle-nextjs-docker && npm run build`

## Deployment Steps

### First-Time Deployment

1. **Verify All Secrets**
   ```bash
   # Run verification script
   ./setup-secrets-check.sh
   ```
   - [ ] Script shows all required files
   - [ ] All values are available

2. **Push to GitHub**
   ```bash
   git checkout main
   git pull origin main
   git add .
   git commit -m "Initial deployment configuration"
   git push origin main
   ```
   - [ ] Code pushed successfully
   - [ ] GitHub Actions workflow triggered

3. **Monitor Workflow**
   - [ ] Go to GitHub Actions tab
   - [ ] Watch "Deploy Infrastructure and Next.js App" workflow
   - [ ] Terraform stage completes (3-5 min)
   - [ ] Deployment stage completes (2-4 min)

4. **Get VM IP Address**
   - [ ] Check workflow summary for public IP
   - [ ] Note down IP: `_________________`

5. **Test Application**
   - [ ] Open browser: `http://VM_IP:3000`
   - [ ] Application loads successfully
   - [ ] No console errors

### Verification After Deployment

1. **Check VM Status**
   ```bash
   ssh -i vm-keys/oci_vm_key ubuntu@YOUR_VM_IP
   ```
   - [ ] SSH connection successful

2. **Check Docker**
   ```bash
   sudo docker ps
   ```
   - [ ] Container `univalle-nextjs-production` is running
   - [ ] Status shows "Up X minutes"

3. **Check Application Logs**
   ```bash
   sudo docker logs univalle-nextjs-production
   ```
   - [ ] No critical errors
   - [ ] Server started on port 3000

4. **Test Application Locally on VM**
   ```bash
   curl localhost:3000
   ```
   - [ ] Returns HTML content

5. **Test from Internet**
   ```bash
   curl http://YOUR_VM_IP:3000
   ```
   - [ ] Returns HTML content
   - [ ] Application accessible from outside

## Post-Deployment

### Documentation
- [ ] Update README.md with actual VM IP
- [ ] Document any environment variables added
- [ ] Update team on deployment URL

### Monitoring
- [ ] Bookmark application URL
- [ ] Bookmark GitHub Actions page
- [ ] Set up uptime monitoring (optional)

### Security
- [ ] Verify sensitive files not in git: `git status`
- [ ] Confirm `.gitignore` is working
- [ ] Review OCI security rules are appropriate

## Troubleshooting Checklist

If deployment fails, check:

### Terraform Stage Fails
- [ ] All OCI secrets are correctly copied
- [ ] No extra spaces in secret values
- [ ] OCI_FINGERPRINT format is correct (aa:bb:cc:...)
- [ ] OCI_PRIVATE_KEY includes BEGIN/END lines
- [ ] OCIDs are from correct region
- [ ] Compartment and subnet exist
- [ ] User has proper permissions

### Deployment Stage Fails
- [ ] Docker Hub secrets are correct
- [ ] DOCKER_USER is your username (not email)
- [ ] DOCKER_PAT is a valid token
- [ ] VM is accessible via SSH
- [ ] VM_SSH_PRIVATE_KEY and VM_SSH_PUBLIC_KEY match
- [ ] Docker is running on VM

### Application Not Accessible
- [ ] OCI Security List has port 3000 ingress rule
- [ ] Container is running: `sudo docker ps`
- [ ] No port conflicts on VM
- [ ] Application started without errors in logs

### SSH Connection Fails
- [ ] Security List allows port 22
- [ ] SSH keys are a valid pair
- [ ] VM is in running state
- [ ] Correct username (ubuntu)
- [ ] VM finished initialization (wait 2-3 minutes)

## Quick Commands Reference

```bash
# Verify setup
./setup-secrets-check.sh

# Copy OCI private key (macOS)
cat oci-keys/*.pem | pbcopy

# Copy SSH public key (macOS)
cat vm-keys/oci_vm_key.pub | pbcopy

# Copy SSH private key (macOS)
cat vm-keys/oci_vm_key | pbcopy

# SSH into VM
ssh -i vm-keys/oci_vm_key ubuntu@YOUR_VM_IP

# Check Docker on VM
sudo docker ps
sudo docker logs univalle-nextjs-production

# Restart application
sudo docker compose restart

# View GitHub Actions
open "https://github.com/YOUR_USERNAME/YOUR_REPO/actions"
```

## Success Criteria ✓

Deployment is successful when ALL of these are true:

- [x] GitHub Actions workflow completed without errors
- [x] Workflow summary displays VM public IP
- [x] Application accessible at `http://VM_IP:3000`
- [x] Next.js page loads in browser
- [x] No critical errors in application logs
- [x] Container shows "Up" status in `docker ps`
- [x] Health check passed (or application responding to curl)

## Next Steps After Successful Deployment

1. **Set up custom domain** (optional)
   - Point DNS to VM IP
   - Configure nginx reverse proxy
   - Set up SSL with Let's Encrypt

2. **Configure monitoring**
   - Set up uptime monitoring
   - Configure log aggregation
   - Set up alerts

3. **Plan for updates**
   - Subsequent updates are automatic on push to main
   - Test changes in a separate branch first
   - Monitor GitHub Actions after each push

4. **Backup strategy**
   - Export Terraform state
   - Backup application data if any
   - Document recovery procedures

---

**Date Started**: _________________
**Date Completed**: _________________
**VM Public IP**: _________________
**Application URL**: http://_________________:3000

**Deployed By**: _________________
**Status**: [ ] In Progress  [ ] Complete  [ ] Issues Found

**Notes**:
_________________________________________________________
_________________________________________________________
_________________________________________________________
