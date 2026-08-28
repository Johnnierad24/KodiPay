const { rateLimit } = require('express-rate-limit');

/** Stricter limiter for write-heavy endpoints (payments, tenancies, etc.). */
const writeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
});

/** Limiter for resource creation (properties, units, maintenance). */
const createLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
});

module.exports = { writeLimiter, createLimiter };
