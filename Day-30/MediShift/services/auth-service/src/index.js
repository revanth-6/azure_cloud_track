const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const { sequelize, connectWithRetry } = require('./config/database');
const User = require('./models/user.model');
const authRoutes = require('./routes/auth.routes');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'medishift-auth-service', timestamp: new Date().toISOString() });
});

app.use('/api/auth', authRoutes);

const seedAdmin = async () => {
  try {
    const admin = await User.findOne({ where: { email: 'admin@medishift.com' } });
    if (!admin) {
      const hashed = await bcrypt.hash('admin123', 10);
      await User.create({ email: 'admin@medishift.com', password: hashed, role: 'admin' });
      console.log(`[${new Date().toISOString()}] Admin user seeded: admin@medishift.com`);
    } else {
      console.log(`[${new Date().toISOString()}] Admin already exists`);
    }
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Seed error: ${error.message}`);
  }
};

const start = async () => {
  await connectWithRetry();
  await sequelize.sync({ alter: true });
  await seedAdmin();
  const server = app.listen(PORT, () => {
    console.log(`[${new Date().toISOString()}] Auth service running on port ${PORT}`);
  });
  process.on('SIGTERM', () => { console.log(`[${new Date().toISOString()}] SIGTERM received`); server.close(() => process.exit(0)); });
  process.on('SIGINT', () => { console.log(`[${new Date().toISOString()}] SIGINT received`); server.close(() => process.exit(0)); });
};

start();
