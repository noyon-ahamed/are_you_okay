const cron = require('node-cron');
const Subscription = require('../model/Subscription');
const User = require('../model/User');
const { sendNotification } = require('../config/firebase');
const { logger } = require('../middleware/logger');

// Check for expired subscriptions
const checkExpiredSubscriptions = async () => {
    try {
        logger.info('🔍 Checking for expired subscriptions...');

        const now = new Date();

        // Find active premium subscriptions that have expired
        const expiredSubscriptions = await Subscription.find({
            plan: 'premium',
            status: 'active',
            expiryDate: { $lt: now },
        }).populate('userId', 'name email fcmToken');

        if (expiredSubscriptions.length === 0) {
            logger.info('No expired subscriptions found');
            return;
        }

        logger.info(`Found ${expiredSubscriptions.length} expired subscription(s)`);

        for (const subscription of expiredSubscriptions) {
            try {
                // Downgrade to free plan
                subscription.plan = 'free';
                subscription.status = 'expired';

                // Reset to free limits
                subscription.usageLimits = {
                    aiConversations: { used: 0, limit: 5 },
                    aiVoiceCalls: { used: 0, limit: 0 },
                    smsSent: { used: 0, limit: 5 },
                    voiceCallMinutes: { used: 0, limit: 0 },
                };

                await subscription.save();

                // Send notification to user
                const user = subscription.userId;

                if (user && user.fcmToken) {
                    await sendNotification(user.fcmToken, {
                        title: '⚠️ Subscription Expired',
                        body: 'Your Premium subscription has expired. Renew now to continue enjoying unlimited features!',
                    });
                }

                logger.info(`✅ Downgraded user ${user?._id} to free plan`);

            } catch (error) {
                logger.error(`Error processing subscription ${subscription._id}:`, error);
            }
        }

        logger.info('✅ Subscription expiry check completed');

    } catch (error) {
        logger.error('Subscription expiry check error:', error);
    }
};

// Check for subscriptions expiring soon (7 days warning)
const checkExpiringSubscriptions = async () => {
    try {
        logger.info('🔍 Checking for expiring subscriptions...');

        const now = new Date();
        const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

        // Find subscriptions expiring in next 7 days
        const expiringSubscriptions = await Subscription.find({
            plan: 'premium',
            status: 'active',
            expiryDate: {
                $gte: now,
                $lte: sevenDaysFromNow,
            },
        }).populate('userId', 'name email fcmToken');

        if (expiringSubscriptions.length === 0) {
            logger.info('No subscriptions expiring soon');
            return;
        }

        logger.info(`Found ${expiringSubscriptions.length} subscription(s) expiring soon`);

        for (const subscription of expiringSubscriptions) {
            try {
                const user = subscription.userId;
                const daysLeft = Math.ceil(
                    (subscription.expiryDate - now) / (1000 * 60 * 60 * 24)
                );

                if (user && user.fcmToken) {
                    await sendNotification(user.fcmToken, {
                        title: '⏰ Subscription Expiring Soon',
                        body: `Your Premium subscription expires in ${daysLeft} day(s). Renew now to avoid interruption!`,
                    });
                }

                logger.info(`✅ Sent expiry warning to user ${user?._id} (${daysLeft} days left)`);

            } catch (error) {
                logger.error(`Error notifying user:`, error);
            }
        }

    } catch (error) {
        logger.error('Expiring subscription check error:', error);
    }
};

// Start cron jobs
const startSubscriptionExpiry = () => {
    logger.info('📅 Starting subscription expiry cron jobs');

    // Check for expired subscriptions daily at midnight
    cron.schedule('0 0 * * *', () => {
        logger.info('Running daily subscription expiry check');
        checkExpiredSubscriptions();
    });

    // Check for expiring subscriptions daily at 10 AM
    cron.schedule('0 10 * * *', () => {
        logger.info('Running daily expiring subscription check');
        checkExpiringSubscriptions();
    });

    // Run immediately on startup in development
    if (process.env.NODE_ENV === 'development') {
        logger.info('🔧 Running initial subscription checks (dev mode)');
        // Uncomment to run on startup:
        // checkExpiredSubscriptions();
        // checkExpiringSubscriptions();
    }
};

module.exports = startSubscriptionExpiry;