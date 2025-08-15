#!/usr/bin/env powershell

# MCP Server Management Script
# Starts and manages Azure MCP and Playwright MCP servers

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "config")]
    [string]$Action = "start",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("azure", "playwright", "all")]
    [string]$Server = "all"
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 MCP Server Manager" -ForegroundColor Cyan
Write-Host "Action: $Action | Server: $Server" -ForegroundColor Yellow

# Configuration
$MCP_CONFIG = "mcp/mcp-config.json"
$PLAYWRIGHT_CONFIG = "mcp/playwright-mcp-config.json"
$PID_DIR = "mcp/pids"
$OUTPUT_DIR = "mcp/output"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $PID_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

function Start-AzureMCP {
    Write-Host "🚀 Starting Azure MCP Server..." -ForegroundColor Green
    
    # Check environment variables
    if (-not $env:AZURE_SUBSCRIPTION_ID) {
        Write-Host "⚠️  AZURE_SUBSCRIPTION_ID not set. Loading from .env..." -ForegroundColor Yellow
        if (Test-Path ".env") {
            Get-Content ".env" | ForEach-Object {
                if ($_ -match "^([^#][^=]+)=(.+)$") {
                    [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
                }
            }
        }
    }
    
    # Start Azure MCP server
    $azureMcpProcess = Start-Process -FilePath "npx" -ArgumentList "@azure/mcp-server@latest", "--port", "3001" -PassThru -WindowStyle Hidden
    $azureMcpProcess.Id | Out-File "mcp/pids/azure-mcp.pid"
    
    Write-Host "✅ Azure MCP Server started on port 3001 (PID: $($azureMcpProcess.Id))" -ForegroundColor Green
}

function Start-PlaywrightMCP {
    Write-Host "🎭 Starting Playwright MCP Server..." -ForegroundColor Green
    
    # Start Playwright MCP server
    $playwrightArgs = @(
        "@playwright/mcp@latest",
        "--port", "3002",
        "--config", $PLAYWRIGHT_CONFIG,
        "--headless",
        "--save-trace",
        "--save-session",
        "--output-dir", $OUTPUT_DIR
    )
    
    $playwrightMcpProcess = Start-Process -FilePath "npx" -ArgumentList $playwrightArgs -PassThru -WindowStyle Hidden
    $playwrightMcpProcess.Id | Out-File "mcp/pids/playwright-mcp.pid"
    
    Write-Host "✅ Playwright MCP Server started on port 3002 (PID: $($playwrightMcpProcess.Id))" -ForegroundColor Green
}

function Stop-McpServer {
    param([string]$PidFile, [string]$ServerName)
    
    if (Test-Path $PidFile) {
        $pid = Get-Content $PidFile
        try {
            Stop-Process -Id $pid -Force
            Remove-Item $PidFile
            Write-Host "⏹️  $ServerName stopped (PID: $pid)" -ForegroundColor Yellow
        } catch {
            Write-Host "⚠️  Failed to stop $ServerName (PID: $pid)" -ForegroundColor Red
        }
    } else {
        Write-Host "ℹ️  $ServerName not running" -ForegroundColor Gray
    }
}

function Get-McpStatus {
    Write-Host "📊 MCP Server Status:" -ForegroundColor Cyan
    
    # Check Azure MCP
    if (Test-Path "mcp/pids/azure-mcp.pid") {
        $azurePid = Get-Content "mcp/pids/azure-mcp.pid"
        try {
            Get-Process -Id $azurePid -ErrorAction Stop | Out-Null
            Write-Host "✅ Azure MCP Server: Running (PID: $azurePid, Port: 3001)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Azure MCP Server: Not Running (stale PID)" -ForegroundColor Red
            Remove-Item "mcp/pids/azure-mcp.pid" -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "⭕ Azure MCP Server: Not Running" -ForegroundColor Gray
    }
    
    # Check Playwright MCP
    if (Test-Path "mcp/pids/playwright-mcp.pid") {
        $playwrightPid = Get-Content "mcp/pids/playwright-mcp.pid"
        try {
            Get-Process -Id $playwrightPid -ErrorAction Stop | Out-Null
            Write-Host "✅ Playwright MCP Server: Running (PID: $playwrightPid, Port: 3002)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Playwright MCP Server: Not Running (stale PID)" -ForegroundColor Red
            Remove-Item "mcp/pids/playwright-mcp.pid" -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "⭕ Playwright MCP Server: Not Running" -ForegroundColor Gray
    }
    
    # Check endpoints
    Write-Host "`n🔗 MCP Endpoints:" -ForegroundColor Cyan
    Write-Host "   Azure MCP:      http://localhost:3001/mcp" -ForegroundColor White
    Write-Host "   Playwright MCP: http://localhost:3002/mcp" -ForegroundColor White
}

function Show-McpConfig {
    Write-Host "⚙️  MCP Configuration:" -ForegroundColor Cyan
    
    if (Test-Path $MCP_CONFIG) {
        Write-Host "`nMCP Config ($MCP_CONFIG):" -ForegroundColor Yellow
        Get-Content $MCP_CONFIG | Write-Host
    }
    
    if (Test-Path $PLAYWRIGHT_CONFIG) {
        Write-Host "`nPlaywright MCP Config ($PLAYWRIGHT_CONFIG):" -ForegroundColor Yellow
        Get-Content $PLAYWRIGHT_CONFIG | Write-Host
    }
    
    Write-Host "`n📁 Output Directory: $OUTPUT_DIR" -ForegroundColor Gray
    Write-Host "📁 PID Directory: $PID_DIR" -ForegroundColor Gray
}

# Main execution logic
switch ($Action) {
    "start" {
        switch ($Server) {
            "azure" { Start-AzureMCP }
            "playwright" { Start-PlaywrightMCP }
            "all" { 
                Start-AzureMCP
                Start-PlaywrightMCP
            }
        }
        Start-Sleep -Seconds 2
        Get-McpStatus
    }
    
    "stop" {
        switch ($Server) {
            "azure" { Stop-McpServer "mcp/pids/azure-mcp.pid" "Azure MCP Server" }
            "playwright" { Stop-McpServer "mcp/pids/playwright-mcp.pid" "Playwright MCP Server" }
            "all" {
                Stop-McpServer "mcp/pids/azure-mcp.pid" "Azure MCP Server"
                Stop-McpServer "mcp/pids/playwright-mcp.pid" "Playwright MCP Server"
            }
        }
    }
    
    "restart" {
        & $MyInvocation.MyCommand.Path -Action stop -Server $Server
        Start-Sleep -Seconds 2
        & $MyInvocation.MyCommand.Path -Action start -Server $Server
    }
    
    "status" {
        Get-McpStatus
    }
    
    "config" {
        Show-McpConfig
    }
}

Write-Host "`n🎯 MCP Server management completed!" -ForegroundColor Cyan
