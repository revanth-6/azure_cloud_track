const axios = require('axios');
const Staff = require('../models/staff.model');
const Department = require('../models/department.model');

const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://localhost:3001';
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const phoneRegex = /^[0-9\s+\-()]{7,15}$/;

exports.getAll = async (req, res) => {
  try {
    const staff = await Staff.findAll({ include: [{ model: Department, as: 'department' }], order: [['name', 'ASC']] });
    return res.status(200).json({ success: true, data: staff });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get staff error: ${error.message}`);
    if (error.name === 'SequelizeConnectionError') return res.status(503).json({ success: false, message: 'Database unavailable' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.getById = async (req, res) => {
  try {
    const staff = await Staff.findByPk(req.params.id, { include: [{ model: Department, as: 'department' }] });
    if (!staff) return res.status(404).json({ success: false, message: 'Staff member not found' });
    return res.status(200).json({ success: true, data: staff });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get staff by ID error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.getByUserId = async (req, res) => {
  try {
    const staff = await Staff.findOne({ where: { user_id: req.params.userId }, include: [{ model: Department, as: 'department' }] });
    if (!staff) return res.status(404).json({ success: false, message: 'Staff not found' });
    return res.status(200).json({ success: true, data: staff });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get staff by user ID error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.create = async (req, res) => {
  try {
    let { name, email, phone, department_id, password } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ success: false, message: 'Name is required' });
    name = name.trim();
    if (name.length < 2) return res.status(400).json({ success: false, message: 'Name must be at least 2 characters' });
    if (name.length > 100) return res.status(400).json({ success: false, message: 'Name cannot exceed 100 characters' });
    if (!email || !email.trim()) return res.status(400).json({ success: false, message: 'Email is required' });
    email = email.trim().toLowerCase();
    if (!emailRegex.test(email)) return res.status(400).json({ success: false, message: 'Invalid email format' });

    const existingStaff = await Staff.findOne({ where: { email } });
    if (existingStaff) return res.status(409).json({ success: false, message: 'A staff member with this email already exists' });

    if (!phone || !phone.trim()) return res.status(400).json({ success: false, message: 'Phone number is required' });
    phone = phone.trim();
    if (!phoneRegex.test(phone)) return res.status(400).json({ success: false, message: 'Invalid phone number format' });

    if (!department_id) return res.status(400).json({ success: false, message: 'Department is required' });
    const department = await Department.findByPk(department_id);
    if (!department) return res.status(404).json({ success: false, message: 'Selected department does not exist' });

    if (!password) return res.status(400).json({ success: false, message: 'Password is required' });
    if (password.length < 6) return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });

    let authUserId;
    try {
      const authResponse = await axios.post(`${AUTH_SERVICE_URL}/api/auth/create-user`, { email, password, role: 'staff' }, { headers: { Authorization: req.headers.authorization }, timeout: 5000 });
      if (!authResponse.data.success) return res.status(400).json({ success: false, message: 'Failed to create user credentials' });
      authUserId = authResponse.data.data.user_id;
    } catch (error) {
      console.error(`[${new Date().toISOString()}] Auth service call failed: ${error.message}`);
      if (error.response && error.response.status === 409) return res.status(409).json({ success: false, message: 'Email already registered' });
      return res.status(503).json({ success: false, message: 'Unable to create credentials. Please try again later.' });
    }

    let staff;
    try {
      staff = await Staff.create({ user_id: authUserId, name, email, phone, department_id });
    } catch (error) {
      console.error(`[${new Date().toISOString()}] Staff creation failed, rolling back auth: ${error.message}`);
      try { await axios.delete(`${AUTH_SERVICE_URL}/api/auth/delete-user/${authUserId}`, { timeout: 5000 }); } catch (e) { console.error(`[${new Date().toISOString()}] Rollback failed: ${e.message}`); }
      return res.status(500).json({ success: false, message: 'Failed to create staff profile' });
    }

    const staffWithDept = await Staff.findByPk(staff.id, { include: [{ model: Department, as: 'department' }] });
    console.log(`[${new Date().toISOString()}] Staff created: ${name} (${email})`);
    return res.status(201).json({ success: true, data: staffWithDept });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Create staff error: ${error.message}`);
    if (error.name === 'SequelizeUniqueConstraintError') return res.status(409).json({ success: false, message: 'A staff member with this email already exists' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.update = async (req, res) => {
  try {
    let { name, phone, department_id } = req.body;
    const staff = await Staff.findByPk(req.params.id);
    if (!staff) return res.status(404).json({ success: false, message: 'Staff member not found' });

    if (name !== undefined) {
      name = name.trim();
      if (name.length < 2) return res.status(400).json({ success: false, message: 'Name must be at least 2 characters' });
      staff.name = name;
    }
    if (phone !== undefined) {
      phone = phone.trim();
      if (!phoneRegex.test(phone)) return res.status(400).json({ success: false, message: 'Invalid phone number format' });
      staff.phone = phone;
    }
    if (department_id) {
      const dept = await Department.findByPk(department_id);
      if (!dept) return res.status(404).json({ success: false, message: 'Department not found' });
      staff.department_id = department_id;
    }

    await staff.save();
    const updated = await Staff.findByPk(req.params.id, { include: [{ model: Department, as: 'department' }] });
    console.log(`[${new Date().toISOString()}] Staff updated: ${staff.name}`);
    return res.status(200).json({ success: true, data: updated });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Update staff error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.remove = async (req, res) => {
  try {
    const staff = await Staff.findByPk(req.params.id);
    if (!staff) return res.status(404).json({ success: false, message: 'Staff member not found' });
    const userId = staff.user_id;
    await staff.destroy();
    try { await axios.delete(`${AUTH_SERVICE_URL}/api/auth/delete-user/${userId}`, { timeout: 5000 }); } catch (e) { console.error(`[${new Date().toISOString()}] Failed to delete auth user: ${e.message}`); }
    console.log(`[${new Date().toISOString()}] Staff deleted: ${staff.name}`);
    return res.status(200).json({ success: true, data: { message: 'Staff deleted successfully' } });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Delete staff error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};
