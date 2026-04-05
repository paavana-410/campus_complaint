import axios from 'axios';

export const API_BASE_URL =
  process.env.REACT_APP_API_URL || '';

const API_URL = `${API_BASE_URL}/api/auth/`;

const register = async (userData) => {
  const response = await axios.post(`${API_URL}register`, userData);
  return response.data;
};

const login = async (userData) => {
  const response = await axios.post(`${API_URL}login`, userData);
  return response.data;
};

export default {
  register,
  login,
};
