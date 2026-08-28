const { validationResult } = require('express-validator');

/**
 * Shared validation-result checker. Place as the last middleware before the
 * controller in any route that uses express-validator rules.
 *
 * Usage:
 *   router.post('/', body('name').notEmpty(), validate, controller.create);
 */
module.exports = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array().map((e) => ({ field: e.path, message: e.msg })),
    });
  }
  next();
};
