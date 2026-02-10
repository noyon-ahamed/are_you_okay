const cron = require('node-cron');
const User = require('../model/User');
const UsageLog = require('../model/UsageLog');
const { logger } = require('../middleware/logger');

// Reset monthly usage for all subscriptions
const resetMonthlyUsage = async () => {
    try {
        logger.info('🔄 Resetting monthly usage for all subscriptions...');

        const result = await Subscription.updateMany(
            {},
            {
                $set: {
                    'usageLimits.aiConversations.used': 0,
                    'usageLimits.aiVoiceCalls.used': 0,
                    'usageLimits.smsSent.used': 0,
                    'usageLimits.voiceCallMinutes.used': 0,
                    lastResetDate: new Date(),
                },
            }
        );

        logger.info(`✅ Reset usage for ${result.modifiedCount} subscriptions`);

    } catch (error) {
        logger.error('Usage reset error:', error);
    }
};

// Start cron job - runs on 1st of every month at midnight
const startUsageReset = () => {
    logger.info('📅 Starting monthly usage reset cron job');

    // Run on 1st of every month at 00:00: 0 0 1 * *
    cron.schedule('0 0 1 * *', () => {
        logger.info('Running monthly usage reset');
        resetMonthlyUsage();
    });
};

module.exports = startUsageReset;