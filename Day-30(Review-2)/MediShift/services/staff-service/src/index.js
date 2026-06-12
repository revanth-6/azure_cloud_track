const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const { sequelize, connectWithRetry } = require('./config/database');
require('./models/department.model');
require('./models/staff.model');
const departmentRoutes = require('./routes/department.routes');
const staffRoutes = require('./routes/staff.routes');

const app = express();
const PORT = process.env.PORT || 3002;

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'medishift-staff-service', timestamp: new Date().toISOString() });
});

app.use('/api/departments', departmentRoutes);
app.use('/api/staff', staffRoutes);

const start = async () => {
  await connectWithRetry();
  await sequelize.sync({ alter: true });
  const server = app.listen(PORT, () => {
    console.log(`[${new Date().toISOString()}] Staff service running on port ${PORT}`);
  });
  process.on('SIGTERM', () => { console.log(`[${new Date().toISOString()}] SIGTERM received`); server.close(() => process.exit(0)); });
  process.on('SIGINT', () => { console.log(`[${new Date().toISOString()}] SIGINT received`); server.close(() => process.exit(0)); });
};

start();
