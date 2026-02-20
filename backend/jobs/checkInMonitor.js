const cron = require('node-cron');
const User = require('../model/User');
const CheckIn = require('../model/CheckIn');
const EmergencyContact = require('../model/EmergencyContact');
const EmergencyAlert = require('../model/EmergencyAlert');
const { sendNotification } = require('../config/firebase');
const twilioClient = require('../config/twilio');
const { sendEmail } = require('../services/emailService');
const { ALERT_MESSAGES, CHECK_IN } = require('../config/constants');
const { logger } = require('../middleware/logger');

// Monitor users who haven't checked in for 2 days (48 hours)
const checkMissedCheckIns = async (io) => {
    try {
        logger.info('🔍 Running check-in monitor...');

        const gracePeriod = CHECK_IN.GRACE_PERIOD_HOURS * 60 * 60 * 1000; // Convert to ms
        const thresholdTime = new Date(Date.now() - gracePeriod);

        // Find users who haven't checked in for 2+ days (48h)
        const missedUsers = await User.find({
            isActive: true,
            $or: [
                { lastCheckIn: { $lt: thresholdTime } },
                { lastCheckIn: { $exists: false } },
            ],
        }).select('_id name email phone lastCheckIn location fcmToken');

        logger.info(`Found ${missedUsers.length} users with missed check-ins`);

        for (const user of missedUsers) {
            try {
                // Get emergency contacts
                const contacts = await EmergencyContact.find({ userId: user._id })
                    .sort({ priority: 1 });

                if (contacts.length === 0) {
                    logger.warn(`No emergency contacts for user ${user._id}`);
                    continue;
                }

                // Check if alert already sent in last 24 hours
                const recentAlert = await EmergencyAlert.findOne({
                    userId: user._id,
                    alertType: 'missed_checkin',
                    triggeredAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
                });

                if (recentAlert) {
                    logger.info(`Alert already sent for user ${user._id} in last 24h`);
                    continue;
                }

                // Create emergency alert
                const alert = await EmergencyAlert.create({
                    userId: user._id,
                    alertType: 'missed_checkin',
                    triggeredBy: 'system',
                    location: user.location,
                    message: ALERT_MESSAGES.MISSED_CHECKIN.EN,
                    contactsNotified: [],
                });

                // Format alert message
                const lastSeenDate = user.lastCheckIn
                    ? user.lastCheckIn.toLocaleDateString()
                    : 'Unknown';

                const alertMessage = ALERT_MESSAGES.MISSED_CHECKIN.EN
                    .replace('{userName}', user.name)
                    .replace('{userPhone}', user.phone || 'N/A');

                // Send alerts to emergency contacts
                const contactResults = [];

                for (const contact of contacts) {
                    const contactInfo = {
                        contactId: contact._id,
                        name: contact.name,
                        phone: contact.phone,
                        email: contact.email,
                    };

                    try {
                        // Send SMS
                        const sms = await twilioClient.messages.create({
                            body: alertMessage,
                            from: process.env.TWILIO_PHONE_NUMBER,
                            to: contact.phone,
                        });

                        contactInfo.smsStatus = 'sent';
                        contactInfo.smsSentAt = new Date();
                        contactInfo.smsMessageId = sms.sid;

                        logger.info(`SMS sent to ${contact.name} (${contact.phone})`);

                    } catch (error) {
                        logger.error(`Failed to send SMS to ${contact.name}:`, error);
                        contactInfo.smsStatus = 'failed';
                    }

                    contactResults.push(contactInfo);
                }

                // Update alert with results
                alert.contactsNotified = contactResults;
                await alert.save();

                // Send email alerts to contacts who have email
                for (const contact of contacts) {
                    if (contact.email) {
                        try {
                            const emailSubject = `Emergency Alert: ${user.name} has not checked in`;
                            const emailBody = `
                                <h2>⚠️ Emergency Alert</h2>
                                <p>${alertMessage}</p>
                                <p><strong>User:</strong> ${user.name}</p>
                                <p><strong>Phone:</strong> ${user.phone || 'N/A'}</p>
                                <p><strong>Last Check-in:</strong> ${lastSeenDate}</p>
                                <p>Please contact them immediately.</p>
                                <hr>
                                <p><small>This alert was sent automatically by Are You Okay app.</small></p>
                            `;
                            await sendEmail(contact.email, emailSubject, emailBody);
                            logger.info(`Email sent to ${contact.name} (${contact.email})`);
                        } catch (error) {
                            logger.error(`Failed to send email to ${contact.name}:`, error);
                        }
                    }
                }

                // Update user's missed count
                await User.findByIdAndUpdate(user._id, {
                    $inc: { missedCheckInCount: 1 },
                });

                // Send real-time notification via Socket.io
                if (io) {
                    io.to(`user_${user._id}`).emit('missed_checkin_alert', {
                        message: 'Emergency contacts have been notified',
                        alertId: alert._id,
                    });
                }

                // Send push notification to user
                if (user.fcmToken) {
                    await sendNotification(user.fcmToken, {
                        title: '⚠️ Check-in Reminder',
                        body: 'You haven\'t checked in for 2 days. Your emergency contacts have been notified.',
                    });
                }

                logger.info(`✅ Alert sent for user ${user._id} to ${contactResults.length} contacts`);

            } catch (error) {
                logger.error(`Error processing user ${user._id}:`, error);
            }
        }

        logger.info('✅ Check-in monitor completed');

    } catch (error) {
        logger.error('Check-in monitor error:', error);
    }
};

// Start cron job - runs every 6 hours
const startCheckInMonitor = (io) => {
    logger.info('📅 Starting check-in monitor cron job (every 6 hours)');

    // Run every 6 hours: 0 */6 * * *
    cron.schedule('0 */6 * * *', () => {
        checkMissedCheckIns(io);
    });

    // Run immediately on startup in development
    if (process.env.NODE_ENV === 'development') {
        logger.info('🔧 Running initial check-in monitor (dev mode)');
        // Uncomment to run on startup:
        // checkMissedCheckIns(io);
    }
};

module.exports = startCheckInMonitor;