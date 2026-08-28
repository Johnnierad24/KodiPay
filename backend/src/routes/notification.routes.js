const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const notificationController = require('../controllers/notification.controller');
const validate = require('../middleware/validate');

router.get('/', notificationController.getNotifications);
router.put('/:id/read', notificationController.markAsRead);
router.put('/read-all', notificationController.markAllAsRead);
router.post('/test',
  body('title').trim().notEmpty().isLength({ max: 200 }),
  body('body').trim().notEmpty().isLength({ max: 1000 }),
  validate,
  notificationController.sendTestNotification
);
router.post('/rent-reminder',
  body('tenancy_id').isInt({ min: 1 }),
  validate,
  notificationController.sendRentReminder
);
router.post('/announcement',
  body('title').trim().notEmpty().isLength({ max: 200 }),
  body('message').trim().notEmpty().isLength({ max: 2000 }),
  body('property_id').isInt({ min: 1 }),
  validate,
  notificationController.sendAnnouncement
);

module.exports = router;
