# Simple test script
Write-Host "Testing PowerShell script execution..." -ForegroundColor Green

# Test Azure CLI
Write-Host "Checking Azure CLI..." -ForegroundColor Cyan
$azVersion = az version 2>$null
if ($azVersion) {
    Write-Host "✅ Azure CLI is available" -ForegroundColor Green
} else {
    Write-Host "❌ Azure CLI not found" -ForegroundColor Red
}

# Test basic commands
Write-Host "Testing basic Azure commands..." -ForegroundColor Cyan
$currentAccount = az account show --query name -o tsv 2>$null
if ($currentAccount) {
    Write-Host "✅ Logged in as: $currentAccount" -ForegroundColor Green
} else {
    Write-Host "⚠️  Not logged in to Azure" -ForegroundColor Yellow
}

Write-Host "✅ Script completed successfully!" -ForegroundColor Green
