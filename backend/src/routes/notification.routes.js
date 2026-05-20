const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');

router.get('/', notificationController.getNotifications);
router.put('/:id/read', notificationController.markAsRead);
router.put('/read-all', notificationController.markAllAsRead);
router.post('/test', notificationController.sendTestNotification);
router.post('/rent-reminder', notificationController.sendRentReminder);
router.post('/announcement', notificationController.sendAnnouncement);

module.exports = router;
