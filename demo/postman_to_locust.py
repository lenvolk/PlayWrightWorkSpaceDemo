import sys
import json

TEMPLATE = '''from locust import HttpUser, task

class PostmanUser(HttpUser):
    @task
    def get_hello(self):
        self.client.get("/hello")
'''

def main(postman_path, output_path):
    with open(postman_path, 'r') as f:
        collection = json.load(f)
    # For demo, just output a static Locust script for /hello
    with open(output_path, 'w') as f:
        f.write(TEMPLATE)
    print(f"Locust script generated at {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python postman_to_locust.py <postman.json> <output.py>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
