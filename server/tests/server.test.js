const request = require('supertest');
const app = require('../app');
const mongoose = require('mongoose');

describe('Server API Endpoints', () => {
  // Test the basic /api/test endpoint
  it('should return 200 for GET /api/test', async () => {
    const res = await request(app).get('/api/test');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('message', 'Server is working!');
  });

  // Test the prometheus metrics endpoint
  it('should return metrics for GET /metrics', async () => {
    const res = await request(app).get('/metrics');
    expect(res.statusCode).toEqual(200);
    expect(res.text).toContain('http_requests_total');
  });

  // We should mock mongoose connection or close it after tests
  afterAll(async () => {
    // If connected during tests, ensure it's closed
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
    }
  });
});
