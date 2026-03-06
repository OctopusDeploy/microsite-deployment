# Verify Azure authentication
$accountInfo = az account show --output json | ConvertFrom-Json
Write-Host "Authenticated to Azure as: $($accountInfo.user.name)"

# Configure AZCopy to use Azure CLI authentication
$env:AZCOPY_AUTO_LOGIN_TYPE = "AZCLI"

# Get package path
$packagePath = $OctopusParameters["Octopus.Action.Package[Microsite_Package].ExtractedPath"]
Write-Host "Package path: $packagePath"

# Set storage account details (use Octopus variables for these)
$storageAccountName = $OctopusParameters["Azure.StorageAccount.Name"]
$containerName = "`$web"  # Escaped $ for PowerShell
$storageUrl = "https://$storageAccountName.blob.core.windows.net/$containerName"

Write-Host "`nSyncing to: $storageUrl"

# Run azcopy sync with Azure authentication
# AZCopy will automatically use the Azure CLI login context
azcopy sync $packagePath $storageUrl --recursive --delete-destination=true --compare-hash=MD5 --put-md5

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Sync completed successfully"
} else {
    Write-Error "AZCopy sync failed with exit code: $LASTEXITCODE"
    exit 1
}