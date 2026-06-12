const { Sequelize } = require('sequelize');

const DATABASE_URL = process.env.DATABASE_URL || 'postgres://medishift:medishift123@localhost:5432/medishift';

const sequelize = new Sequelize(DATABASE_URL, {
  dialect: 'postgres',
  logging: false,
  pool: { max: 5, min: 0, acquire: 30000, idle: 10000 }
});

const connectWithRetry = async (retries = 5, delay = 5000) => {
  for (let i = 1; i <= retries; i++) {
    try {
      await sequelize.authenticate();
      console.log(`[${new Date().toISOString()}] Database connected successfully`);
      return;
    } catch (error) {
      console.error(`[${new Date().toISOString()}] Database connection attempt ${i}/${retries} failed: ${error.message}`);
      if (i === retries) { console.error(`[${new Date().toISOString()}] All connection attempts failed. Exiting.`); process.exit(1); }
      await new Promise(r => setTimeout(r, delay));
    }
  }
};

module.exports = { sequelize, connectWithRetry };
