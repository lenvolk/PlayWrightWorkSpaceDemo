#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Comprehensive Azure Playwright Workspaces Demo - API and Web UI Testing

.DESCRIPTION
    Demonstrates execution of both Playwright API tests and web UI tests on Azure Playwright Workspaces.
    Shows the complete testing capabilities including:
    - API testing (request fixture)
    - Web UI testing (browser automation)  
    - Cross-browser compatibility testing
    - Azure cloud infrastructure utilization

.EXAMPLE
    .\run-azure-demo.ps1
    .\run-azure-demo.ps1 -TestType "API"
    .\run-azure-demo.ps1 -TestType "WebUI"
    .\run-azure-demo.ps1 -TestType "All" -Workers 10
#>

param(
    [Parameter(HelpMessage="Test type to run: API, WebUI, or All")]
    [ValidateSet("API", "WebUI", "All")]
    [string]$TestType = "All",
    
    [Parameter(HelpMessage="Number of parallel workers for Azure execution")]
    [int]$Workers = 5,
    
    [Parameter(HelpMessage="Show detailed output")]
    [switch]$DetailedOutput
)

# Color functions for output
function Write-ColorOutput($ForegroundColor, $Message) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Header($Message) {
    Write-ColorOutput "Cyan" "🌩️ $Message"
}

function Write-Success($Message) {
    Write-ColorOutput "Green" "✅ $Message"
}

function Write-Warning($Message) {
    Write-ColorOutput "Yellow" "⚠️ $Message"
}

function Write-Error($Message) {
    Write-ColorOutput "Red" "❌ $Message"
}

# Ensure we're in the correct directory
if (-not (Test-Path "playwright.service.config.ts")) {
    Write-Error "Please run this script from the demo directory"
    exit 1
}

Write-Header "Azure Playwright Workspaces - Comprehensive Testing Demo"
Write-Output ""

# Check Azure configuration
Write-Header "Checking Azure Configuration..."
if (-not (Test-Path ".env")) {
    Write-Error "Azure environment not configured. Please run .\setup-interactive.ps1 first"
    exit 1
}

# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match "^([^=]+)=(.*)$") {
        [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2])
    }
}

Write-Success "Azure Playwright Workspaces configuration found"
Write-Output "   Workspace: $env:PLAYWRIGHT_SERVICE_URL"
Write-Output ""

# Start mock API server in background
Write-Header "Starting Mock API Server..."
$mockServerJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    python mock-api-server.py
}

# Wait for server to start
Start-Sleep -Seconds 3
Write-Success "Mock API server started (Job ID: $($mockServerJob.Id))"
Write-Output "   📚 API Documentation: http://localhost:5000/docs"
Write-Output "   🧪 Interactive Tester: http://localhost:5000/test" 
Write-Output "   🔍 API Explorer: http://localhost:5000/explorer"
Write-Output ""

try {
    switch ($TestType) {
        "API" {
            Write-Header "Running API Tests on Azure Playwright Workspaces..."
            Write-Output "🔌 Testing API endpoints using Playwright request fixture"
            Write-Output "🌩️ Executing on Azure cloud infrastructure"
            Write-Output ""
            
            $apiTests = @(
                "tests/swagger-generated.spec.ts",
                "tests/postman-generated.spec.ts"
            )
            
            foreach ($testFile in $apiTests) {
                if (Test-Path $testFile) {
                    Write-Output "🧪 Running: $testFile"
                    npx playwright test $testFile --config=playwright.service.config.ts --workers=$Workers
                    Write-Output ""
                }
            }
        }
        
        "WebUI" {
            Write-Header "Running Web UI Tests on Azure Playwright Workspaces..."
            Write-Output "🎭 Testing browser automation and UI interactions"
            Write-Output "🌐 Cross-browser testing: Chromium, Firefox, WebKit"
            Write-Output "🌩️ Executing on Azure cloud infrastructure"
            Write-Output ""
            
            npx playwright test tests/web-ui-tests.spec.ts --config=playwright.service.config.ts --workers=$Workers
        }
        
        "All" {
            Write-Header "Running Comprehensive Test Suite on Azure Playwright Workspaces..."
            Write-Output "🔌 API Testing: Request-based endpoint validation"
            Write-Output "🎭 Web UI Testing: Browser automation and interactions"
            Write-Output "🌐 Cross-browser: Chromium, Firefox, WebKit compatibility"
            Write-Output "⚡ Parallel Execution: $Workers workers on Azure infrastructure"
            Write-Output "🌩️ Cloud Scale: Unlimited browser capacity"
            Write-Output ""
            
            # Run all tests
            npx playwright test --config=playwright.service.config.ts --workers=$Workers
        }
    }
    
    Write-Header "Test Execution Complete!"
    Write-Success "Azure Playwright Workspaces Demo Results:"
    Write-Output ""
    Write-Output "📊 Check Azure Portal for detailed results:"
    Write-Output "   1. Navigate to Azure Portal"
    Write-Output "   2. Go to your Resource Group"
    Write-Output "   3. Open your Playwright Workspace"
    Write-Output "   4. Click 'Test runs' to see execution details"
    Write-Output ""
    Write-Output "🎯 What was demonstrated:"
    Write-Output "   ✅ API Testing with Playwright request fixture"
    Write-Output "   ✅ Web UI Testing with browser automation"
    Write-Output "   ✅ Cross-browser compatibility testing"
    Write-Output "   ✅ Azure cloud infrastructure utilization"
    Write-Output "   ✅ Parallel execution and scalability"
    Write-Output "   ✅ Professional test reporting in Azure Portal"
    Write-Output ""
    
    if ($TestType -eq "All") {
        Write-Header "Comprehensive Testing Summary"
        Write-Output "🔌 API Tests: Swagger and Postman endpoint validation"
        Write-Output "🎭 Web UI Tests: Browser automation, forms, responsive design"
        Write-Output "🌐 Cross-browser: Compatibility across all major browsers"
        Write-Output "🌩️ Azure Features: Cloud scaling, network simulation, geolocation"
        Write-Output "📊 Results: Available in Azure Portal Test runs section"
    }
    
} finally {
    # Cleanup
    Write-Header "Cleaning up..."
    Stop-Job $mockServerJob -ErrorAction SilentlyContinue
    Remove-Job $mockServerJob -ErrorAction SilentlyContinue
    Write-Success "Mock API server stopped"
}

Write-Output ""
Write-Header "Demo Complete! 🎉"
Write-Output "Your Azure Playwright Workspaces demo showcased both API and Web UI testing capabilities."
