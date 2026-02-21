const cron = require('node-cron');
const User = require('../model/User');
const { sendNotification } = require('../config/firebase');
const { logger } = require('../middleware/logger');

// Run at 8:00 AM, 2:00 PM (14:00), and 9:00 PM (21:00) every day
cron.schedule('0 8,14,21 * * *', async () => {
    try {
        logger.info('Running scheduled check-in reminders (8AM, 2PM, 9PM)...');

        // Find all active users with FCM tokens
        const users = await User.find({
            isActive: true,
            fcmToken: { $exists: true, $ne: '' }
        });

        logger.info(`Sending check-in reminders to ${users.length} users.`);

        for (const user of users) {
            // Send reminder alert
            await sendNotification(user.fcmToken, {
                title: 'Check-in Reminder 🕒',
                body: 'Are you okay? Open the app and tap the check-in button to let your loved ones know.',
            });
        }

        logger.info('✅ Successfully sent check-in reminders.');
    } catch (error) {
        logger.error('Error in check-in scheduler:', error);
    }
});

module.exports = {};
