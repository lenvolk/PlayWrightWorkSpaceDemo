# Simple syntax test
Write-Host "Testing basic PowerShell syntax..."

# Test Azure CLI command
$subscriptions = az account list --query '[].{Name:name, Id:id}' -o json | ConvertFrom-Json
Write-Host "Subscriptions count: $($subscriptions.Count)"

# Test string concatenation
$envContent = "AZURE_SUBSCRIPTION_ID=test"
$envContent += "`nAZURE_RESOURCE_GROUP=test"
Write-Host "Environment content:`n$envContent"

Write-Host "Syntax test completed successfully!"
