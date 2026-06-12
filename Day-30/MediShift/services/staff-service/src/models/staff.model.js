const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const Department = require('./department.model');

const Staff = sequelize.define('Staff', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: false
  },
  department_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: Department, key: 'id' }
  }
}, {
  tableName: 'staff',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

Staff.belongsTo(Department, { foreignKey: 'department_id', as: 'department' });
Department.hasMany(Staff, { foreignKey: 'department_id', as: 'staff' });

module.exports = Staff;
