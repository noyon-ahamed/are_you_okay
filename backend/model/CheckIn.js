const mongoose = require('mongoose');

const checkInSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    status: {
        type: String,
        enum: ['safe', 'missed', 'emergency'],
        default: 'missed'
    },
    checkInTime: {
        type: Date,
        default: Date.now
    },
    location: {
        latitude: Number,
        longitude: Number,
        address: String
    },
    notes: String,
    deviceInfo: String
}, {
    timestamps: true
});

module.exports = mongoose.model('CheckIn', checkInSchema);
