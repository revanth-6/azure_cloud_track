const express = require('express');
const router = express.Router();
const c = require('../controllers/staff.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// Internal (service-to-service — no auth)
router.get('/by-user/:userId', c.getByUserId);

// Protected routes
router.get('/', authenticate, isAdmin, c.getAll);
router.post('/', authenticate, isAdmin, c.create);
router.get('/:id', authenticate, c.getById);
router.put('/:id', authenticate, isAdmin, c.update);
router.delete('/:id', authenticate, isAdmin, c.remove);

module.exports = router;
