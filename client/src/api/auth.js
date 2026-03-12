// filepath: smart-campus-complaint-system/client/src/api/auth.js

import axios from 'axios';

// API base URL (uses env variable if available)
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

const API_URL = `${API_BASE_URL}/api/auth/`;

// Register user
const register = async (userData) => {
    const response = await axios.post(`${API_URL}register`, userData);
    return response.data;
};

// Login user
const login = async (userData) => {
    const response = await axios.post(`${API_URL}login`, userData);
    return response.data;
};

// Export functions
export default {
    register,
    login,
};