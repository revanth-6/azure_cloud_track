const express = require('express');
const router = express.Router();
const c = require('../controllers/department.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

router.get('/', authenticate, isAdmin, c.getAll);
router.get('/:id', authenticate, isAdmin, c.getById);
router.post('/', authenticate, isAdmin, c.create);
router.put('/:id', authenticate, isAdmin, c.update);
router.delete('/:id', authenticate, isAdmin, c.remove);

module.exports = router;
