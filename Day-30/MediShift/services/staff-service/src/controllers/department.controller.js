const Department = require('../models/department.model');
const Staff = require('../models/staff.model');
const { Op } = require('sequelize');

exports.getAll = async (req, res) => {
  try {
    const departments = await Department.findAll({ order: [['name', 'ASC']] });
    return res.status(200).json({ success: true, data: departments });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get departments error: ${error.message}`);
    if (error.name === 'SequelizeConnectionError') return res.status(503).json({ success: false, message: 'Database unavailable' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.getById = async (req, res) => {
  try {
    const department = await Department.findByPk(req.params.id);
    if (!department) return res.status(404).json({ success: false, message: 'Department not found' });
    return res.status(200).json({ success: true, data: department });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get department error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.create = async (req, res) => {
  try {
    let { name } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ success: false, message: 'Department name is required' });
    name = name.trim();
    if (name.length < 2) return res.status(400).json({ success: false, message: 'Department name must be at least 2 characters' });
    if (name.length > 100) return res.status(400).json({ success: false, message: 'Department name cannot exceed 100 characters' });

    const existing = await Department.findOne({ where: { name: { [Op.iLike]: name } } });
    if (existing) return res.status(409).json({ success: false, message: 'Department with this name already exists' });

    const department = await Department.create({ name });
    console.log(`[${new Date().toISOString()}] Department created: ${name}`);
    return res.status(201).json({ success: true, data: department });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Create department error: ${error.message}`);
    if (error.name === 'SequelizeUniqueConstraintError') return res.status(409).json({ success: false, message: 'Department with this name already exists' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.update = async (req, res) => {
  try {
    let { name } = req.body;
    const department = await Department.findByPk(req.params.id);
    if (!department) return res.status(404).json({ success: false, message: 'Department not found' });
    if (!name || !name.trim()) return res.status(400).json({ success: false, message: 'Department name is required' });
    name = name.trim();
    if (name.length < 2) return res.status(400).json({ success: false, message: 'Department name must be at least 2 characters' });
    if (name.length > 100) return res.status(400).json({ success: false, message: 'Department name cannot exceed 100 characters' });

    const duplicate = await Department.findOne({ where: { name: { [Op.iLike]: name }, id: { [Op.ne]: req.params.id } } });
    if (duplicate) return res.status(409).json({ success: false, message: 'Department with this name already exists' });

    department.name = name;
    await department.save();
    console.log(`[${new Date().toISOString()}] Department updated: ${name}`);
    return res.status(200).json({ success: true, data: department });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Update department error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.remove = async (req, res) => {
  try {
    const department = await Department.findByPk(req.params.id);
    if (!department) return res.status(404).json({ success: false, message: 'Department not found' });

    const staffCount = await Staff.count({ where: { department_id: req.params.id } });
    if (staffCount > 0) return res.status(400).json({ success: false, message: `Cannot delete department. ${staffCount} staff member(s) assigned.` });

    await department.destroy();
    console.log(`[${new Date().toISOString()}] Department deleted: ${department.name}`);
    return res.status(200).json({ success: true, data: { message: 'Department deleted successfully' } });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Delete department error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};
