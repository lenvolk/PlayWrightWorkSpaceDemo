#!/usr/bin/env pwsh
# 🎭 Interactive Enhanced Swagger and Postman Conversion Demo Setup
# This script dynamically configures the demo based on user's Azure environment

param(
    [switch]$SkipAzureLogin,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

$ErrorActionPreference = "Stop"

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    
    $ConsoleColor = switch ($Color) {
        "Header"  { "Cyan" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Info"    { "Blue" }
        "Prompt"  { "Magenta" }
        default   { "White" }
    }
    
    Write-Host $Text -ForegroundColor $ConsoleColor
}

function Show-Header {
    Clear-Host
    Write-ColorText "🚀 Enhanced Swagger and Postman Conversion Demo Setup" "Header"
    Write-ColorText "=" * 60 "Header"
    Write-ColorText "This interactive setup will configure your demo environment" "Info"
    Write-ColorText "based on your existing Azure resources and preferences.`n" "Info"
}

function Test-AzureConnection {
    try {
        $account = az account show --query "user.name" -o tsv 2>$null
        if ($account) {
            Write-ColorText "✅ Already authenticated as: $account" "Success"
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

function Get-AzureSubscriptions {
    Write-ColorText "🔍 Retrieving available Azure subscriptions..." "Info"
    try {
        $subscriptions = az account list --query '[].{Name:name, Id:id, IsDefault:isDefault}' -o json | ConvertFrom-Json
        return $subscriptions
    }
    catch {
        Write-ColorText "❌ Failed to retrieve subscriptions. Please check your Azure CLI installation." "Error"
        throw
    }
}

function Select-AzureSubscription {
    param([array]$Subscriptions)
    
    Write-ColorText "`n📋 Available Azure Subscriptions:" "Prompt"
    for ($i = 0; $i -lt $Subscriptions.Length; $i++) {
        $default = if ($Subscriptions[$i].IsDefault) { " (Current)" } else { "" }
        Write-Host "  $($i + 1). $($Subscriptions[$i].Name)$default" -ForegroundColor White
        Write-Host "      ID: $($Subscriptions[$i].Id)" -ForegroundColor Gray
    }
    
    do {
        $selection = Read-Host "`nSelect subscription number (1-$($Subscriptions.Length))"
        $index = [int]$selection - 1
    } while ($index -lt 0 -or $index -ge $Subscriptions.Length)
    
    $selectedSub = $Subscriptions[$index]
    Write-ColorText "✅ Selected: $($selectedSub.Name)" "Success"
    
    # Set as active subscription
    az account set --subscription $selectedSub.Id
    return $selectedSub
}

function Get-ResourceGroups {
    param([string]$SubscriptionId)
    
    Write-ColorText "🔍 Retrieving resource groups..." "Info"
    try {
        $resourceGroups = az group list --query '[].{Name:name, Location:location}' -o json | ConvertFrom-Json
        return $resourceGroups
    }
    catch {
        Write-ColorText "❌ Failed to retrieve resource groups." "Error"
        throw
    }
}

function Select-OrCreate-ResourceGroup {
    param([array]$ResourceGroups)
    
    Write-ColorText "`n📁 Resource Group Options:" "Prompt"
    Write-Host "  0. Create new resource group" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $ResourceGroups.Length; $i++) {
        Write-Host "  $($i + 1). $($ResourceGroups[$i].Name) ($($ResourceGroups[$i].Location))" -ForegroundColor White
    }
    
    do {
        $selection = Read-Host "`nSelect option (0-$($ResourceGroups.Length))"
        $index = [int]$selection
    } while ($index -lt 0 -or $index -gt $ResourceGroups.Length)
    
    if ($index -eq 0) {
        # Create new resource group
        $rgName = Read-Host "Enter new resource group name"
        $locations = @("eastus", "westus2", "centralus", "westeurope", "eastus2")
        Write-ColorText "`nAvailable locations: $($locations -join ', ')" "Info"
        $location = Read-Host "Enter location (default: eastus)"
        if (-not $location) { $location = "eastus" }
        
        Write-ColorText "🔨 Creating resource group '$rgName' in '$location'..." "Info"
        az group create --name $rgName --location $location | Out-Null
        Write-ColorText "✅ Resource group created successfully!" "Success"
        
        return @{ Name = $rgName; Location = $location }
    }
    else {
        $selectedRG = $ResourceGroups[$index - 1]
        Write-ColorText "✅ Selected: $($selectedRG.Name)" "Success"
        return $selectedRG
    }
}

function Get-PlaywrightWorkspaces {
    param([string]$ResourceGroupName)
    
    Write-ColorText "🎭 Checking for Playwright Workspaces in '$ResourceGroupName'..." "Info"
    try {
        # Check if the extension is installed
        $extensions = az extension list --query "[?name=='application-insights'].name" -o tsv
        if (-not $extensions -contains "application-insights") {
            Write-ColorText "📦 Installing Azure CLI extension for App Testing..." "Info"
            az extension add --name application-insights --yes 2>$null
        }
        
        # Try to get Playwright workspaces (this might not work if extension doesn't exist)
        try {
            $workspaces = az resource list --resource-group $ResourceGroupName --resource-type "Microsoft.LoadTestService/playwrightWorkspaces" --query '[].{Name:name, Id:id}' -o json | ConvertFrom-Json
            return $workspaces
        }
        catch {
            Write-ColorText "⚠️  Could not query Playwright Workspaces directly. Will use manual input." "Warning"
            return @()
        }
    }
    catch {
        Write-ColorText "⚠️  Azure CLI extensions not available. Will use manual configuration." "Warning"
        return @()
    }
}

function Select-OrCreate-PlaywrightWorkspace {
    param([array]$Workspaces, [string]$ResourceGroupName, [string]$Location)
    
    Write-ColorText "`n🎭 Playwright Workspace Options:" "Prompt"
    Write-Host "  0. Create new Playwright Workspace" -ForegroundColor Yellow
    Write-Host "  1. Use existing workspace (manual input)" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Workspaces.Length; $i++) {
        Write-Host "  $($i + 2). $($Workspaces[$i].Name)" -ForegroundColor White
        Write-Host "      ID: $($Workspaces[$i].Id)" -ForegroundColor Gray
    }
    
    do {
        $selection = Read-Host "`nSelect option (0-$($Workspaces.Length + 1))"
        $index = [int]$selection
    } while ($index -lt 0 -or $index -gt ($Workspaces.Length + 1))
    
    switch ($index) {
        0 {
            # Create new workspace
            $wsName = Read-Host "Enter Playwright Workspace name (default: PlaywrightDemo)"
            if (-not $wsName) { $wsName = "PlaywrightDemo" }
            
            Write-ColorText "🔨 Creating Playwright Workspace '$wsName'..." "Info"
            Write-ColorText "⚠️  Note: You may need to create this manually in Azure Portal if CLI command fails." "Warning"
            
            try {
                # This might fail if the resource type isn't available via CLI
                $result = az resource create --resource-group $ResourceGroupName --name $wsName --resource-type "Microsoft.LoadTestService/playwrightWorkspaces" --location $Location --properties "{}" 2>$null
                
                if ($result) {
                    Write-ColorText "✅ Playwright Workspace created successfully!" "Success"
                    $resourceId = "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroupName/providers/Microsoft.LoadTestService/playwrightWorkspaces/$wsName"
                    return @{ Name = $wsName; ResourceId = $resourceId; Url = "https://$Location.api.playwright.microsoft.com/accounts/$wsName/" }
                }
                else {
                    throw "CLI creation failed"
                }
            }
            catch {
                Write-ColorText "⚠️  Automatic creation failed. Please create manually:" "Warning"
                Write-ColorText "   1. Go to Azure Portal" "Info"
                Write-ColorText "   2. Search for 'Playwright Workspaces'" "Info"
                Write-ColorText "   3. Create new workspace named '$wsName' in '$ResourceGroupName'" "Info"
                Write-ColorText "   4. Note the service URL for configuration" "Info"
                
                $manualUrl = Read-Host "Enter the Playwright service URL"
                $resourceId = "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroupName/providers/Microsoft.LoadTestService/playwrightWorkspaces/$wsName"
                
                return @{ Name = $wsName; ResourceId = $resourceId; Url = $manualUrl }
            }
        }
        1 {
            # Manual input
            $wsName = Read-Host "Enter existing Playwright Workspace name"
            $wsUrl = Read-Host "Enter Playwright service URL"
            $resourceId = "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroupName/providers/Microsoft.LoadTestService/playwrightWorkspaces/$wsName"
            
            return @{ Name = $wsName; ResourceId = $resourceId; Url = $wsUrl }
        }
        default {
            # Existing workspace from list
            $selectedWS = $Workspaces[$index - 2]
            Write-ColorText "✅ Selected: $($selectedWS.Name)" "Success"
            
            # Need to get the service URL
            $wsUrl = Read-Host "Enter the service URL for this workspace"
            return @{ Name = $selectedWS.Name; ResourceId = $selectedWS.Id; Url = $wsUrl }
        }
    }
}

function Get-LoadTestResources {
    param([string]$ResourceGroupName)
    
    Write-ColorText "🧪 Checking for Azure Load Testing resources..." "Info"
    try {
        $loadTestResources = az resource list --resource-group $ResourceGroupName --resource-type "Microsoft.LoadTestService/loadtests" --query '[].{Name:name, Id:id}' -o json | ConvertFrom-Json
        return $loadTestResources
    }
    catch {
        Write-ColorText "⚠️  Could not query Load Testing resources. Will use manual input." "Warning"
        return @()
    }
}

function Select-OrCreate-LoadTestResource {
    param([array]$LoadTestResources, [string]$ResourceGroupName, [string]$Location)
    
    Write-ColorText "`n🧪 Azure Load Testing Options:" "Prompt"
    Write-Host "  0. Skip Load Testing (demo will work without it)" -ForegroundColor Yellow
    Write-Host "  1. Create new Load Testing resource" -ForegroundColor Green
    
    for ($i = 0; $i -lt $LoadTestResources.Length; $i++) {
        Write-Host "  $($i + 2). $($LoadTestResources[$i].Name)" -ForegroundColor White
    }
    
    do {
        $selection = Read-Host "`nSelect option (0-$($LoadTestResources.Length + 1))"
        $index = [int]$selection
    } while ($index -lt 0 -or $index -gt ($LoadTestResources.Length + 1))
    
    switch ($index) {
        0 {
            Write-ColorText "⏭️  Skipping Azure Load Testing configuration" "Info"
            return $null
        }
        1 {
            $ltName = Read-Host "Enter Load Testing resource name (default: PlaywrightLoadTesting)"
            if (-not $ltName) { $ltName = "PlaywrightLoadTesting" }
            
            Write-ColorText "🔨 Creating Load Testing resource '$ltName'..." "Info"
            try {
                az extension add --name load --yes 2>$null
                az load test-resource create --name $ltName --resource-group $ResourceGroupName --location $Location | Out-Null
                Write-ColorText "✅ Load Testing resource created successfully!" "Success"
                return @{ Name = $ltName }
            }
            catch {
                Write-ColorText "❌ Failed to create Load Testing resource. Skipping." "Error"
                return $null
            }
        }
        default {
            $selectedLT = $LoadTestResources[$index - 2]
            Write-ColorText "✅ Selected: $($selectedLT.Name)" "Success"
            return @{ Name = $selectedLT.Name }
        }
    }
}

function Update-Configuration {
    param(
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [hashtable]$PlaywrightWorkspace,
        [hashtable]$LoadTestResource
    )
    
    Write-ColorText "`n🔧 Updating configuration files..." "Info"
    
    # Update .env file
    $envContent = @"
# Azure Configuration - Generated by Interactive Setup
AZURE_SUBSCRIPTION_ID=$SubscriptionId
AZURE_RESOURCE_GROUP=$ResourceGroupName
"@
    
    if ($PlaywrightWorkspace) {
        $envContent += "`nPLAYWRIGHT_SERVICE_URL=$($PlaywrightWorkspace.Url)"
        $envContent += "`nPLAYWRIGHT_WORKSPACE_NAME=$($PlaywrightWorkspace.Name)"
        $envContent += "`nPLAYWRIGHT_WORKSPACE_RESOURCE_ID=$($PlaywrightWorkspace.ResourceId)"
    }
    
    if ($LoadTestResource) {
        $envContent += "`nAZURE_LOAD_TEST_RESOURCE=$($LoadTestResource.Name)"
    }
    
    $envContent += "`n`n# Add your Azure authentication details if needed:"
    $envContent += "`n# AZURE_TENANT_ID=your-tenant-id"
    $envContent += "`n# AZURE_CLIENT_ID=your-client-id"
    $envContent += "`n# AZURE_CLIENT_SECRET=your-client-secret"
    
    Set-Content -Path ".env" -Value $envContent
    Write-ColorText "✅ Created .env file with your configuration" "Success"
    
    # Update MCP configuration
    $mcpConfig = @{
        mcpServers = @{
            "azure-mcp" = @{
                command = "npx"
                args = @("@azure/mcp-server@latest")
                env = @{
                    AZURE_SUBSCRIPTION_ID = $SubscriptionId
                    AZURE_RESOURCE_GROUP = $ResourceGroupName
                }
            }
            "playwright-mcp" = @{
                command = "npx"
                args = @(
                    "@playwright/mcp@latest",
                    "--headless",
                    "--save-trace",
                    "--save-session",
                    "--output-dir", "./mcp/output"
                )
            }
        }
        version = "1.0"
    }
    
    if ($LoadTestResource) {
        $mcpConfig.mcpServers["azure-load-testing"] = @{
            command = "npx"
            args = @(
                "@azure/mcp-server@latest",
                "--namespace", "loadtesting",
                "--mode", "namespace"
            )
            env = @{
                AZURE_SUBSCRIPTION_ID = $SubscriptionId
                AZURE_RESOURCE_GROUP = $ResourceGroupName
                AZURE_LOAD_TEST_RESOURCE = $LoadTestResource.Name
            }
        }
    }
    
    $mcpConfigJson = $mcpConfig | ConvertTo-Json -Depth 10
    Set-Content -Path "mcp/mcp-config.json" -Value $mcpConfigJson
    Write-ColorText "✅ Updated MCP configuration" "Success"
}

function Install-Dependencies {
    Write-ColorText "`n📦 Installing dependencies..." "Info"
    
    # Python dependencies
    Write-ColorText "🐍 Installing Python packages..." "Info"
    python -m pip install -r requirements.txt --quiet
    
    # Node.js dependencies
    Write-ColorText "📦 Installing Node.js packages..." "Info"
    npm install --silent
    
    # Playwright browsers
    Write-ColorText "🎭 Installing Playwright browsers..." "Info"
    npx playwright install --quiet
    
    Write-ColorText "✅ All dependencies installed!" "Success"
}

function Generate-TestFiles {
    Write-ColorText "`n🔄 Generating test files..." "Info"
    
    # Traditional test files
    python swagger_to_locust.py swagger-sample.yaml locust_swagger.py
    python postman_to_locust.py postman-sample.json locust_postman.py
    python swagger_to_playwright.py swagger-sample.yaml tests/swagger-generated.spec.ts
    python postman_to_playwright.py postman-sample.json tests/postman-generated.spec.ts
    
    # MCP test files
    python swagger_to_azure_mcp.py swagger-sample.yaml mcp/output/swagger-azure-mcp.sh
    python postman_to_azure_mcp.py postman-sample.json mcp/output/postman-azure-mcp.sh
    python swagger_to_playwright_mcp.py swagger-sample.yaml mcp/output/swagger-mcp-commands.js
    python postman_to_playwright_mcp.py postman-sample.json mcp/output/postman-mcp-commands.js
    
    Write-ColorText "✅ Test files generated!" "Success"
}

function Show-Summary {
    param(
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [hashtable]$PlaywrightWorkspace,
        [hashtable]$LoadTestResource
    )
    
    Write-ColorText "`n🎉 Setup Complete! Configuration Summary:" "Header"
    Write-ColorText "=" * 50 "Header"
    Write-ColorText "Subscription: $SubscriptionId" "Info"
    Write-ColorText "Resource Group: $ResourceGroupName" "Info"
    
    if ($PlaywrightWorkspace) {
        Write-ColorText "Playwright Workspace: $($PlaywrightWorkspace.Name)" "Info"
        Write-ColorText "Service URL: $($PlaywrightWorkspace.Url)" "Info"
    }
    
    if ($LoadTestResource) {
        Write-ColorText "Load Testing Resource: $($LoadTestResource.Name)" "Info"
    }
    else {
        Write-ColorText "Load Testing: Skipped (demo works without it)" "Warning"
    }
    
    Write-ColorText "`n🚀 Next Steps:" "Success"
    Write-ColorText "1. Run tests: npm run test" "Info"
    Write-ColorText "2. View results: Test report opens automatically" "Info"
    Write-ColorText "3. For Azure testing: npm run test:azure" "Info"
    Write-ColorText "4. Demo runner: .\run-demo.ps1" "Info"
}

# Main execution
try {
    Show-Header
    
    # Step 1: Azure Authentication
    if (-not $SkipAzureLogin -and -not (Test-AzureConnection)) {
        Write-ColorText "🔐 Azure Authentication Required" "Prompt"
        Write-ColorText "Please authenticate to Azure CLI..." "Info"
        az login
        
        if (-not (Test-AzureConnection)) {
            throw "Azure authentication failed"
        }
    }
    
    # Step 2: Subscription Selection
    $subscriptions = Get-AzureSubscriptions
    $selectedSubscription = Select-AzureSubscription -Subscriptions $subscriptions
    
    # Step 3: Resource Group Selection/Creation
    $resourceGroups = Get-ResourceGroups -SubscriptionId $selectedSubscription.Id
    $selectedResourceGroup = Select-OrCreate-ResourceGroup -ResourceGroups $resourceGroups
    
    # Step 4: Playwright Workspace Configuration
    $playwrightWorkspaces = Get-PlaywrightWorkspaces -ResourceGroupName $selectedResourceGroup.Name
    $selectedPlaywrightWorkspace = Select-OrCreate-PlaywrightWorkspace -Workspaces $playwrightWorkspaces -ResourceGroupName $selectedResourceGroup.Name -Location $selectedResourceGroup.Location
    
    # Step 5: Load Testing Resource Configuration
    $loadTestResources = Get-LoadTestResources -ResourceGroupName $selectedResourceGroup.Name
    $selectedLoadTestResource = Select-OrCreate-LoadTestResource -LoadTestResources $loadTestResources -ResourceGroupName $selectedResourceGroup.Name -Location $selectedResourceGroup.Location
    
    # Step 6: Update Configuration
    Update-Configuration -SubscriptionId $selectedSubscription.Id -ResourceGroupName $selectedResourceGroup.Name -PlaywrightWorkspace $selectedPlaywrightWorkspace -LoadTestResource $selectedLoadTestResource
    
    # Step 7: Install Dependencies
    Install-Dependencies
    
    # Step 8: Generate Test Files
    Generate-TestFiles
    
    # Step 9: Show Summary
    Show-Summary -SubscriptionId $selectedSubscription.Id -ResourceGroupName $selectedResourceGroup.Name -PlaywrightWorkspace $selectedPlaywrightWorkspace -LoadTestResource $selectedLoadTestResource
    
    Write-ColorText "`n✨ Demo is ready! Run 'npm run test' to see it in action!" "Success"
}
catch {
    Write-ColorText "`n❌ Setup failed: $($_.Exception.Message)" "Error"
    Write-ColorText "Please check the error above and try again." "Error"
    exit 1
}
