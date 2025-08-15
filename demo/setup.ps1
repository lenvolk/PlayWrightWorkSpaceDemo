#!/usr/bin/env powershell

# Demo Setup Script for Swagger and Postman Conversion Demo
Write-Host "🚀 Setting up Swagger and Postman Conversion Demo..." -ForegroundColor Green

# Check if we're in the demo directory
if (!(Test-Path "requirements.txt")) {
    Write-Host "❌ Please run this script from the demo directory" -ForegroundColor Red
    exit 1
}

# Install Python dependencies
Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow
python -m pip install -r requirements.txt

# Install Node.js dependencies
Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Yellow
npm install

# Install Playwright browsers
Write-Host "🎭 Installing Playwright browsers..." -ForegroundColor Yellow
npx playwright install

# Create .env file if it doesn't exist
if (!(Test-Path ".env")) {
    Write-Host "📝 Creating .env file..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "⚠️  Please update the .env file with your Azure Playwright Workspaces URL" -ForegroundColor Yellow
}

# Generate test files
Write-Host "🔄 Generating test files from Swagger and Postman..." -ForegroundColor Yellow
python swagger_to_locust.py swagger-sample.yaml locust_swagger.py
python postman_to_locust.py postman-sample.json locust_postman.py
python swagger_to_playwright.py swagger-sample.yaml tests/swagger-generated.spec.ts
python postman_to_playwright.py postman-sample.json tests/postman-generated.spec.ts

Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Update .env file with your Azure Playwright Workspaces URL"
Write-Host "2. Start the mock API server: python mock-api-server.py"
Write-Host "3. Run tests locally: npm run test"
Write-Host "4. Run tests on Azure: npm run test:azure"
Write-Host "5. Run Locust load tests: python -m locust -f locust_swagger.py"
