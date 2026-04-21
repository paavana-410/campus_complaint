const request = require('supertest');
const app = require('../app');
const User = require('../models/User');
const Complaint = require('../models/Complaint');
const jwt = require('jsonwebtoken');

jest.mock('../models/User');
jest.mock('../models/Complaint');
jest.mock('jsonwebtoken');

describe('Complaint API Endpoints', () => {
    let studentToken = 'fake-jwt-token';
    let studentId = '12345';

    beforeEach(() => {
        jest.clearAllMocks();
        // Mock JWT verification to auto-pass authMiddleware
        jwt.verify.mockReturnValue({ user: { id: studentId, role: 'student' } });
    });

    describe('GET /api/complaints/my', () => {
        it('should get all complaints raised by the logged-in student', async () => {
            Complaint.find.mockReturnValue({
                sort: jest.fn().mockResolvedValue([
                    { title: 'Leaky faucet', status: 'pending', raisedBy: studentId }
                ])
            });

            const res = await request(app)
                .get('/api/complaints/my')
                .set('Authorization', `Bearer ${studentToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.length).toEqual(1);
            expect(res.body[0]).toHaveProperty('title', 'Leaky faucet');
        });

        it('should deny access if no token is provided', async () => {
            const res = await request(app).get('/api/complaints/my');
            expect(res.statusCode).toEqual(401);
            expect(res.body).toHaveProperty('message', 'Access denied. No token provided.');
        });
    });

    describe('POST /api/complaints', () => {
        it('should successfully create a new complaint', async () => {
            Complaint.prototype.save = jest.fn().mockResolvedValue(true);

            const res = await request(app)
                .post('/api/complaints')
                .set('Authorization', `Bearer ${studentToken}`)
                .send({
                    title: 'Broken Projector',
                    description: 'The projector in Hall B is broken.',
                    category: 'Classroom',
                    dueInDays: 1
                });
            
            expect(res.statusCode).toEqual(201);
            expect(res.body.message).toEqual('Complaint submitted successfully');
            expect(Complaint.prototype.save).toHaveBeenCalled();
        });
    });

    describe('GET /api/complaints/stats', () => {
        it('should fetch public stats for the dashboard', async () => {
            Complaint.countDocuments.mockResolvedValueOnce(10).mockResolvedValueOnce(5);
            Complaint.find.mockResolvedValue([]);

            const res = await request(app).get('/api/complaints/stats');
            expect(res.statusCode).toEqual(200);
            expect(res.body).toHaveProperty('total', 10);
            expect(res.body).toHaveProperty('resolved', 5);
        });
    });
});
