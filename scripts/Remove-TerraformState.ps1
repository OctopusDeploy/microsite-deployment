param(
    [Parameter(Mandatory = $true)]
    [string]$MicrositeStorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$StateStorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$StateSubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$StateContainerName,

    [Parameter(Mandatory = $true)]
    [string]$MicrositePrefix,

    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName
)

$EnvironmentName = $EnvironmentName.ToLower()
$blobPrefix = "microsites/$MicrositePrefix/$EnvironmentName/"

# Step 1: Confirm the microsite storage account has been destroyed
Write-Host "Checking that microsite storage account '$MicrositeStorageAccountName' has been destroyed..."

$storageAccount = az storage account show --name $MicrositeStorageAccountName --output json 2>$null | ConvertFrom-Json

if ($storageAccount) {
    throw "Storage account '$MicrositeStorageAccountName' still exists. Ensure the Terraform destroy step has completed successfully before running this script."
}

Write-Host "Confirmed: storage account '$MicrositeStorageAccountName' no longer exists."

# Step 2: Check for blobs under the environment prefix
Write-Host "Checking for state blobs under prefix '$blobPrefix' in container '$StateContainerName'..."

$blobs = az storage blob list `
    --account-name $StateStorageAccountName `
    --subscription $StateSubscriptionId `
    --container-name $StateContainerName `
    --prefix $blobPrefix `
    --auth-mode login `
    --output json | ConvertFrom-Json

if (-not $blobs -or $blobs.Count -eq 0) {
    Write-Host "No state blobs found under '$blobPrefix'. Nothing to clean up."
    exit 0
}

$blob = $blobs[0]
Write-Host "Found state blob: $($blob.name)"

# Step 3: Delete the state blob
Write-Host "Deleting $($blob.name)..."

az storage blob delete `
    --account-name $StateStorageAccountName `
    --subscription $StateSubscriptionId `
    --container-name $StateContainerName `
    --name $blob.name `
    --auth-mode login

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully deleted state blob for environment '$EnvironmentName'."
} else {
    throw "Failed to delete blob '$($blob.name)'. az storage blob delete exited with code: $LASTEXITCODE"
}
