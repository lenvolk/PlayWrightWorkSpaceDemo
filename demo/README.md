# Swagger and Postman Conversion Demo

This demo shows how to convert Swagger (OpenAPI) documentation and Postman collections into Locust scripts, and execute the tests end-to-end.

## Structure
- `swagger-sample.yaml`: Example OpenAPI 3.0 spec
- `postman-sample.json`: Example Postman collection
- `swagger_to_locust.py`: Script to convert Swagger to Locust script
- `postman_to_locust.py`: Script to convert Postman to Locust script
- `locust_swagger.py`: Example Locust script generated from Swagger
- `locust_postman.py`: Example Locust script generated from Postman
- `requirements.txt`: Python dependencies

## Steps

### 1. Install dependencies
```powershell
pip install -r requirements.txt
```

### 2. Convert Swagger/Postman to Locust
```powershell
python swagger_to_locust.py swagger-sample.yaml locust_swagger.py
python postman_to_locust.py postman-sample.json locust_postman.py
```

### 3. Run Locust tests
```powershell
python -m locust -f locust_swagger.py
# or
python -m locust -f locust_postman.py
```

Open http://localhost:8089 in your browser to start the test.

---

This demo can be extended to use real conversion tools and more complex APIs.
