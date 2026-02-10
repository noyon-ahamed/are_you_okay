const cron = require('node-cron');
const CheckIn = require('../model/CheckIn');
const Notification = require('../model/Notification');
const UsageLog = require('../model/UsageLog');
const { logger } = require('../middleware/logger');

// Clean up old records
const cleanupOldRecords = async () => {
    try {
        logger.info('🧹 Starting database cleanup...');

        const now = new Date();

        // Delete check-ins older than 90 days
        const ninetyDaysAgo = new Date(now - 90 * 24 * 60 * 60 * 1000);
        const deletedCheckIns = await CheckIn.deleteMany({
            timestamp: { $lt: ninetyDaysAgo },
        });
        logger.info(`Deleted ${deletedCheckIns.deletedCount} old check-ins`);

        // Delete read notifications older than 30 days
        const thirtyDaysAgo = new Date(now - 30 * 24 * 60 * 60 * 1000);
        const deletedNotifications = await Notification.deleteMany({
            read: true,
            createdAt: { $lt: thirtyDaysAgo },
        });
        logger.info(`Deleted ${deletedNotifications.deletedCount} old notifications`);

        // Delete usage logs older than 6 months
        const sixMonthsAgo = new Date(now - 180 * 24 * 60 * 60 * 1000);
        const deletedLogs = await UsageLog.deleteMany({
            timestamp: { $lt: sixMonthsAgo },
        });
        logger.info(`Deleted ${deletedLogs.deletedCount} old usage logs`);

        logger.info('✅ Database cleanup completed');

    } catch (error) {
        logger.error('Database cleanup error:', error);
    }
};

// Start cron job - runs weekly on Sunday at 3 AM
const startCleanup = () => {
    logger.info('📅 Starting database cleanup cron job (weekly)');

    // Run every Sunday at 3 AM: 0 3 * * 0
    cron.schedule('0 3 * * 0', () => {
        logger.info('Running weekly database cleanup');
        cleanupOldRecords();
    });
};

module.exports = startCleanup;