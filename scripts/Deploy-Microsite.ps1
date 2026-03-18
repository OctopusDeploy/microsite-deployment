param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$PackagePath
)

# Verify Azure authentication
$accountInfo = az account show --output json | ConvertFrom-Json
Write-Host "Authenticated to Azure as: $($accountInfo.user.name)"

# Configure AZCopy to use Azure CLI authentication
$env:AZCOPY_AUTO_LOGIN_TYPE = "AZCLI"

Write-Host "Package path: $PackagePath"

$containerName = "`$web"
$storageUrl = "https://$StorageAccountName.blob.core.windows.net/$containerName"

Write-Host "`nSyncing to: $storageUrl"

# Run azcopy sync with Azure authentication
# AZCopy will automatically use the Azure CLI login context
azcopy sync $PackagePath $storageUrl --recursive --delete-destination=true --compare-hash=MD5 --put-md5

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Sync completed successfully"
} else {
    Write-Error "AZCopy sync failed with exit code: $LASTEXITCODE"
    exit 1
}