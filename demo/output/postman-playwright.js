import { test, expect } from '@playwright/test';

// Generated from Postman Collection: postman-sample.json
test.describe('API Tests from Postman', () => {

  test('Hello Request', async ({ request }) => {
    const response = await request.get('/hello');
    expect(response.status()).toBe(200);
    
    const responseData = await response.json();
    console.log('Response:', responseData);
  });\n
  test('Get All Users', async ({ request }) => {
    const response = await request.get('/users', { headers: { /* Add headers here */ } });
    expect(response.status()).toBe(200);
    
    const responseData = await response.json();
    console.log('Response:', responseData);
  });\n
  test('Create User', async ({ request }) => {
    const response = await request.post('/users', { headers: { /* Add headers here */ } });
    expect(response.status()).toBe(200);
    
    const responseData = await response.json();
    console.log('Response:', responseData);
  });\n
  test('Get User by ID', async ({ request }) => {
    const response = await request.get('/users/1');
    expect(response.status()).toBe(200);
    
    const responseData = await response.json();
    console.log('Response:', responseData);
  });
});
