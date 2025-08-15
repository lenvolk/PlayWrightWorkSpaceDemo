#!/usr/bin/env powershell

# Enhanced Demo Setup Script with MCP Support
Write-Host "🚀 Setting up Enhanced Swagger and Postman Conversion Demo with MCP..." -ForegroundColor Green

# Check if we're in the demo directory
if (!(Test-Path "requirements.txt")) {
    Write-Host "❌ Please run this script from the demo directory" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Demo Features:" -ForegroundColor Cyan
Write-Host "   ✨ Traditional approach: Locust + Playwright" -ForegroundColor White
Write-Host "   🎯 MCP approach: Azure Load Testing MCP + Playwright MCP" -ForegroundColor White
Write-Host "   🔄 Comparison scenarios and orchestration" -ForegroundColor White
Write-Host ""

# Install Python dependencies
Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow
python -m pip install -r requirements.txt

# Install Node.js dependencies (including MCP packages)
Write-Host "📦 Installing Node.js dependencies and MCP packages..." -ForegroundColor Yellow
npm install

# Install Playwright browsers
Write-Host "🎭 Installing Playwright browsers..." -ForegroundColor Yellow
npx playwright install

# Create .env file if it doesn't exist
if (!(Test-Path ".env")) {
    Write-Host "📝 Creating .env file..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "⚠️  Please update the .env file with your Azure credentials and URLs" -ForegroundColor Yellow
}

# Create output directories
Write-Host "📁 Creating MCP output directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "mcp/output" | Out-Null
New-Item -ItemType Directory -Force -Path "mcp/pids" | Out-Null
New-Item -ItemType Directory -Force -Path "mcp/output/reports" | Out-Null
New-Item -ItemType Directory -Force -Path "mcp/output/traces" | Out-Null

# Generate traditional test files
Write-Host "🔄 Generating traditional test files..." -ForegroundColor Yellow
python swagger_to_locust.py swagger-sample.yaml locust_swagger.py
python postman_to_locust.py postman-sample.json locust_postman.py
python swagger_to_playwright.py swagger-sample.yaml tests/swagger-generated.spec.ts
python postman_to_playwright.py postman-sample.json tests/postman-generated.spec.ts

# Generate MCP test files
Write-Host "🎯 Generating MCP-based test files..." -ForegroundColor Yellow
python swagger_to_azure_mcp.py swagger-sample.yaml mcp/output/swagger-azure-mcp.sh
python postman_to_azure_mcp.py postman-sample.json mcp/output/postman-azure-mcp.sh
python swagger_to_playwright_mcp.py swagger-sample.yaml mcp/output/swagger-mcp-commands.js
python postman_to_playwright_mcp.py postman-sample.json mcp/output/postman-mcp-commands.js

# Set execution permissions for shell scripts
if (Test-Path "mcp/output/*.sh") {
    Write-Host "🔧 Setting execution permissions for MCP scripts..." -ForegroundColor Yellow
    # Note: PowerShell doesn't need to set execute permissions like Unix
}

Write-Host "✅ Enhanced setup complete!" -ForegroundColor Green
Write-Host ""

# Display comprehensive next steps
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 📝 Configure Environment:" -ForegroundColor White
Write-Host "   • Update .env file with your Azure credentials" -ForegroundColor Gray
Write-Host "   • Set up Azure Load Testing resource" -ForegroundColor Gray
Write-Host "   • Configure Playwright Workspaces URL" -ForegroundColor Gray
Write-Host ""

Write-Host "2. 🚀 Start Services:" -ForegroundColor White
Write-Host "   • Mock API: python mock-api-server.py" -ForegroundColor Gray
Write-Host "   • MCP Servers: npm run mcp:start" -ForegroundColor Gray
Write-Host "   • Check status: npm run mcp:status" -ForegroundColor Gray
Write-Host ""

Write-Host "3. 🔄 Traditional Approach:" -ForegroundColor White
Write-Host "   • Load tests: python -m locust -f locust_swagger.py" -ForegroundColor Gray
Write-Host "   • E2E tests: npm run test" -ForegroundColor Gray
Write-Host "   • Azure tests: npm run test:azure" -ForegroundColor Gray
Write-Host ""

Write-Host "4. 🎯 MCP Approach:" -ForegroundColor White
Write-Host "   • Azure Load Testing: ./mcp/output/swagger-azure-mcp.sh" -ForegroundColor Gray
Write-Host "   • Playwright MCP: node mcp/output/swagger-mcp-commands.js" -ForegroundColor Gray
Write-Host "   • Orchestrated demo: npm run demo:mcp" -ForegroundColor Gray
Write-Host ""

Write-Host "5. 📊 Compare & Analyze:" -ForegroundColor White
Write-Host "   • View MCP traces: mcp/output/traces/" -ForegroundColor Gray
Write-Host "   • Check reports: mcp/output/reports/" -ForegroundColor Gray
Write-Host "   • Compare performance and capabilities" -ForegroundColor Gray
Write-Host ""

Write-Host "🌟 Ready for an impressive demo showcasing both traditional and MCP approaches!" -ForegroundColor Magenta
