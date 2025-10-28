# 🔐 GitHub Secrets Quick Reference

## Required Secrets for Deployment

### 📋 OCI Authentication (9 secrets)

```
OCI_TENANCY_OCID          → Your OCI tenancy identifier
OCI_USER_OCID             → Your OCI user identifier  
OCI_FINGERPRINT           → API key fingerprint (format: aa:bb:cc:...)
OCI_PRIVATE_KEY           → Full content of your .pem private key file
OCI_REGION                → e.g., us-ashburn-1, us-phoenix-1
OCI_COMPARTMENT_OCID      → Compartment where VM will be created
OCI_SUBNET_ID             → Subnet OCID for VM networking
OCI_AVAILABILITY_DOMAIN   → e.g., abCD:US-ASHBURN-AD-1
OCI_UBUNTU_IMAGE_OCID     → Ubuntu 22.04 image OCID for your region
```

### 🔑 SSH Keys (2 secrets)

```
VM_SSH_PUBLIC_KEY         → Content of vm-keys/oci_vm_key.pub
VM_SSH_PRIVATE_KEY        → Content of vm-keys/oci_vm_key
```

### 🐳 Docker Hub (2 secrets)

```
DOCKER_USER               → Your Docker Hub username
DOCKER_PAT                → Docker Hub Personal Access Token
```

## 📝 How to Copy Keys to Clipboard

### macOS
```bash
# OCI Private Key
cat oci-keys/*.pem | pbcopy

# SSH Public Key  
cat vm-keys/oci_vm_key.pub | pbcopy

# SSH Private Key
cat vm-keys/oci_vm_key | pbcopy
```

### Linux
```bash
# Replace pbcopy with xclip
cat oci-keys/*.pem | xclip -selection clipboard
cat vm-keys/oci_vm_key.pub | xclip -selection clipboard
cat vm-keys/oci_vm_key | xclip -selection clipboard
```

### Windows (PowerShell)
```powershell
# Replace pbcopy with clip
Get-Content oci-keys\*.pem | Set-Clipboard
Get-Content vm-keys\oci_vm_key.pub | Set-Clipboard
Get-Content vm-keys\oci_vm_key | Set-Clipboard
```

## 🚀 Quick Setup Steps

1. **Run verification script:**
   ```bash
   ./setup-secrets-check.sh
   ```

2. **Go to GitHub:**
   - Your Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"

3. **Add each secret:**
   - Name: Use exact names from list above
   - Value: Paste the copied content
   - Click "Add secret"

4. **Create Docker Hub Token:**
   - Go to https://hub.docker.com/settings/security
   - Click "New Access Token"
   - Description: "GitHub Actions Deployment"
   - Copy token and add as `DOCKER_PAT` secret

5. **Verify all 13 secrets are added:**
   - You should see all secrets listed in GitHub

## ✅ Testing Your Setup

After adding all secrets:

1. **Test locally (optional):**
   ```bash
   terraform init
   terraform plan
   ```

2. **Trigger GitHub Actions:**
   ```bash
   git add .
   git commit -m "Configure deployment"
   git push origin main
   ```

3. **Monitor deployment:**
   - Go to Actions tab in GitHub
   - Watch the workflow progress
   - Check the summary for your VM's public IP

4. **Access your app:**
   ```
   http://YOUR_VM_IP:3000
   ```

## 🔧 Troubleshooting

### Missing Secrets Error
- Double-check all 13 secrets are added
- Verify exact spelling (case-sensitive)
- Ensure no extra spaces in values

### Authentication Failed
- Verify OCI_FINGERPRINT matches your API key
- Check OCI_PRIVATE_KEY includes BEGIN/END lines
- Ensure OCIDs are from the correct region

### SSH Connection Failed  
- Verify SSH keys are a matching pair
- Check VM_SSH_PRIVATE_KEY has proper line breaks
- Ensure no extra characters when copying

## 📚 Additional Resources

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [OCI API Keys](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
- [Docker Hub Tokens](https://docs.docker.com/docker-hub/access-tokens/)

---

**Total Secrets Required: 13**
- ✓ 9 OCI Configuration
- ✓ 2 SSH Keys  
- ✓ 2 Docker Hub

Once configured, deployments are fully automated! 🎉
