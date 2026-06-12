const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

router.post('/login', authController.login);
router.get('/verify', authController.verify);
router.post('/create-user', authenticate, isAdmin, authController.createUser);
router.delete('/delete-user/:userId', authController.deleteUser);

module.exports = router;
