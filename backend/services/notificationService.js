const admin = require('firebase-admin');
const User = require('../model/User');

// Initialize Firebase Admin (assuming service account is set up in server.js or config)
// If not, we should initialize it here or in a config file.
// For now, assuming it's initialized globally or we import the instance.

const sendPushNotification = async (userId, title, body, data = {}) => {
    try {
        const user = await User.findById(userId);
        if (!user || !user.fcmToken) return;

        const message = {
            notification: { title, body },
            data,
            token: user.fcmToken
        };

        await admin.messaging().send(message);
        return true;
    } catch (error) {
        console.error('Error sending push notification:', error);
        return false;
    }
};

const sendMulticastNotification = async (userIds, title, body, data = {}) => {
    // logic for multiple users
};

module.exports = { sendPushNotification, sendMulticastNotification };
