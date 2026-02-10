const cron = require('node-cron');
const User = require('../model/User');
const CheckIn = require('../model/CheckIn');
const notificationService = require('../services/notificationService');
const moment = require('moment');

// Run every minute to check for missed check-ins
cron.schedule('* * * * *', async () => {
    try {
        const now = moment();
        // Logic to find users who missed their check-in time
        // This is a simplified example. Real logic needs timezone handling.

        /*
        const users = await User.find({
            'settings.checkInTime': now.format('HH:mm'),
            lastActive: { $lt: now.startOf('day').toDate() } 
        });
        
        for (const user of users) {
             // Send reminder or alert
             await notificationService.sendPushNotification(user._id, "Check-in Reminder", "Are you okay? Please check in.");
        }
        */
        console.log('Running check-in monitor...');
    } catch (error) {
        console.error('Error in check-in monitor:', error);
    }
});

module.exports = {};
