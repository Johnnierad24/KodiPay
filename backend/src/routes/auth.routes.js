const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { rateLimit } = require('express-rate-limit');
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { validateName, validateEmail, validatePhone } = require('../utils/validators');

// Throttle credential-guessing on sensitive auth endpoints (brute-force / OTP abuse).
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 attempts per IP per window
  message: { error: 'Too many attempts from this IP, please try again after 15 minutes' },
  standardHeaders: true,
  legacyHeaders: false,
});

router.post('/register',
  authLimiter,
  validateEmail('email'),
  body('password').isLength({ min: 6 }),
  validateName('first_name'),
  validateName('last_name'),
  body('role').isIn(['landlord', 'tenant', 'caretaker', 'agent']),
  validatePhone('phone'),
  authController.register
);

router.post('/login',
  authLimiter,
  body('email').isString().notEmpty(),
  body('password').notEmpty(),
  authController.login
);

router.post('/forgot-password',
  authLimiter,
  body('email').isString().notEmpty(),
  authController.requestPasswordReset
);

router.post('/reset-password',
  authLimiter,
  body('token').isString().isLength({ min: 32 }),
  body('password').isLength({ min: 6 }),
  authController.resetPassword
);

router.post('/send-otp',
  authLimiter,
  body('identifier').isString().notEmpty(),
  body('method').isIn(['email', 'phone']),
  authController.sendOtp
);

router.post('/verify-otp',
  authLimiter,
  body('identifier').isString().notEmpty(),
  body('otp').isString().notEmpty(),
  authController.verifyOtp
);

router.post('/reset-password-with-otp',
  authLimiter,
  body('identifier').isString().notEmpty(),
  body('otp').isString().notEmpty(),
  body('password').isLength({ min: 6 }),
  authController.resetPasswordWithOtp
);

router.get('/me', authMiddleware, authController.getCurrentUser);

router.put('/profile',
  authMiddleware,
  validateName('first_name', { optional: true }),
  validateName('last_name', { optional: true }),
  validateEmail('email', { optional: true }),
  validatePhone('phone'),
  authController.updateProfile
);

router.post('/change-password',
  authMiddleware,
  body('current_password').isString().notEmpty(),
  body('new_password').isLength({ min: 6 }),
  authController.changePassword
);

module.exports = router;
