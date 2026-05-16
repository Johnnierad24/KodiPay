const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.post('/register',
  body('email').isEmail(),
  body('password').isLength({ min: 6 }),
  body('first_name').notEmpty(),
  body('last_name').notEmpty(),
  body('role').isIn(['landlord', 'tenant', 'caretaker', 'agent']),
  authController.register
);

router.post('/login',
  body('email').isEmail(),
  body('password').notEmpty(),
  authController.login
);

router.get('/me', authMiddleware, authController.getCurrentUser);

module.exports = router;
