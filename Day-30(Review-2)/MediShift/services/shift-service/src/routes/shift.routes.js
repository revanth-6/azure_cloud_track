const express = require('express');
const router = express.Router();
const c = require('../controllers/shift.controller');
const { authenticate, isAdmin, isStaff } = require('../middleware/auth.middleware');

// Internal (service-to-service — no auth, BEFORE /:id)
router.get('/check-dates', c.checkDates);
router.put('/cancel-by-leave', c.cancelByLeave);

// Named routes (BEFORE /:id)
router.get('/my-shifts', authenticate, isStaff, c.getMyShifts);
router.get('/staff/:staffId', authenticate, c.getByStaffId);

// Base routes
router.get('/', authenticate, isAdmin, c.getAll);
router.post('/', authenticate, isAdmin, c.create);

// Parameterized routes (LAST)
router.put('/:id', authenticate, isAdmin, c.update);
router.delete('/:id', authenticate, isAdmin, c.remove);

module.exports = router;
