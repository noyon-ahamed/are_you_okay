const mongoose = require('mongoose');

const usageLogSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },

    // Feature used
    feature: {
        type: String,
        enum: [
            'ai_conversation',
            'ai_voice_call',
            'sms_sent',
            'voice_call',
            'check_in',
            'sos_alert',
            'earthquake_alert'
        ],
        required: true,
        index: true
    },

    // Usage details
    timestamp: {
        type: Date,
        default: Date.now,
        index: true
    },

    // Subscription info at time of use
    subscriptionPlan: {
        type: String,
        enum: ['free', 'premium']
    },

    // Feature-specific data
    metadata: {
        // For AI
        conversationId: mongoose.Schema.Types.ObjectId,
        messageCount: Number,
        tokensUsed: Number,

        // For calls
        duration: Number, // seconds
        cost: Number,

        // For SMS
        recipientCount: Number,

        // For alerts
        alertType: String,
        severity: String
    },

    // Cost tracking (for analytics)
    estimatedCost: {
        type: Number,
        default: 0
    },
    currency: {
        type: String,
        default: 'BDT'
    },

    // Status
    status: {
        type: String,
        enum: ['success', 'failed', 'partial'],
        default: 'success'
    },
    errorMessage: String
});

// Compound index for monthly usage queries
usageLogSchema.index({
    userId: 1,
    feature: 1,
    timestamp: -1
});

// Method to get monthly usage for a user
usageLogSchema.statics.getMonthlyUsage = async function (userId, feature) {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    return await this.countDocuments({
        userId,
        feature,
        timestamp: { $gte: startOfMonth },
        status: 'success'
    });
};

module.exports = mongoose.model('UsageLog', usageLogSchema);