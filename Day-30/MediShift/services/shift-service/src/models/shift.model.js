const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Shift = sequelize.define('Shift', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  staff_id: {
    type: DataTypes.UUID,
    allowNull: false
  },
  shift_date: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  start_time: {
    type: DataTypes.TIME,
    allowNull: false
  },
  end_time: {
    type: DataTypes.TIME,
    allowNull: false
  },
  shift_type: {
    type: DataTypes.ENUM('morning', 'afternoon', 'night'),
    allowNull: false
  }
}, {
  tableName: 'shifts',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

module.exports = Shift;
