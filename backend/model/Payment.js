const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },

    // Payment gateway info
    transactionId: {
        type: String,
        required: true,
        unique: true
    },
    gatewayTransactionId: String, // SSLCommerz/Stripe transaction ID

    amount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        default: 'BDT'
    },

    paymentMethod: String,
    gateway: {
        type: String,
        enum: ['sslcommerz', 'aamarpay', 'stripe']
    },

    // Payment status
    status: {
        type: String,
        enum: ['pending', 'success', 'failed', 'refunded'],
        default: 'pending'
    },

    // Subscription reference
    subscriptionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Subscription'
    },

    // Gateway response (for debugging)
    gatewayResponse: mongoose.Schema.Types.Mixed,

    // Timestamps
    paidAt: Date,
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Payment', paymentSchema);