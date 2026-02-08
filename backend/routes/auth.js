const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/authMiddleware');
const User = require('../models/User');
const Subscription = require('../models/Subscription');
const { admin } = require('../config/firebase');

// Register/Login (handled by Firebase, but we sync to MongoDB)
router.post('/sync', authenticate, async (req, res) => {
    try {
        const { name, email, phone, profilePicture, fcmToken } = req.body;

        // User already created in middleware, just update if needed
        const user = await User.findByIdAndUpdate(
            req.user._id,
            {
                name: name || req.user.name,
                email: email || req.user.email,
                phone: phone || req.user.phone,
                profilePicture: profilePicture || req.user.profilePicture,
                fcmToken: fcmToken || req.user.fcmToken,
                updatedAt: new Date(),
            },
            { new: true }
        );

        // Ensure user has a subscription
        let subscription = await Subscription.findOne({ userId: user._id });
        if (!subscription) {
            subscription = await Subscription.create({
                userId: user._id,
                plan: 'free',
            });
        }

        res.json({
            success: true,
            user,
            subscription,
            message: 'User synced successfully',
        });

    } catch (error) {
        console.error('Sync Error:', error);
        res.status(500).json({ error: 'Failed to sync user' });
    }
});

// Get user profile
router.get('/profile', authenticate, async (req, res) => {
    try {
        const user = await User.findById(req.user._id).select('-__v');

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Get subscription info
        const subscription = await Subscription.findOne({ userId: user._id });

        res.json({
            success: true,
            user,
            subscription,
        });

    } catch (error) {
        console.error('Profile Error:', error);
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
});

// Update profile
router.put('/profile', authenticate, async (req, res) => {
    try {
        const { name, phone, profilePicture, medicalInfo } = req.body;

        const updateData = {
            updatedAt: new Date(),
        };

        if (name) updateData.name = name;
        if (phone) updateData.phone = phone;
        if (profilePicture) updateData.profilePicture = profilePicture;
        if (medicalInfo) updateData.medicalInfo = medicalInfo;

        const user = await User.findByIdAndUpdate(
            req.user._id,
            updateData,
            { new: true, runValidators: true }
        );

        res.json({
            success: true,
            user,
            message: 'Profile updated successfully',
        });

    } catch (error) {
        console.error('Update Profile Error:', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

// Update location
router.post('/update-location', authenticate, async (req, res) => {
    try {
        const { latitude, longitude } = req.body;

        if (!latitude || !longitude) {
            return res.status(400).json({ error: 'Latitude and longitude required' });
        }

        const user = await User.findByIdAndUpdate(
            req.user._id,
            {
                location: {
                    type: 'Point',
                    coordinates: [longitude, latitude],
                },
                updatedAt: new Date(),
            },
            { new: true }
        );

        res.json({
            success: true,
            message: 'Location updated',
            location: user.location,
        });

    } catch (error) {
        console.error('Update Location Error:', error);
        res.status(500).json({ error: 'Failed to update location' });
    }
});

// Update FCM token
router.post('/fcm-token', authenticate, async (req, res) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({ error: 'FCM token required' });
        }

        await User.findByIdAndUpdate(req.user._id, {
            fcmToken: token,
            updatedAt: new Date(),
        });

        res.json({
            success: true,
            message: 'FCM token updated',
        });

    } catch (error) {
        console.error('FCM Token Error:', error);
        res.status(500).json({ error: 'Failed to update FCM token' });
    }
});

// Verify phone number (send OTP)
router.post('/verify-phone/send', authenticate, async (req, res) => {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({ error: 'Phone number required' });
        }

        // Use Firebase phone verification
        // Note: Actual verification happens on client side
        // This endpoint is just for logging/tracking

        res.json({
            success: true,
            message: 'OTP sent to ' + phoneNumber,
        });

    } catch (error) {
        console.error('Send OTP Error:', error);
        res.status(500).json({ error: 'Failed to send OTP' });
    }
});

// Delete account
router.delete('/account', authenticate, async (req, res) => {
    try {
        const userId = req.user._id;
        const firebaseUid = req.user.firebaseUid;

        // Delete from MongoDB
        await User.findByIdAndDelete(userId);
        await Subscription.deleteMany({ userId });

        // Also delete related data
        const CheckIn = require('../models/CheckIn');
        const EmergencyContact = require('../models/EmergencyContact');
        const AIConversation = require('../models/AIConversation');
        const EmergencyAlert = require('../models/EmergencyAlert');

        await Promise.all([
            CheckIn.deleteMany({ userId }),
            EmergencyContact.deleteMany({ userId }),
            AIConversation.deleteMany({ userId }),
            EmergencyAlert.deleteMany({ userId }),
        ]);

        // Delete from Firebase
        const { deleteUser } = require('../config/firebase');
        await deleteUser(firebaseUid);

        res.json({
            success: true,
            message: 'Account deleted successfully',
        });

    } catch (error) {
        console.error('Delete Account Error:', error);
        res.status(500).json({ error: 'Failed to delete account' });
    }
});

// Get app statistics (for user dashboard)
router.get('/stats', authenticate, async (req, res) => {
    try {
        const CheckIn = require('../models/CheckIn');
        const EmergencyAlert = require('../models/EmergencyAlert');

        const [totalCheckIns, totalAlerts, user] = await Promise.all([
            CheckIn.countDocuments({ userId: req.user._id }),
            EmergencyAlert.countDocuments({ userId: req.user._id }),
            User.findById(req.user._id),
        ]);

        res.json({
            success: true,
            stats: {
                totalCheckIns,
                currentStreak: user.checkInStreak || 0,
                totalAlerts,
                accountAge: Math.floor(
                    (Date.now() - user.createdAt) / (1000 * 60 * 60 * 24)
                ), // days
                lastCheckIn: user.lastCheckIn,
            },
        });

    } catch (error) {
        console.error('Stats Error:', error);
        res.status(500).json({ error: 'Failed to fetch stats' });
    }
});

module.exports = router;