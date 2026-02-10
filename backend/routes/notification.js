const express = require('express');
const router = express.Router();
const Notification = require('../model/Notification');
const protect = require('../middleware/authMiddleware');
const { formatResponse } = require('../utils/responseFormatter');

router.get('/', protect, async (req, res, next) => {
    try {
        const notifications = await Notification.find({ user: req.user.id }).sort({ createdAt: -1 }).limit(50);
        res.json(formatResponse(true, 'Notifications retrieved', notifications));
    } catch (error) {
        next(error);
    }
});

module.exports = router;
