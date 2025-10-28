#!/bin/bash

# GitHub Secrets Setup Verification Script
# This script helps you verify that you have all necessary values to configure GitHub Secrets

echo "=================================================="
echo "GitHub Secrets Configuration Verification"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} Found: $1"
        return 0
    else
        echo -e "${RED}✗${NC} Missing: $1"
        return 1
    fi
}

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Command available: $1"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Command not found: $1"
        return 1
    fi
}

echo "Checking required files..."
echo ""

# Check for key files
check_file "oci-keys/*.pem"
check_file "vm-keys/oci_vm_key.pub"
check_file "vm-keys/oci_vm_key"
check_file "terraform.tfvars"

echo ""
echo "Checking required commands..."
echo ""

check_command "terraform"
check_command "ssh"
check_command "docker"

echo ""
echo "=================================================="
echo "Required GitHub Secrets Checklist"
echo "=================================================="
echo ""

echo "OCI Configuration:"
echo "  [ ] OCI_TENANCY_OCID"
echo "  [ ] OCI_USER_OCID"
echo "  [ ] OCI_FINGERPRINT"
echo "  [ ] OCI_PRIVATE_KEY"
echo "  [ ] OCI_REGION"
echo "  [ ] OCI_COMPARTMENT_OCID"
echo "  [ ] OCI_SUBNET_ID"
echo "  [ ] OCI_AVAILABILITY_DOMAIN"
echo "  [ ] OCI_UBUNTU_IMAGE_OCID"
echo ""

echo "SSH Keys:"
echo "  [ ] VM_SSH_PUBLIC_KEY"
echo "  [ ] VM_SSH_PRIVATE_KEY"
echo ""

echo "Docker Hub:"
echo "  [ ] DOCKER_USER"
echo "  [ ] DOCKER_PAT"
echo ""

echo "=================================================="
echo "Quick Commands to Copy Keys"
echo "=================================================="
echo ""

echo "Copy OCI Private Key (macOS):"
echo "  cat oci-keys/*.pem | pbcopy"
echo ""

echo "Copy SSH Public Key (macOS):"
echo "  cat vm-keys/oci_vm_key.pub | pbcopy"
echo ""

echo "Copy SSH Private Key (macOS):"
echo "  cat vm-keys/oci_vm_key | pbcopy"
echo ""

echo "For Linux users, replace 'pbcopy' with 'xclip -selection clipboard'"
echo ""

if [ -f "terraform.tfvars" ]; then
    echo "=================================================="
    echo "Values from terraform.tfvars"
    echo "=================================================="
    echo ""
    echo "You can use these values for your GitHub Secrets:"
    echo ""
    grep -E "^[^#]" terraform.tfvars | while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            key=$(echo "$line" | cut -d'=' -f1 | tr -d ' ')
            value=$(echo "$line" | cut -d'=' -f2- | tr -d ' "')
            echo "  $key = $value"
        fi
    done
    echo ""
fi

echo "=================================================="
echo "Next Steps"
echo "=================================================="
echo ""
echo "1. Go to your GitHub repository"
echo "2. Navigate to: Settings → Secrets and variables → Actions"
echo "3. Click 'New repository secret' for each secret"
echo "4. Copy the values using the commands above"
echo "5. Create a Docker Hub Personal Access Token:"
echo "   https://hub.docker.com/settings/security"
echo ""
echo "Once all secrets are configured, push to main branch to trigger deployment!"
echo ""
