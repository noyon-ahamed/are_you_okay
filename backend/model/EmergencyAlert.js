const mongoose = require('mongoose');

const emergencyAlertSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },

    // Alert type
    alertType: {
        type: String,
        enum: ['missed_checkin', 'manual_sos', 'earthquake', 'location_emergency'],
        required: true
    },

    // Trigger info
    triggeredAt: {
        type: Date,
        default: Date.now,
        index: true
    },
    triggeredBy: {
        type: String,
        enum: ['system', 'user', 'auto'],
        default: 'system'
    },

    // Location at time of alert
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: [Number]
    },
    address: String,

    // Message sent
    message: String,
    customMessage: String, // User's custom SOS message

    // Contacts notified
    contactsNotified: [{
        contactId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'EmergencyContact'
        },
        name: String,
        phone: String,
        email: String,

        // Notification status
        smsStatus: {
            type: String,
            enum: ['pending', 'sent', 'failed', 'delivered'],
            default: 'pending'
        },
        smsSentAt: Date,
        smsMessageId: String,

        callStatus: {
            type: String,
            enum: ['pending', 'initiated', 'answered', 'failed', 'no_answer'],
            default: 'pending'
        },
        callInitiatedAt: Date,
        callDuration: Number, // seconds
        callSid: String, // Twilio call ID

        emailStatus: {
            type: String,
            enum: ['pending', 'sent', 'failed', 'opened'],
            default: 'pending'
        },
        emailSentAt: Date,

        pushStatus: {
            type: String,
            enum: ['pending', 'sent', 'failed', 'delivered'],
            default: 'pending'
        },
        pushSentAt: Date
    }],

    // Police/Ambulance notification (premium only)
    policeNotified: {
        type: Boolean,
        default: false
    },
    policeNotifiedAt: Date,
    ambulanceNotified: {
        type: Boolean,
        default: false
    },
    ambulanceNotifiedAt: Date,

    // Alert resolution
    resolved: {
        type: Boolean,
        default: false
    },
    resolvedAt: Date,
    resolvedBy: {
        type: String,
        enum: ['user', 'contact', 'auto']
    },
    resolutionNote: String,

    // Metadata
    userStatus: {
        type: String,
        enum: ['missing', 'in_danger', 'safe', 'unknown'],
        default: 'unknown'
    },
    priority: {
        type: String,
        enum: ['low', 'medium', 'high', 'critical'],
        default: 'high'
    },

    createdAt: {
        type: Date,
        default: Date.now
    }
});

emergencyAlertSchema.index({ userId: 1, triggeredAt: -1 });
emergencyAlertSchema.index({ alertType: 1, resolved: 1 });

module.exports = mongoose.model('EmergencyAlert', emergencyAlertSchema);