# 🔧 Fixing the OCI Private Key Configuration

## The Problem

GitHub Actions was failing with this error:
```
Error: can not create client, bad configuration: did not find a proper configuration for private key
```

This happens because the OCI private key is a multi-line secret, and it needs to be handled carefully in GitHub Actions.

## ✅ Solution Applied

The workflow has been updated to properly handle multi-line secrets using `printf` instead of `echo`, which preserves newlines correctly.

### What Changed:

**Before:**
```yaml
- name: Create OCI private key file
  run: |
    mkdir -p oci-keys
    echo "${{ secrets.OCI_PRIVATE_KEY }}" > oci-keys/api_key.pem
    chmod 600 oci-keys/api_key.pem
```

**After:**
```yaml
- name: Create OCI private key file
  run: |
    mkdir -p oci-keys
    printf "%s\n" "$OCI_PRIVATE_KEY" > oci-keys/api_key.pem
    chmod 600 oci-keys/api_key.pem
  env:
    OCI_PRIVATE_KEY: ${{ secrets.OCI_PRIVATE_KEY }}
```

## 📋 How to Configure OCI_PRIVATE_KEY Secret

### Step 1: Get Your Private Key Content

```bash
# On macOS
cat oci-keys/qcg3005741@est.univalle.edu-2025-10-14T13_40_00.291Z.pem | pbcopy

# On Linux
cat oci-keys/qcg3005741@est.univalle.edu-2025-10-14T13_40_00.291Z.pem | xclip -selection clipboard

# On Windows (PowerShell)
Get-Content oci-keys\qcg3005741@est.univalle.edu-2025-10-14T13_40_00.291Z.pem | Set-Clipboard
```

### Step 2: Add to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `OCI_PRIVATE_KEY`
5. Value: Paste the **entire content** including:
   - `-----BEGIN PRIVATE KEY-----`
   - All the lines in between
   - `-----END PRIVATE KEY-----`

### Important Notes:

✅ **DO include:**
- The BEGIN line
- All middle lines
- The END line
- All newlines (they should be preserved when you copy)

❌ **DO NOT:**
- Add extra spaces
- Remove any lines
- Modify the key content
- Add quotes around the content

### Example Format (shortened):

```
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...
[many more lines]
...xYZ123
-----END PRIVATE KEY-----
```

## 🧪 Verify the Configuration

After adding the secret and pushing to main:

1. **Check GitHub Actions logs:**
   - Go to Actions tab
   - Click on the latest workflow run
   - Expand "Create OCI private key file"
   - Should show no errors

2. **Terraform Init should succeed:**
   - The "Terraform Init" step should complete successfully
   - No authentication errors

3. **Terraform Plan should work:**
   - Should be able to communicate with OCI

## 🔍 Troubleshooting

### Still Getting Authentication Errors?

**Double-check the fingerprint:**
```bash
# Get the fingerprint of your local key
openssl rsa -pubout -outform DER -in oci-keys/*.pem | openssl md5 -c
```

This should match your `OCI_FINGERPRINT` secret exactly (format: `aa:bb:cc:dd:...`)

### Key Format Issues?

Make sure your private key is in the correct format:
```bash
# Check the key format
head -1 oci-keys/*.pem
# Should output: -----BEGIN PRIVATE KEY-----
# or: -----BEGIN RSA PRIVATE KEY-----
```

### GitHub Secret Not Updating?

If you updated the secret:
1. Delete the old secret completely
2. Create a new one with the correct content
3. Trigger a new workflow run

## ✅ Other Secrets Updated

The workflow was also updated to properly handle:
- `VM_SSH_PRIVATE_KEY` - For SSH connections to the VM
- Multi-line environment variables in the deployment stage

All SSH key handling now uses the same secure `printf` method.

## 🚀 Next Steps

1. **Verify the OCI_PRIVATE_KEY secret is correctly configured** (see Step 2 above)
2. **Ensure all other secrets are configured** (see SECRETS_REFERENCE.md)
3. **Push a new commit to trigger the workflow:**
   ```bash
   git add .
   git commit -m "Fix OCI private key handling"
   git push origin main
   ```
4. **Monitor the workflow** to ensure it completes successfully

## 📚 Additional Resources

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [OCI API Key Documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
- [SECRETS_REFERENCE.md](./SECRETS_REFERENCE.md) - Complete secrets guide

---

**Status**: ✅ Workflow Updated
**Action Required**: Verify OCI_PRIVATE_KEY secret is correctly configured in GitHub
