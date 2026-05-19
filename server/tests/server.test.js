const request = require('supertest');
const app = require('../app');
const mongoose = require('mongoose');

// Mock environment variables for CI
process.env.JWT_SECRET = 'test_secret_key';

describe('Server API Endpoints', () => {
  // Test the basic /api/test endpoint
  it('should return 200 for GET /api/test', async () => {
    const res = await request(app).get('/api/test');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('message', 'Server is working!');
  });

  // We should mock mongoose connection or close it after tests
  afterAll(async () => {
    // If connected during tests, ensure it's closed
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
    }
  });
});
