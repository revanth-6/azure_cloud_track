import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || '';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (!error.response) {
      if (error.code === 'ECONNABORTED') {
        error.message = 'Request timed out. Please try again.';
      } else {
        error.message = 'Network error. Please check your connection.';
      }
      return Promise.reject(error);
    }

    if (error.response.status === 401) {
      const message = error.response.data?.message || '';
      const isAuthError =
        message.toLowerCase().includes('expired') ||
        message.toLowerCase().includes('invalid token') ||
        message.toLowerCase().includes('no token') ||
        message.toLowerCase().includes('please login again');

      if (isAuthError) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/login';
      }
    }

    return Promise.reject(error);
  }
);

export default api;
