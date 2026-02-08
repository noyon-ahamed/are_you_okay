const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },

    // Notification type
    type: {
        type: String,
        enum: [
            'checkin_reminder',
            'checkin_missed',
            'emergency_alert',
            'earthquake_alert',
            'subscription_expiring',
            'subscription_expired',
            'usage_limit_warning',
            'contact_response',
            'system_announcement',
            'payment_success',
            'payment_failed'
        ],
        required: true,
        index: true
    },

    // Content
    title: {
        type: String,
        required: true
    },
    body: {
        type: String,
        required: true
    },
    imageUrl: String,

    // Action data (for deep linking)
    actionData: {
        screen: String, // Screen to open
        params: mongoose.Schema.Types.Mixed // Additional params
    },

    // Delivery
    channels: [{
        type: String,
        enum: ['push', 'sms', 'email', 'in_app']
    }],

    // Push notification specific
    fcmMessageId: String,
    fcmStatus: {
        type: String,
        enum: ['pending', 'sent', 'delivered', 'failed'],
        default: 'pending'
    },

    // Status
    read: {
        type: Boolean,
        default: false
    },
    readAt: Date,

    clicked: {
        type: Boolean,
        default: false
    },
    clickedAt: Date,

    // Priority
    priority: {
        type: String,
        enum: ['low', 'normal', 'high', 'urgent'],
        default: 'normal'
    },

    // Scheduling
    scheduledFor: Date,
    sentAt: Date,

    // Metadata
    createdAt: {
        type: Date,
        default: Date.now,
        index: true
    },
    expiresAt: Date // Auto-delete old notifications
});

// Compound indexes
notificationSchema.index({ userId: 1, read: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, type: 1 });

// Auto-delete expired notifications
notificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('Notification', notificationSchema);