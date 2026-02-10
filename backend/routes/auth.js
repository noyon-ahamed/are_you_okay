const express = require('express');
const router = express.Router();
const authService = require('../services/authService');
const authenticate = require('../middleware/authMiddleware');
const { formatResponse } = require('../utils/responseFormatter');
const User = require('../model/User');
const Subscription = require('../model/Subscription');

/**
 * Register new user
 * POST /api/auth/register
 */
router.post('/register', async (req, res) => {
    try {
        const { email, password, name, phone } = req.body;

        // Validation
        if (!email || !password || !name) {
            return res.status(400).json({
                success: false,
                error: 'Email, password, and name are required',
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                error: 'Password must be at least 6 characters',
            });
        }

        const result = await authService.register(email, password, name, phone);

        // Create free subscription for new user
        await Subscription.create({
            userId: result.user.id,
            plan: 'free',
        });

        res.status(201).json({
            success: true,
            data: result,
            message: 'Registration successful. Please check your email to verify your account.',
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(400).json({
            success: false,
            error: error.message || 'Registration failed',
        });
    }
});

/**
 * Login
 * POST /api/auth/login
 */
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Email and password are required',
            });
        }

        const result = await authService.login(email, password);

        res.json({
            success: true,
            data: result,
            message: 'Login successful',
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(401).json({
            success: false,
            error: error.message || 'Login failed',
        });
    }
});

/**
 * Verify email
 * GET /api/auth/verify-email/:token
 */
router.get('/verify-email/:token', async (req, res) => {
    try {
        const { token } = req.params;
        const result = await authService.verifyEmail(token);

        res.json({
            success: true,
            message: result.message,
        });
    } catch (error) {
        console.error('Email verification error:', error);
        res.status(400).json({
            success: false,
            error: error.message || 'Verification failed',
        });
    }
});

/**
 * Request password reset
 * POST /api/auth/forgot-password
 */
router.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                error: 'Email is required',
            });
        }

        const result = await authService.forgotPassword(email);

        res.json({
            success: true,
            message: result.message,
        });
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(400).json({
            success: false,
            error: error.message || 'Failed to send reset email',
        });
    }
});

/**
 * Reset password
 * POST /api/auth/reset-password
 */
router.post('/reset-password', async (req, res) => {
    try {
        const { token, password } = req.body;

        if (!token || !password) {
            return res.status(400).json({
                success: false,
                error: 'Token and new password are required',
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                error: 'Password must be at least 6 characters',
            });
        }

        const result = await authService.resetPassword(token, password);

        res.json({
            success: true,
            message: result.message,
        });
    } catch (error) {
        console.error('Password reset error:', error);
        res.status(400).json({
            success: false,
            error: error.message || 'Password reset failed',
        });
    }
});

/**
 * Get current user profile
 * GET /api/auth/profile
 */
router.get('/profile', authenticate, async (req, res) => {
    try {
        const user = await User.findById(req.user._id).select('-password');

        if (!user) {
            return res.status(404).json({ success: false, error: 'User not found' });
        }

        // Get subscription info
        const subscription = await Subscription.findOne({ userId: user._id });

        res.json({
            success: true,
            data: { user, subscription },
        });
    } catch (error) {
        console.error('Profile error:', error);
        res.status(500).json({ success: false, error: 'Failed to fetch profile' });
    }
});

/**
 * Update profile
 * PUT /api/auth/profile
 */
router.put('/profile', authenticate, async (req, res) => {
    try {
        const { name, phone, profilePicture } = req.body;

        const updateData = { updatedAt: new Date() };
        if (name) updateData.name = name;
        if (phone) updateData.phone = phone;
        if (profilePicture) updateData.profilePicture = profilePicture;

        const user = await User.findByIdAndUpdate(
            req.user._id,
            updateData,
            { new: true, runValidators: true }
        ).select('-password');

        res.json({
            success: true,
            data: { user },
            message: 'Profile updated successfully',
        });
    } catch (error) {
        console.error('Update Profile Error:', error);
        res.status(500).json({ success: false, error: 'Failed to update profile' });
    }
});

/**
 * Update location
 * POST /api/auth/update-location
 */
router.post('/update-location', authenticate, async (req, res) => {
    try {
        const { latitude, longitude } = req.body;

        if (!latitude || !longitude) {
            return res.status(400).json({ success: false, error: 'Latitude and longitude required' });
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
        ).select('-password');

        res.json({
            success: true,
            message: 'Location updated',
            data: { location: user.location },
        });
    } catch (error) {
        console.error('Update Location Error:', error);
        res.status(500).json({ success: false, error: 'Failed to update location' });
    }
});

/**
 * Update FCM token
 * POST /api/auth/fcm-token
 */
router.post('/fcm-token', authenticate, async (req, res) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({ success: false, error: 'FCM token required' });
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
        res.status(500).json({ success: false, error: 'Failed to update FCM token' });
    }
});

/**
 * Delete account
 * DELETE /api/auth/account
 */
router.delete('/account', authenticate, async (req, res) => {
    try {
        const userId = req.user._id;

        // Delete from MongoDB
        await User.findByIdAndDelete(userId);
        await Subscription.deleteMany({ userId });

        // Also delete related data
        const CheckIn = require('../model/CheckIn');
        const EmergencyContact = require('../model/EmergencyContact');
        const AIConversation = require('../model/AIConversation');
        const EmergencyAlert = require('../model/EmergencyAlert');

        await Promise.all([
            CheckIn.deleteMany({ userId }),
            EmergencyContact.deleteMany({ userId }),
            AIConversation.deleteMany({ userId }),
            EmergencyAlert.deleteMany({ userId }),
        ]);

        res.json({
            success: true,
            message: 'Account deleted successfully',
        });
    } catch (error) {
        console.error('Delete Account Error:', error);
        res.status(500).json({ success: false, error: 'Failed to delete account' });
    }
});

/**
 * Get app statistics (for user dashboard)
 * GET /api/auth/stats
 */
router.get('/stats', authenticate, async (req, res) => {
    try {
        const CheckIn = require('../model/CheckIn');
        const EmergencyAlert = require('../model/EmergencyAlert');

        const [totalCheckIns, totalAlerts, user] = await Promise.all([
            CheckIn.countDocuments({ userId: req.user._id }),
            EmergencyAlert.countDocuments({ userId: req.user._id }),
            User.findById(req.user._id),
        ]);

        res.json({
            success: true,
            data: {
                stats: {
                    totalCheckIns,
                    currentStreak: user.checkInStreak || 0,
                    totalAlerts,
                    accountAge: Math.floor(
                        (Date.now() - user.createdAt) / (1000 * 60 * 60 * 24)
                    ),
                    lastCheckIn: user.lastCheckIn,
                },
            },
        });
    } catch (error) {
        console.error('Stats Error:', error);
        res.status(500).json({ success: false, error: 'Failed to fetch stats' });
    }
});

module.exports = router;