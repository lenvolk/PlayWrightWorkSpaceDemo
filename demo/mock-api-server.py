from flask import Flask, jsonify, request, render_template_string

app = Flask(__name__)

# Sample data
users = [
    {"id": 1, "name": "John Doe", "email": "john@example.com"},
    {"id": 2, "name": "Jane Smith", "email": "jane@example.com"}
]

# HTML Templates for Web UI Testing
DOCS_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Documentation - Sample API</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; transition: all 0.3s; }
        .dark-theme { background-color: #2d2d2d; color: #ffffff; }
        .grid-container { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .endpoint { background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 10px 0; }
        .dark-theme .endpoint { background: #444; }
        .mobile-menu { display: none; }
        .desktop-nav { display: block; }
        @media (max-width: 768px) {
            .mobile-menu { display: block; }
            .desktop-nav { display: none; }
        }
        button { padding: 10px 20px; margin: 10px; border: none; border-radius: 4px; cursor: pointer; }
        #dark-mode-toggle { background: #007acc; color: white; }
    </style>
</head>
<body>
    <nav class="desktop-nav">Desktop Navigation</nav>
    <div class="mobile-menu">Mobile Menu</div>
    
    <div aria-label="API Documentation">
        <h1>Sample API Documentation</h1>
        <button id="dark-mode-toggle">Toggle Dark Mode</button>
        
        <div class="grid-container">
            <div class="api-section">
                <h2>Available Endpoints</h2>
                
                <div class="endpoint">
                    <h3>GET /hello</h3>
                    <p>Returns a simple greeting message</p>
                    <code>Response: {"message": "Hello, World!"}</code>
                </div>
                
                <div class="endpoint">
                    <h3>GET /users</h3>
                    <p>Retrieves all users</p>
                    <code>Response: [{"id": 1, "name": "John Doe", "email": "john@example.com"}]</code>
                </div>
                
                <div class="endpoint">
                    <h3>POST /users</h3>
                    <p>Creates a new user</p>
                    <code>Body: {"name": "string", "email": "string"}</code>
                </div>
                
                <div class="endpoint">
                    <h3>GET /users/{id}</h3>
                    <p>Retrieves a specific user by ID</p>
                    <code>Response: {"id": 1, "name": "John Doe", "email": "john@example.com"}</code>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        document.getElementById('dark-mode-toggle').addEventListener('click', function() {
            document.body.classList.toggle('dark-theme');
        });
    </script>
</body>
</html>
"""

TEST_PAGE_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Tester - Interactive Testing</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .test-section { background: #f9f9f9; padding: 20px; margin: 20px 0; border-radius: 8px; }
        button { padding: 10px 20px; margin: 10px; border: none; border-radius: 4px; cursor: pointer; background: #007acc; color: white; }
        input { padding: 10px; margin: 5px; border: 1px solid #ddd; border-radius: 4px; width: 200px; }
        .response { background: #e8f5e8; padding: 15px; margin: 10px 0; border-radius: 4px; border-left: 4px solid #4caf50; }
        .success { background: #d4edda; color: #155724; padding: 10px; border-radius: 4px; margin: 10px 0; }
        #success-message { display: none; }
    </style>
</head>
<body>
    <div class="container">
        <h1>API Tester</h1>
        
        <div class="test-section">
            <h2>Test Hello Endpoint</h2>
            <button id="test-hello">Test /hello</button>
            <div id="response-hello" class="response" style="display: none;"></div>
        </div>
        
        <div class="test-section">
            <h2>Create User</h2>
            <input type="text" id="user-name" placeholder="User Name">
            <input type="email" id="user-email" placeholder="User Email">
            <button id="create-user-btn">Create User</button>
            <div id="success-message" class="success">User created successfully!</div>
        </div>
    </div>
    
    <script>
        document.getElementById('test-hello').addEventListener('click', async function() {
            try {
                const response = await fetch('/hello');
                const data = await response.json();
                document.getElementById('response-hello').textContent = JSON.stringify(data);
                document.getElementById('response-hello').style.display = 'block';
            } catch (error) {
                document.getElementById('response-hello').textContent = 'Error: ' + error.message;
                document.getElementById('response-hello').style.display = 'block';
            }
        });
        
        document.getElementById('create-user-btn').addEventListener('click', function() {
            const name = document.getElementById('user-name').value;
            const email = document.getElementById('user-email').value;
            
            if (name && email) {
                document.getElementById('success-message').style.display = 'block';
                setTimeout(() => {
                    document.getElementById('success-message').style.display = 'none';
                }, 3000);
            }
        });
    </script>
</body>
</html>
"""

EXPLORER_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Explorer - Interactive API Testing</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; }
        select, input, button { padding: 10px; margin: 10px; border: 1px solid #ddd; border-radius: 4px; }
        button { background: #007acc; color: white; border: none; cursor: pointer; }
        .response-container { background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .error { background: #f8d7da; color: #721c24; padding: 15px; border-radius: 4px; margin: 10px 0; }
        pre { background: #ffffff; padding: 15px; border: 1px solid #ddd; border-radius: 4px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>API Explorer</h1>
        
        <div>
            <label for="endpoint-select">Select Endpoint:</label>
            <select id="endpoint-select">
                <option value="/hello">GET /hello</option>
                <option value="/users">GET /users</option>
                <option value="/users/1">GET /users/1</option>
            </select>
            <button id="execute-btn">Execute</button>
        </div>
        
        <div>
            <label for="custom-endpoint">Custom Endpoint:</label>
            <input type="text" id="custom-endpoint" placeholder="/api/endpoint">
            <button id="execute-custom-btn">Execute Custom</button>
        </div>
        
        <div class="response-container">
            <h3>Response:</h3>
            <div id="error-message" class="error" style="display: none;"></div>
            <pre id="api-response">Click execute to see response...</pre>
        </div>
    </div>
    
    <script>
        async function executeRequest(endpoint) {
            try {
                document.getElementById('error-message').style.display = 'none';
                const response = await fetch(endpoint);
                const data = await response.json();
                
                if (response.ok) {
                    document.getElementById('api-response').textContent = JSON.stringify(data, null, 2);
                } else {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }
            } catch (error) {
                document.getElementById('error-message').textContent = error.message;
                document.getElementById('error-message').style.display = 'block';
                document.getElementById('api-response').textContent = 'Request failed';
            }
        }
        
        document.getElementById('execute-btn').addEventListener('click', function() {
            const endpoint = document.getElementById('endpoint-select').value;
            executeRequest(endpoint);
        });
        
        document.getElementById('execute-custom-btn').addEventListener('click', function() {
            const endpoint = document.getElementById('custom-endpoint').value;
            executeRequest(endpoint);
        });
    </script>
</body>
</html>
"""

LOCATION_TEST_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Location Testing</title>
</head>
<body>
    <h1>Geolocation Testing</h1>
    <button id="get-location-btn">Get Location</button>
    <div id="location-result"></div>
    
    <script>
        document.getElementById('get-location-btn').addEventListener('click', function() {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(function(position) {
                    // Simulate location lookup
                    document.getElementById('location-result').textContent = 'New York, NY (40.7128, -74.0060)';
                });
            }
        });
    </script>
</body>
</html>
"""

# API Routes
@app.route('/hello', methods=['GET'])
def hello():
    return jsonify({"message": "Hello, World!"})

@app.route('/users', methods=['GET'])
def get_users():
    return jsonify(users)

@app.route('/users', methods=['POST'])
def create_user():
    data = request.get_json()
    new_user = {
        "id": len(users) + 1,
        "name": data.get("name"),
        "email": data.get("email")
    }
    users.append(new_user)
    return jsonify(new_user), 201

@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = next((u for u in users if u["id"] == user_id), None)
    if user:
        return jsonify(user)
    return jsonify({"error": "User not found"}), 404

# Web UI Routes for Testing
@app.route('/docs')
def docs():
    return render_template_string(DOCS_TEMPLATE)

@app.route('/test')
def test_page():
    return render_template_string(TEST_PAGE_TEMPLATE)

@app.route('/explorer')
def explorer():
    return render_template_string(EXPLORER_TEMPLATE)

@app.route('/location-test')
def location_test():
    return render_template_string(LOCATION_TEST_TEMPLATE)

if __name__ == '__main__':
    print("🚀 Starting Mock API Server with Web UI Support...")
    print("📚 API Documentation: http://localhost:5000/docs")
    print("🧪 Interactive Tester: http://localhost:5000/test")
    print("🔍 API Explorer: http://localhost:5000/explorer")
    print("📍 Location Testing: http://localhost:5000/location-test")
    print("🔌 API Endpoints: /hello, /users")
    app.run(debug=True, host='localhost', port=5000)
