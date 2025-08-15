import sys
import yaml
import json

PLAYWRIGHT_TEMPLATE = '''import {{ test, expect }} from '@playwright/test';

// Generated from Swagger: {swagger_file}
test.describe('API Tests from Swagger', () => {{
{test_methods}
}});
'''

TEST_METHOD_TEMPLATE = '''
  test('{method_name}', async ({{ request }}) => {{
    const response = await request.{http_method}('{endpoint}');
    expect(response.status()).toBe(200);
    
    const responseData = await response.json();
    console.log('Response:', responseData);
  }});'''

def generate_test_methods(spec):
    test_methods = []
    
    if 'paths' in spec:
        for path, methods in spec['paths'].items():
            for method, details in methods.items():
                method_name = f'{method.upper()} {path}'
                test_method = TEST_METHOD_TEMPLATE.format(
                    method_name=method_name,
                    http_method=method.lower(),
                    endpoint=path
                )
                test_methods.append(test_method)
    
    return '\\n'.join(test_methods) if test_methods else '\\n  test.skip("No API endpoints found", () => {});'

def main(swagger_path, output_path):
    with open(swagger_path, 'r') as f:
        if swagger_path.endswith('.json'):
            spec = json.load(f)
        else:
            spec = yaml.safe_load(f)
    
    test_methods = generate_test_methods(spec)
    playwright_code = PLAYWRIGHT_TEMPLATE.format(
        swagger_file=swagger_path,
        test_methods=test_methods
    )
    
    with open(output_path, 'w') as f:
        f.write(playwright_code)
    
    print(f"Playwright test generated at {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python swagger_to_playwright.py <swagger.yaml> <output.spec.ts>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
