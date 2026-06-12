const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Leave = sequelize.define('Leave', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  staff_id: {
    type: DataTypes.UUID,
    allowNull: false
  },
  from_date: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  to_date: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  reason: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'rejected'),
    allowNull: false,
    defaultValue: 'pending'
  },
  approved_by: {
    type: DataTypes.UUID,
    allowNull: true
  }
}, {
  tableName: 'leaves',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

module.exports = Leave;
