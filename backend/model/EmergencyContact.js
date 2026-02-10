const mongoose = require('mongoose');

const emergencyContactSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    phone: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        trim: true,
        lowercase: true
    },
    relation: {
        type: String,
        default: 'Family'
    },
    priority: {
        type: Number, // 1 for primary, 2 for secondary, etc.
        default: 1
    },
    isVerified: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('EmergencyContact', emergencyContactSchema);
