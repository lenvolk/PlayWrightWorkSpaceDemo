import sys
import yaml

TEMPLATE = '''from locust import HttpUser, task

class SwaggerUser(HttpUser):
    @task
    def get_hello(self):
        self.client.get("/hello")
'''

def main(swagger_path, output_path):
    with open(swagger_path, 'r') as f:
        spec = yaml.safe_load(f)
    # For demo, just output a static Locust script for /hello
    with open(output_path, 'w') as f:
        f.write(TEMPLATE)
    print(f"Locust script generated at {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python swagger_to_locust.py <swagger.yaml> <output.py>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
