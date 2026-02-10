const express = require('express');
const router = express.Router();
const User = require('../model/User');
const CheckIn = require('../model/CheckIn');
const protect = require('../middleware/authMiddleware'); // Add admin middleware if available
const { formatResponse } = require('../utils/responseFormatter');

// Simple middleware to check if user is admin
const adminOnly = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(403).json(formatResponse(false, 'Not authorized as admin'));
    }
};

router.get('/users', protect, adminOnly, async (req, res, next) => {
    try {
        const users = await User.find().select('-password');
        res.json(formatResponse(true, 'All users retrieved', users));
    } catch (error) {
        next(error);
    }
});

router.get('/checkins', protect, adminOnly, async (req, res, next) => {
    try {
        const checkins = await CheckIn.find().populate('user', 'name email');
        res.json(formatResponse(true, 'All checkins retrieved', checkins));
    } catch (error) {
        next(error);
    }
});

module.exports = router;
