import sys
import json

MCP_LOAD_TEST_TEMPLATE = '''# Azure MCP Load Testing Commands
# Generated from Postman: {postman_file}

# Create Load Test Resource (if not exists)
azmcp loadtesting testresource create \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name}

{load_test_commands}

# Monitor all test executions
azmcp loadtesting testrun list \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name}
'''

LOAD_TEST_COMMAND_TEMPLATE = '''
# Load Test for {request_name}
azmcp loadtesting test create \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name} \\
    --test-id "{test_id}" \\
    --display-name "{test_name}" \\
    --description "Load test for {request_name} request" \\
    --endpoint "{endpoint}" \\
    --virtual-users 15 \\
    --duration 90 \\
    --ramp-up-time 15

# Execute the load test
azmcp loadtesting testrun create \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name} \\
    --test-id "{test_id}" \\
    --testrun-id "{testrun_id}" \\
    --display-name "Test Run: {request_name}" \\
    --description "Automated Postman-derived test via MCP"

# Get detailed test results
azmcp loadtesting testrun get \\
    --subscription $AZURE_SUBSCRIPTION_ID \\
    --resource-group $AZURE_RESOURCE_GROUP \\
    --test-resource-name {test_resource_name} \\
    --testrun-id "{testrun_id}"'''

def generate_load_test_commands(collection, test_resource_name):
    commands = []
    
    if 'item' in collection:
        for item in collection['item']:
            if 'request' in item:
                request = item['request']
                request_name = item.get('name', 'Unnamed request')
                method = request.get('method', 'GET')
                
                # Handle URL
                url = request.get('url', '')
                if isinstance(url, dict):
                    url = url.get('raw', '')
                
                # Extract endpoint from full URL
                endpoint = url
                if url.startswith('http'):
                    try:
                        from urllib.parse import urlparse
                        parsed = urlparse(url)
                        endpoint = f"http://localhost:5000{parsed.path}"
                    except:
                        endpoint = url
                
                test_id = f"test_{request_name.lower().replace(' ', '_')}"
                testrun_id = f"run_{request_name.lower().replace(' ', '_')}_$(date +%s)"
                test_name = f"Load Test: {request_name}"
                
                command = LOAD_TEST_COMMAND_TEMPLATE.format(
                    request_name=request_name,
                    test_resource_name=test_resource_name,
                    test_id=test_id,
                    test_name=test_name,
                    endpoint=endpoint,
                    testrun_id=testrun_id
                )
                commands.append(command)
    
    return '\\n'.join(commands) if commands else '# No API requests found for load testing'

def main(postman_path, output_path):
    with open(postman_path, 'r') as f:
        collection = json.load(f)
    
    test_resource_name = "postman-demo-loadtest"
    load_test_commands = generate_load_test_commands(collection, test_resource_name)
    
    mcp_script = MCP_LOAD_TEST_TEMPLATE.format(
        postman_file=postman_path,
        test_resource_name=test_resource_name,
        load_test_commands=load_test_commands
    )
    
    with open(output_path, 'w') as f:
        f.write(mcp_script)
    
    print(f"Azure MCP Load Testing script generated at {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python postman_to_azure_mcp.py <postman.json> <output.sh>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
