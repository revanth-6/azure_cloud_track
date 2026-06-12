const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const User = require('../models/user.model');

const JWT_SECRET = process.env.JWT_SECRET || 'default-jwt-secret';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';
const STAFF_SERVICE_URL = process.env.STAFF_SERVICE_URL || 'http://localhost:3002';

exports.login = async (req, res) => {
  try {
    let { email, password } = req.body;
    if (!email || !email.trim()) return res.status(400).json({ success: false, message: 'Email is required' });
    if (!password) return res.status(400).json({ success: false, message: 'Password is required' });
    email = email.trim().toLowerCase();
    if (!email.includes('@')) return res.status(400).json({ success: false, message: 'Invalid email format' });

    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(401).json({ success: false, message: 'Invalid email or password' });

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ success: false, message: 'Invalid email or password' });

    let staff_id = null;
    if (user.role === 'staff') {
      try {
        const r = await axios.get(`${STAFF_SERVICE_URL}/api/staff/by-user/${user.id}`, { timeout: 5000 });
        if (r.data.success) staff_id = r.data.data.id;
      } catch (e) {
        console.error(`[${new Date().toISOString()}] Failed to get staff_id: ${e.message}`);
      }
    }

    const token = jwt.sign({ user_id: user.id, staff_id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
    console.log(`[${new Date().toISOString()}] Login: ${user.email} (${user.role})`);
    return res.status(200).json({ success: true, data: { token, user: { user_id: user.id, staff_id, email: user.email, role: user.role } } });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Login error: ${error.message}`);
    if (error.name === 'SequelizeConnectionError') return res.status(503).json({ success: false, message: 'Service temporarily unavailable' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.verify = (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) return res.status(401).json({ success: false, message: 'No token provided' });
    if (!authHeader.startsWith('Bearer ')) return res.status(401).json({ success: false, message: 'Invalid token format. Use Bearer <token>' });
    const decoded = jwt.verify(authHeader.split(' ')[1], JWT_SECRET);
    return res.status(200).json({ success: true, data: decoded });
  } catch (error) {
    if (error.name === 'TokenExpiredError') return res.status(401).json({ success: false, message: 'Token has expired. Please login again.' });
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
};

exports.createUser = async (req, res) => {
  try {
    let { email, password, role } = req.body;
    if (!email || !email.trim()) return res.status(400).json({ success: false, message: 'Email is required' });
    if (!password) return res.status(400).json({ success: false, message: 'Password is required' });
    if (password.length < 6) return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    email = email.trim().toLowerCase();

    const existing = await User.findOne({ where: { email } });
    if (existing) return res.status(409).json({ success: false, message: 'Email already registered' });

    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({ email, password: hashed, role: role || 'staff' });
    console.log(`[${new Date().toISOString()}] User created: ${user.email}`);
    return res.status(201).json({ success: true, data: { user_id: user.id, email: user.email, role: user.role } });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Create user error: ${error.message}`);
    if (error.name === 'SequelizeUniqueConstraintError') return res.status(409).json({ success: false, message: 'Email already registered' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    await user.destroy();
    console.log(`[${new Date().toISOString()}] User deleted: ${user.email}`);
    return res.status(200).json({ success: true, data: { message: 'User deleted' } });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Delete user error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};
