const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'default-jwt-secret';

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ success: false, message: 'No token provided' });
  if (!authHeader.startsWith('Bearer ')) return res.status(401).json({ success: false, message: 'Invalid token format. Use Bearer <token>' });
  try {
    const decoded = jwt.verify(authHeader.split(' ')[1], JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') return res.status(401).json({ success: false, message: 'Token has expired. Please login again.' });
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
};

const isAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') return res.status(403).json({ success: false, message: 'Admin access required' });
  next();
};

const isStaff = (req, res, next) => {
  if (req.user.role !== 'staff') return res.status(403).json({ success: false, message: 'Staff access required' });
  next();
};

module.exports = { authenticate, isAdmin, isStaff };
