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
  body('email').isString().notEmpty(),
  body('password').notEmpty(),
  authController.login
);

router.post('/forgot-password',
  body('email').isString().notEmpty(),
  authController.requestPasswordReset
);

router.post('/reset-password',
  body('token').isString().isLength({ min: 32 }),
  body('password').isLength({ min: 6 }),
  authController.resetPassword
);

router.post('/send-otp',
  body('identifier').isString().notEmpty(),
  body('method').isIn(['email', 'phone']),
  authController.sendOtp
);

router.post('/verify-otp',
  body('identifier').isString().notEmpty(),
  body('otp').isString().notEmpty(),
  authController.verifyOtp
);

router.post('/reset-password-with-otp',
  body('identifier').isString().notEmpty(),
  body('otp').isString().notEmpty(),
  body('password').isLength({ min: 6 }),
  authController.resetPasswordWithOtp
);

router.get('/me', authMiddleware, authController.getCurrentUser);

router.put('/profile',
  authMiddleware,
  body('first_name').optional().isString(),
  body('last_name').optional().isString(),
  body('email').optional().isEmail(),
  body('phone').optional().isString(),
  authController.updateProfile
);

router.post('/change-password',
  authMiddleware,
  body('current_password').isString().notEmpty(),
  body('new_password').isLength({ min: 6 }),
  authController.changePassword
);

module.exports = router;
