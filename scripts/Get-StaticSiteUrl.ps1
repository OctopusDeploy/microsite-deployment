param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName
)

# Query Azure for the static website endpoint
$url = az storage account show --name $storageAccountName --query "primaryEndpoints.web" --output tsv

if (-not $url) {
    throw "Could not retrieve static website URL for storage account: $storageAccountName"
}

# Trim any trailing slash for consistency
$url = $url.TrimEnd('/')

Write-Host "Static website URL: $url"

# Set as an output variable for use in subsequent steps
Set-OctopusVariable -name "StaticWebsiteUrl" -value $url