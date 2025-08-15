import sys
import json

PLAYWRIGHT_TEMPLATE = '''import {{ test, expect }} from '@playwright/test';

// Generated from Postman Collection: {collection_file}
test.describe('API Tests from Postman', () => {{
{test_methods}
}});
'''

TEST_METHOD_TEMPLATE = '''
  test('{test_name}', async ({{ request }}) => {{
    const response = await request.{http_method}('{url}'{headers});
    expect(response.status()).toBe(200);
    
    const responseData = await response.json();
    console.log('Response:', responseData);
  }});'''

def generate_test_methods(collection):
    test_methods = []
    
    if 'item' in collection:
        for item in collection['item']:
            if 'request' in item:
                request = item['request']
                test_name = item.get('name', 'Unnamed test')
                method = request.get('method', 'GET').lower()
                
                # Handle URL
                url = request.get('url', '')
                if isinstance(url, dict):
                    url = url.get('raw', '')
                
                # Simple URL parsing - remove protocol and host for relative paths
                if url.startswith('http'):
                    url_parts = url.split('/', 3)
                    if len(url_parts) > 3:
                        url = '/' + url_parts[3]
                    else:
                        url = '/'
                
                # Handle headers (simplified)
                headers = ''
                if 'header' in request and request['header']:
                    headers = ', { headers: { /* Add headers here */ } }'
                
                test_method = TEST_METHOD_TEMPLATE.format(
                    test_name=test_name,
                    http_method=method,
                    url=url,
                    headers=headers
                )
                test_methods.append(test_method)
    
    return '\\n'.join(test_methods) if test_methods else '\\n  test.skip("No API requests found", () => {});'

def main(postman_path, output_path):
    with open(postman_path, 'r') as f:
        collection = json.load(f)
    
    test_methods = generate_test_methods(collection)
    playwright_code = PLAYWRIGHT_TEMPLATE.format(
        collection_file=postman_path,
        test_methods=test_methods
    )
    
    with open(output_path, 'w') as f:
        f.write(playwright_code)
    
    print(f"Playwright test generated at {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python postman_to_playwright.py <postman.json> <output.spec.ts>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
