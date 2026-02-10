const express = require('express');
const router = express.Router();
const AppConfig = require('../model/AppConfig');
const authenticate = require('../middleware/authMiddleware');

/**
 * Get public app configuration
 * GET /api/config
 * Public endpoint - no auth required
 */
router.get('/', async (req, res) => {
    try {
        const config = await AppConfig.getSingleton();

        // Return only public fields
        res.json({
            success: true,
            data: {
                adsEnabled: config.adsEnabled,
                maintenanceMode: config.maintenanceMode,
                minAppVersion: config.minAppVersion,
                features: config.features,
                announcement: config.announcement.enabled ? {
                    message: config.announcement.message,
                    type: config.announcement.type,
                    dismissible: config.announcement.dismissible
                } : null
            }
        });
    } catch (error) {
        console.error('Get config error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch configuration'
        });
    }
});

/**
 * Update app configuration
 * PUT /api/config
 * Admin only
 */
router.put('/', authenticate, authenticate.requireAdmin, async (req, res) => {
    try {
        const config = await AppConfig.getSingleton();

        const allowedUpdates = [
            'adsEnabled',
            'maintenanceMode',
            'minAppVersion',
            'features',
            'settings',
            'announcement'
        ];

        // Update only allowed fields
        allowedUpdates.forEach(field => {
            if (req.body[field] !== undefined) {
                config[field] = req.body[field];
            }
        });

        await config.save();

        res.json({
            success: true,
            data: config,
            message: 'Configuration updated successfully'
        });
    } catch (error) {
        console.error('Update config error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update configuration'
        });
    }
});

/**
 * Toggle ads
 * POST /api/config/toggle-ads
 * Admin only - quick toggle for ads
 */
router.post('/toggle-ads', authenticate, authenticate.requireAdmin, async (req, res) => {
    try {
        const config = await AppConfig.getSingleton();
        config.adsEnabled = !config.adsEnabled;
        await config.save();

        res.json({
            success: true,
            data: { adsEnabled: config.adsEnabled },
            message: `Ads ${config.adsEnabled ? 'enabled' : 'disabled'} globally`
        });
    } catch (error) {
        console.error('Toggle ads error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to toggle ads'
        });
    }
});

module.exports = router;
