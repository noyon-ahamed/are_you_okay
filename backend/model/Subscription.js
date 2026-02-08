const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },

    plan: {
        type: String,
        enum: ['free', 'premium'],
        default: 'free'
    },

    // Payment info
    transactionId: String,
    paymentMethod: {
        type: String,
        enum: ['bkash', 'nagad', 'rocket', 'card', 'stripe', 'paypal']
    },
    amount: Number,
    currency: {
        type: String,
        default: 'BDT'
    },

    // Subscription period
    startDate: {
        type: Date,
        default: Date.now
    },
    expiryDate: Date,

    // Auto-renewal
    autoRenew: {
        type: Boolean,
        default: false
    },

    status: {
        type: String,
        enum: ['active', 'expired', 'cancelled', 'pending'],
        default: 'pending'
    },

    // Usage tracking
    usageLimits: {
        aiConversations: {
            used: { type: Number, default: 0 },
            limit: { type: Number, default: 5 } // Free tier limit
        },
        aiVoiceCalls: {
            used: { type: Number, default: 0 },
            limit: { type: Number, default: 0 } // Premium only
        },
        smsSent: {
            used: { type: Number, default: 0 },
            limit: { type: Number, default: 5 }
        },
        voiceCallMinutes: {
            used: { type: Number, default: 0 },
            limit: { type: Number, default: 0 }
        }
    },

    // Reset monthly
    lastResetDate: {
        type: Date,
        default: Date.now
    },

    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Auto-reset usage every month
subscriptionSchema.methods.resetMonthlyUsage = function () {
    const now = new Date();
    const lastReset = new Date(this.lastResetDate);

    // Check if a month has passed
    if (now.getMonth() !== lastReset.getMonth() ||
        now.getFullYear() !== lastReset.getFullYear()) {

        this.usageLimits.aiConversations.used = 0;
        this.usageLimits.aiVoiceCalls.used = 0;
        this.usageLimits.smsSent.used = 0;
        this.usageLimits.voiceCallMinutes.used = 0;
        this.lastResetDate = now;

        return this.save();
    }
};

module.exports = mongoose.model('Subscription', subscriptionSchema);