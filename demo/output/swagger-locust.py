from locust import HttpUser, task

class SwaggerUser(HttpUser):
    @task
    def get_hello(self):
        self.client.get("/hello")
