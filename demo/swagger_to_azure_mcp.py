import sys
import yaml
import json

MCP_LOAD_TEST_TEMPLATE = '''# Azure MCP Load Testing Commands
# Generated from Swagger: {swagger_file}

# Create Load Test Resource (if not exists)
azmcp loadtesting testresource create \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name}

{load_test_commands}

# Monitor test execution
azmcp loadtesting testrun list \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name}
'''

LOAD_TEST_COMMAND_TEMPLATE = '''
# Load Test for {endpoint_name}
azmcp loadtesting test create \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name} \\
    --test-id "{test_id}" \\
    --display-name "{test_name}" \\
    --description "Load test for {endpoint} endpoint" \\
    --endpoint "http://localhost:5000{endpoint}" \\
    --virtual-users 10 \\
    --duration 60 \\
    --ramp-up-time 10

# Execute the load test
azmcp loadtesting testrun create \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name} \\
    --test-id "{test_id}" \\
    --testrun-id "{testrun_id}" \\
    --display-name "Test Run for {endpoint_name}" \\
    --description "Automated test execution via MCP"

# Get test results
azmcp loadtesting testrun get \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name} \\
    --testrun-id "{testrun_id}"'''

def generate_load_test_commands(spec, test_resource_name):
    commands = []
    
    if 'paths' in spec:
        for path, methods in spec['paths'].items():
            for method, details in methods.items():
                endpoint_name = f"{method.upper()}_{path.replace('/', '_').replace('{', '').replace('}', '')}"
                test_id = f"test_{endpoint_name.lower()}"
                testrun_id = f"run_{endpoint_name.lower()}_$(date +%s)"
                test_name = f"Load Test: {method.upper()} {path}"
                
                command = LOAD_TEST_COMMAND_TEMPLATE.format(
                    endpoint_name=endpoint_name,
                    test_resource_name=test_resource_name,
                    test_id=test_id,
                    test_name=test_name,
                    endpoint=path,
                    testrun_id=testrun_id
                )
                commands.append(command)
    
    return '\\n'.join(commands) if commands else '# No API endpoints found for load testing'

def main(swagger_path, output_path):
    with open(swagger_path, 'r') as f:
        if swagger_path.endswith('.json'):
            spec = json.load(f)
        else:
            spec = yaml.safe_load(f)
    
    test_resource_name = "swagger-demo-loadtest"
    load_test_commands = generate_load_test_commands(spec, test_resource_name)
    
    mcp_script = MCP_LOAD_TEST_TEMPLATE.format(
        swagger_file=swagger_path,
        test_resource_name=test_resource_name,
        load_test_commands=load_test_commands
    )
    
    with open(output_path, 'w') as f:
        f.write(mcp_script)
    
    print(f"Azure MCP Load Testing script generated at {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python swagger_to_azure_mcp.py <swagger.yaml> <output.sh>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
