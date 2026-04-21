const request = require('supertest');
const app = require('../app');
const User = require('../models/User');
const bcrypt = require('bcryptjs');

// Mock environment variables for CI
process.env.JWT_SECRET = 'test_secret_key';

jest.mock('../models/User');
jest.mock('bcryptjs');

describe('Auth API Endpoints', () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('POST /api/auth/register', () => {
        it('should successfully register a new user', async () => {
            User.findOne.mockResolvedValue(null);
            bcrypt.hash.mockResolvedValue('hashed_password');
            User.create.mockResolvedValue({ _id: '123', email: 'new@student.com' });

            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    name: 'New Student',
                    email: 'new@student.com',
                    password: 'password123',
                    role: 'student',
                    department: 'IT'
                });
            
            expect(res.statusCode).toEqual(201);
            expect(res.body).toHaveProperty('message', 'User registered successfully');
            expect(User.findOne).toHaveBeenCalledWith({ email: 'new@student.com' });
        });

        it('should prevent registration with an existing email', async () => {
             User.findOne.mockResolvedValue({ email: 'test@student.com' });

             const res = await request(app)
                .post('/api/auth/register')
                .send({
                    name: 'Duplicate Student',
                    email: 'test@student.com',
                    password: 'password123',
                    role: 'student',
                    department: 'CS'
                });
            expect(res.statusCode).toEqual(400);
            expect(res.body).toHaveProperty('message', 'User with this email already exists');
        });
    });

    describe('POST /api/auth/login', () => {
        it('should allow a registered user to log in', async () => {
            User.findOne.mockResolvedValue({ _id: '123', email: 'test@student.com', password: 'hashed_password', role: 'student' });
            bcrypt.compare.mockResolvedValue(true);

             const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@student.com',
                    password: 'password123'
                });
            expect(res.statusCode).toEqual(200);
            expect(res.body).toHaveProperty('token');
            expect(res.body).toHaveProperty('user');
        });

        it('should reject invalid credentials', async () => {
            User.findOne.mockResolvedValue(null);

            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@student.com',
                    password: 'wrongpassword'
                });
            expect(res.statusCode).toEqual(400);
            expect(res.body).toHaveProperty('message', 'Email not found');
        });
    });
});
