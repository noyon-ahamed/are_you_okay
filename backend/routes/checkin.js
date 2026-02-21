const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/authMiddleware');
const CheckIn = require('../model/CheckIn');
const User = require('../model/User');
const { sendNotification } = require('../config/firebase');

// Daily check-in
router.post('/', authenticate, async (req, res) => {
    try {
        const { location, status, note } = req.body;

        // Validate location
        if (!location || !location.latitude || !location.longitude) {
            return res.status(400).json({ error: 'Location is required' });
        }

        // Check if already checked in today
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const existingCheckIn = await CheckIn.findOne({
            user: req.user._id,
            checkInTime: { $gte: today },
        });

        if (existingCheckIn) {
            return res.status(400).json({
                error: 'Already checked in today',
                checkIn: existingCheckIn,
            });
        }

        // Create check-in
        const checkIn = await CheckIn.create({
            user: req.user._id,
            location: {
                latitude: location.latitude,
                longitude: location.longitude,
            },
            status: status || 'safe',
            notes: note || '',
        });

        // Update user's last check-in and streak
        const user = await User.findById(req.user._id);
        const lastCheckIn = user.lastCheckIn;

        let newStreak = user.checkInStreak || 0;

        // Calculate streak
        if (lastCheckIn) {
            const daysSinceLastCheckIn = Math.floor(
                (Date.now() - lastCheckIn.getTime()) / (1000 * 60 * 60 * 24)
            );

            if (daysSinceLastCheckIn === 1) {
                // Consecutive day
                newStreak += 1;
            } else if (daysSinceLastCheckIn > 1) {
                // Streak broken
                newStreak = 1;
            }
        } else {
            newStreak = 1;
        }

        // Update user
        await User.findByIdAndUpdate(req.user._id, {
            lastCheckIn: new Date(),
            checkInStreak: newStreak,
            missedCheckInCount: 0,
            location: {
                type: 'Point',
                coordinates: [location.longitude, location.latitude],
            },
            updatedAt: new Date(),
        });

        // Send real-time event via Socket.io
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${req.user._id}`).emit('checkin_success', {
                timestamp: checkIn.checkInTime,
                streak: newStreak,
                status: checkIn.status,
            });
        }

        // Send push notification for milestone streaks
        if (newStreak > 0 && newStreak % 7 === 0 && user.fcmToken) {
            await sendNotification(user.fcmToken, {
                title: '🎉 Streak Milestone!',
                body: `Amazing! You've maintained a ${newStreak}-day check-in streak!`,
            });
        }

        res.json({
            success: true,
            checkIn,
            streak: newStreak,
            message: 'Check-in successful!',
        });

    } catch (error) {
        console.error('Check-in Error:', error);
        res.status(500).json({ error: 'Check-in failed' });
    }
});

// Get check-in history
router.get('/history', authenticate, async (req, res) => {
    try {
        const { limit = 30, skip = 0 } = req.query;

        const checkIns = await CheckIn.find({ user: req.user._id })
            .sort({ checkInTime: -1 })
            .limit(parseInt(limit))
            .skip(parseInt(skip))
            .select('-__v');

        const total = await CheckIn.countDocuments({ user: req.user._id });

        res.json({
            success: true,
            checkIns,
            pagination: {
                total,
                limit: parseInt(limit),
                skip: parseInt(skip),
                hasMore: total > parseInt(skip) + parseInt(limit),
            },
        });

    } catch (error) {
        console.error('History Error:', error);
        res.status(500).json({ error: 'Failed to fetch history' });
    }
});

// Get current streak
router.get('/streak', authenticate, async (req, res) => {
    try {
        const user = await User.findById(req.user._id);

        res.json({
            success: true,
            streak: user.checkInStreak || 0,
            lastCheckIn: user.lastCheckIn,
            missedDays: user.missedCheckInCount || 0,
        });

    } catch (error) {
        console.error('Streak Error:', error);
        res.status(500).json({ error: 'Failed to fetch streak' });
    }
});

// Get check-in status (last check-in info)
router.get('/status', authenticate, async (req, res) => {
    try {
        const user = await User.findById(req.user._id);

        const lastCheckIn = await CheckIn.findOne({ user: req.user._id })
            .sort({ checkInTime: -1 });

        const hoursSinceLastCheckIn = user.lastCheckIn
            ? Math.floor((Date.now() - user.lastCheckIn.getTime()) / (1000 * 60 * 60))
            : null;

        // Check if user has already checked in TODAY
        let needsCheckIn = true;
        if (user.lastCheckIn) {
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            needsCheckIn = user.lastCheckIn < today;
        }

        res.json({
            success: true,
            status: {
                lastCheckIn: lastCheckIn,
                hoursSinceLastCheckIn,
                needsCheckIn,
                streak: user.checkInStreak || 0,
                isAtRisk: hoursSinceLastCheckIn !== null && hoursSinceLastCheckIn >= 72, // 3 days
            },
        });

    } catch (error) {
        console.error('Status Error:', error);
        res.status(500).json({ error: 'Failed to fetch status' });
    }
});

// Set reminder time (for local notifications - just store preference)
router.post('/reminder', authenticate, async (req, res) => {
    try {
        const { hour, minute } = req.body; // 24-hour format

        if (hour === undefined || minute === undefined) {
            return res.status(400).json({ error: 'Hour and minute required' });
        }

        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            return res.status(400).json({ error: 'Invalid time' });
        }

        // Store in user settings (you can add this field to User model)
        await User.findByIdAndUpdate(req.user._id, {
            'settings.reminderTime': { hour, minute },
            updatedAt: new Date(),
        });

        res.json({
            success: true,
            message: 'Reminder time set',
            reminderTime: { hour, minute },
        });

    } catch (error) {
        console.error('Reminder Error:', error);
        res.status(500).json({ error: 'Failed to set reminder' });
    }
});

// Get monthly calendar (for UI calendar view)
router.get('/calendar/:year/:month', authenticate, async (req, res) => {
    try {
        const { year, month } = req.params;

        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0, 23, 59, 59);

        const checkIns = await CheckIn.find({
            user: req.user._id,
            checkInTime: {
                $gte: startDate,
                $lte: endDate,
            },
        }).select('checkInTime status');

        // Group by date
        const calendar = {};
        checkIns.forEach(checkIn => {
            const date = checkIn.checkInTime.toISOString().split('T')[0];
            calendar[date] = {
                status: checkIn.status,
                timestamp: checkIn.checkInTime,
            };
        });

        res.json({
            success: true,
            calendar,
            stats: {
                totalDays: checkIns.length,
                month: parseInt(month),
                year: parseInt(year),
            },
        });

    } catch (error) {
        console.error('Calendar Error:', error);
        res.status(500).json({ error: 'Failed to fetch calendar' });
    }
});

module.exports = router;