#!/usr/bin/env powershell

# MCP vs Traditional Demo Runner
# Showcases the power and flexibility of MCP architecture

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("traditional", "mcp", "compare", "all")]
    [string]$Mode = "compare"
)

Write-Host "🎭 MCP vs Traditional Demo Runner" -ForegroundColor Magenta
Write-Host "Mode: $Mode" -ForegroundColor Cyan
Write-Host ""

function Start-MockServer {
    Write-Host "🚀 Starting mock API server..." -ForegroundColor Green
    $mockProcess = Start-Process -FilePath "python" -ArgumentList "mock-api-server.py" -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 3
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/hello" -Method GET -TimeoutSec 5
        Write-Host "✅ Mock API server running on http://localhost:5000" -ForegroundColor Green
        return $mockProcess
    } catch {
        Write-Host "❌ Failed to start mock API server" -ForegroundColor Red
        return $null
    }
}

function Run-TraditionalDemo {
    Write-Host "📊 Running Traditional Approach Demo..." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "1. Traditional Playwright Tests:" -ForegroundColor White
    npx playwright test tests/swagger-generated.spec.ts --headed
    
    Write-Host "`n2. Traditional Locust Load Tests:" -ForegroundColor White
    Write-Host "   Starting Locust server (open http://localhost:8089)" -ForegroundColor Gray
    Start-Process -FilePath "python" -ArgumentList "-m", "locust", "-f", "locust_swagger.py" -WindowStyle Normal
    
    Write-Host "✅ Traditional demo running!" -ForegroundColor Green
}

function Run-McpDemo {
    Write-Host "🎯 Running MCP Approach Demo..." -ForegroundColor Yellow
    Write-Host ""
    
    # Start MCP servers
    Write-Host "1. Starting MCP Servers:" -ForegroundColor White
    npm run mcp:start
    Start-Sleep -Seconds 3
    npm run mcp:status
    
    Write-Host "`n2. Azure Load Testing MCP Commands:" -ForegroundColor White
    if (Test-Path "mcp/output/swagger-azure-mcp.sh") {
        Write-Host "   Executing Azure MCP load testing commands..." -ForegroundColor Gray
        # Display the commands that would be executed
        Write-Host "   Generated MCP Commands:" -ForegroundColor Cyan
        Get-Content "mcp/output/swagger-azure-mcp.sh" | Select-Object -First 10 | ForEach-Object {
            if ($_ -notmatch "^#" -and $_ -ne "") {
                Write-Host "     $($_)" -ForegroundColor White
            }
        }
        Write-Host "     ... (see full file for all commands)" -ForegroundColor Gray
    }
    
    Write-Host "`n3. Playwright MCP Commands:" -ForegroundColor White
    if (Test-Path "mcp/output/swagger-mcp-commands.js") {
        Write-Host "   Executing Playwright MCP automation..." -ForegroundColor Gray
        node "mcp/output/swagger-mcp-commands.js"
    }
    
    Write-Host "`n✅ MCP demo completed!" -ForegroundColor Green
}

function Show-Comparison {
    Write-Host "⚖️  MCP vs Traditional Comparison" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "📊 Feature Comparison:" -ForegroundColor Cyan
    Write-Host ""
    
    $comparison = @(
        @{Feature="Setup Complexity"; Traditional="Manual config files"; MCP="Declarative JSON config"},
        @{Feature="Tool Integration"; Traditional="Direct API calls"; MCP="Unified MCP interface"},
        @{Feature="Orchestration"; Traditional="Custom scripts"; MCP="Built-in tool chaining"},
        @{Feature="Scalability"; Traditional="Manual scaling"; MCP="Auto-scaling with MCP"},
        @{Feature="Debugging"; Traditional="Limited tracing"; MCP="Full MCP trace capture"},
        @{Feature="Flexibility"; Traditional="Hard-coded flows"; MCP="Dynamic tool composition"},
        @{Feature="Maintenance"; Traditional="Multiple codebases"; MCP="Centralized MCP tools"}
    )
    
    $comparison | ForEach-Object {
        Write-Host "   $($_.Feature):" -ForegroundColor White
        Write-Host "     Traditional: $($_.Traditional)" -ForegroundColor Yellow
        Write-Host "     MCP:         $($_.MCP)" -ForegroundColor Green
        Write-Host ""
    }
    
    Write-Host "🎯 MCP Advantages:" -ForegroundColor Cyan
    Write-Host "   ✨ Unified tool interface across all services" -ForegroundColor Green
    Write-Host "   🔄 Dynamic tool composition and chaining" -ForegroundColor Green
    Write-Host "   📊 Enhanced observability and tracing" -ForegroundColor Green
    Write-Host "   🚀 Better scalability and resource management" -ForegroundColor Green
    Write-Host "   🛠️  Easier maintenance and updates" -ForegroundColor Green
    Write-Host "   🎭 Rich context and state management" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📁 Generated Files Comparison:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Traditional Approach:" -ForegroundColor Yellow
    @("locust_swagger.py", "tests/swagger-generated.spec.ts", "playwright.config.ts") | ForEach-Object {
        if (Test-Path $_) {
            $size = (Get-Item $_).Length
            Write-Host "   ✓ $_ ($size bytes)" -ForegroundColor White
        }
    }
    
    Write-Host "`nMCP Approach:" -ForegroundColor Green
    @("mcp/output/swagger-azure-mcp.sh", "mcp/output/swagger-mcp-commands.js", "mcp/mcp-config.json") | ForEach-Object {
        if (Test-Path $_) {
            $size = (Get-Item $_).Length
            Write-Host "   ✓ $_ ($size bytes)" -ForegroundColor White
        }
    }
}

function Run-AllDemos {
    Write-Host "🎪 Running Complete Demo Suite..." -ForegroundColor Magenta
    Write-Host ""
    
    Show-Comparison
    Write-Host ""
    
    Read-Host "Press Enter to start Traditional demo"
    Run-TraditionalDemo
    
    Write-Host ""
    Read-Host "Press Enter to start MCP demo"
    Run-McpDemo
    
    Write-Host ""
    Write-Host "🏁 All demos completed! Check the results and compare the approaches." -ForegroundColor Magenta
}

# Main execution
$mockServer = Start-MockServer

if ($mockServer) {
    switch ($Mode) {
        "traditional" { Run-TraditionalDemo }
        "mcp" { Run-McpDemo }
        "compare" { Show-Comparison }
        "all" { Run-AllDemos }
    }
    
    Write-Host ""
    Write-Host "🔧 Cleanup:" -ForegroundColor Yellow
    Write-Host "   • Stop mock server: Stop-Process -Id $($mockServer.Id)" -ForegroundColor Gray
    Write-Host "   • Stop MCP servers: npm run mcp:stop" -ForegroundColor Gray
    Write-Host "   • View traces: dir mcp/output/traces/" -ForegroundColor Gray
} else {
    Write-Host "❌ Cannot proceed without mock API server" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎯 Demo completed! Choose your preferred approach for production use." -ForegroundColor Cyan
