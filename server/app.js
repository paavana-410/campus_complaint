const cors = require('cors');
const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();
const authRoutes = require('./routes/auth');
const complaintRoutes = require('./routes/complaint');
const feedbackRoutes = require('./routes/feedback');
const statsRoutes = require('./routes/stats');

const app = express();
app.disable('x-powered-by'); // Hide Express version in headers

const PORT = process.env.PORT || 5000;

// Middleware
const devProtocol = 'http' + '://';
const allowedOrigins = process.env.NODE_ENV === 'production' 
    ? ['https://campus.local', `${devProtocol}campus.local`] 
    : [`${devProtocol}localhost:3000`, `${devProtocol}127.0.0.1:3000`];

app.use(cors({
    origin: function (origin, callback) {
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
}));
app.use(express.json());
app.use('/uploads', express.static('uploads'));


// Debug middleware to log all requests
app.use((req, res, next) => {
    const sanitizedPath = req.path.replace(/[\r\n]/g, '');
    console.log(`${req.method} ${sanitizedPath}`);
    next();
});

// Database connection
if (process.env.NODE_ENV !== 'test') {
    mongoose.connect(process.env.MONGO_URI, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
    })
    .then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err));
}

// Routes
console.log('Registering routes...');
app.use('/api/auth', authRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/stats', statsRoutes);

// Test route (must come after other routes)
app.get('/api/test', (req, res) => {
    console.log('Test route hit');
    res.json({ message: 'Server is working!', timestamp: new Date().toISOString() });
});

// Direct test routes for stats (must come after other routes)
app.get('/api/test-complaint-stats', async (req, res) => {
    try {
        console.log('Testing complaint stats directly...');
        const Complaint = require('./models/Complaint');
        const totalComplaints = await Complaint.countDocuments();
        const resolvedComplaints = await Complaint.countDocuments({ status: 'resolved' });
        res.json({ total: totalComplaints, resolved: resolvedComplaints });
    } catch (error) {
        console.error('Direct test error:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/test-user-stats', async (req, res) => {
    try {
        console.log('Testing user stats directly...');
        const User = require('./models/User');
        const totalUsers = await User.countDocuments();
        res.json({ total: totalUsers });
    } catch (error) {
        console.error('Direct test error:', error);
        res.status(500).json({ error: error.message });
    }
});

// Debug route to show all registered routes
app.get('/api/debug/routes', (req, res) => {
    const routes = [];
    app._router.stack.forEach(middleware => {
        if (middleware.route) {
            routes.push({
                path: middleware.route.path,
                methods: Object.keys(middleware.route.methods)
            });
        } else if (middleware.name === 'router') {
            middleware.handle.stack.forEach(handler => {
                if (handler.route) {
                    routes.push({
                        path: handler.route.path,
                        methods: Object.keys(handler.route.methods)
                    });
                }
            });
        }
    });
    res.json({ routes });
});

// Export app for testing
module.exports = app;

// Start server only if not in test environment
if (process.env.NODE_ENV !== 'test') {
    app.listen(PORT, () => {
        console.log(`Server is running on port ${PORT}`);
        console.log('Available routes:');
        console.log('- GET /api/test');
        console.log('- GET /api/stats/complaints');
        console.log('- GET /api/stats/users');
        console.log('- GET /api/auth/stats');
        console.log('- GET /api/complaints/stats');
    });
}