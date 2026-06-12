const express = require('express');
const router = express.Router();
const c = require('../controllers/leave.controller');
const { authenticate, isAdmin, isStaff } = require('../middleware/auth.middleware');

// Internal (service-to-service — no auth, BEFORE /:id)
router.get('/check-approved', c.checkApprovedLeave);

// Named routes (BEFORE /:id)
router.get('/my-leaves', authenticate, isStaff, c.getMyLeaves);

// Staff route
router.post('/', authenticate, isStaff, c.apply);

// Admin routes
router.get('/', authenticate, isAdmin, c.getAll);

// Parameterized routes (LAST)
router.put('/:id', authenticate, isAdmin, c.updateStatus);

module.exports = router;
