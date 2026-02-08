const Subscription = require('../models/Subscription');
const UsageLog = require('../models/UsageLog');
const { FREE_LIMITS, PREMIUM_LIMITS } = require('../config/constants');

// Check if user can use a specific feature
const checkFeatureAccess = (feature) => {
    return async (req, res, next) => {
        try {
            // Get subscription
            let subscription = await Subscription.findOne({ userId: req.user._id });

            if (!subscription) {
                // Create free subscription if doesn't exist
                subscription = await Subscription.create({
                    userId: req.user._id,
                    plan: 'free',
                });
            }

            // Reset monthly usage if needed
            await resetMonthlyUsageIfNeeded(subscription);

            // Get limits based on plan
            const limits = subscription.plan === 'premium' ? PREMIUM_LIMITS : FREE_LIMITS;
            const featureLimit = limits[feature];

            // Check if feature is unlimited (-1)
            if (featureLimit === -1) {
                req.subscription = subscription;
                return next();
            }

            // Get current usage for this month
            const currentUsage = await getCurrentMonthUsage(req.user._id, feature);

            // Check if limit exceeded
            if (currentUsage >= featureLimit) {
                return res.status(403).json({
                    error: 'Usage limit exceeded',
                    feature,
                    plan: subscription.plan,
                    limit: featureLimit,
                    used: currentUsage,
                    upgradeRequired: subscription.plan === 'free',
                    message: subscription.plan === 'free'
                        ? `You've used ${currentUsage}/${featureLimit} ${getFeatureName(feature)} this month. Upgrade to Premium for unlimited access!`
                        : `You've reached your monthly limit of ${featureLimit} ${getFeatureName(feature)}.`,
                });
            }

            // Attach subscription to request
            req.subscription = subscription;
            req.featureUsage = {
                limit: featureLimit,
                used: currentUsage,
                remaining: featureLimit - currentUsage,
            };

            next();

        } catch (error) {
            console.error('Subscription Middleware Error:', error);
            res.status(500).json({
                error: 'Failed to check subscription',
                message: error.message
            });
        }
    };
};

// Log feature usage
const logUsage = (feature, metadata = {}) => {
    return async (req, res, next) => {
        try {
            const subscription = await Subscription.findOne({ userId: req.user._id });

            // Create usage log
            await UsageLog.create({
                userId: req.user._id,
                feature,
                subscriptionPlan: subscription?.plan || 'free',
                metadata,
                status: 'success',
                timestamp: new Date(),
            });

            // Update subscription usage count (optional, for quick stats)
            if (subscription && subscription.usageLimits[feature]) {
                subscription.usageLimits[feature].used += 1;
                await subscription.save();
            }

            next();

        } catch (error) {
            console.error('Usage Logging Error:', error);
            // Don't fail the request, just log the error
            next();
        }
    };
};

// Premium-only feature guard
const requirePremium = async (req, res, next) => {
    try {
        const subscription = await Subscription.findOne({ userId: req.user._id });

        if (!subscription || subscription.plan !== 'premium') {
            return res.status(403).json({
                error: 'Premium subscription required',
                message: 'This feature is only available for Premium users',
                upgradeRequired: true,
                currentPlan: subscription?.plan || 'free',
            });
        }

        // Check if subscription is expired
        if (subscription.expiryDate && subscription.expiryDate < new Date()) {
            subscription.plan = 'free';
            subscription.status = 'expired';
            await subscription.save();

            return res.status(403).json({
                error: 'Subscription expired',
                message: 'Your Premium subscription has expired. Please renew to continue.',
                upgradeRequired: true,
            });
        }

        req.subscription = subscription;
        next();

    } catch (error) {
        console.error('Premium Check Error:', error);
        res.status(500).json({ error: 'Failed to verify subscription' });
    }
};

// Helper: Reset usage if new month
const resetMonthlyUsageIfNeeded = async (subscription) => {
    const now = new Date();
    const lastReset = new Date(subscription.lastResetDate);

    // Check if month or year changed
    if (now.getMonth() !== lastReset.getMonth() ||
        now.getFullYear() !== lastReset.getFullYear()) {

        // Reset all usage counters
        Object.keys(subscription.usageLimits).forEach(key => {
            subscription.usageLimits[key].used = 0;
        });

        subscription.lastResetDate = now;
        await subscription.save();

        console.log(`✅ Monthly usage reset for user ${subscription.userId}`);
    }
};

// Helper: Get current month usage from logs
const getCurrentMonthUsage = async (userId, feature) => {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const count = await UsageLog.countDocuments({
        userId,
        feature,
        timestamp: { $gte: startOfMonth },
        status: 'success',
    });

    return count;
};

// Helper: Get user-friendly feature name
const getFeatureName = (feature) => {
    const names = {
        AI_CONVERSATIONS: 'AI conversations',
        AI_VOICE_CALLS: 'AI voice calls',
        SMS_ALERTS: 'SMS alerts',
        VOICE_CALL_MINUTES: 'voice call minutes',
    };
    return names[feature] || feature;
};

// Export middleware
module.exports = {
    checkFeatureAccess,
    logUsage,
    requirePremium,
};