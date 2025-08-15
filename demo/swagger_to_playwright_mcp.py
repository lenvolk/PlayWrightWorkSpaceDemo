import sys
import yaml
import json

MCP_PLAYWRIGHT_TEMPLATE = '''/**
 * MCP Playwright Test Commands
 * Generated from Swagger: {swagger_file}
 * 
 * These commands use Playwright MCP for browser automation
 * instead of direct Playwright API calls
 */

// MCP Playwright Commands for API Testing
const mcpCommands = [
{test_commands}
];

// Execute all commands sequentially
async function runAllTests() {{
    console.log('Starting MCP Playwright API Tests...');
    
    for (const command of mcpCommands) {{
        console.log(`Executing: ${{command.name}}`);
        // In actual implementation, these would be sent to MCP server
        console.log(`Command: ${{command.action}}`);
        console.log(`Params: ${{JSON.stringify(command.params)}}`);
        console.log('---');
    }}
}}

// Export for integration with MCP client
module.exports = {{ mcpCommands, runAllTests }};
'''

MCP_COMMAND_TEMPLATE = '''  {{
    name: "{test_name}",
    action: "request",
    params: {{
      method: "{method}",
      url: "http://localhost:5000{endpoint}",
      headers: {{"Content-Type": "application/json"}},
      expectedStatus: 200,
      validation: {{
        checkResponse: true,
        logResponse: true,
        saveTrace: true
      }}
    }}
  }}'''

def generate_mcp_commands(spec):
    commands = []
    
    if 'paths' in spec:
        for path, methods in spec['paths'].items():
            for method, details in methods.items():
                test_name = f"{method.upper()} {path}"
                
                command = MCP_COMMAND_TEMPLATE.format(
                    test_name=test_name,
                    method=method.upper(),
                    endpoint=path
                )
                commands.append(command)
    
    return ',\\n'.join(commands) if commands else '// No API endpoints found'

def main(swagger_path, output_path):
    with open(swagger_path, 'r') as f:
        if swagger_path.endswith('.json'):
            spec = json.load(f)
        else:
            spec = yaml.safe_load(f)
    
    test_commands = generate_mcp_commands(spec)
    mcp_script = MCP_PLAYWRIGHT_TEMPLATE.format(
        swagger_file=swagger_path,
        test_commands=test_commands
    )
    
    with open(output_path, 'w') as f:
        f.write(mcp_script)
    
    print(f"MCP Playwright commands generated at {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python swagger_to_playwright_mcp.py <swagger.yaml> <output.js>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
