const mongoose = require('mongoose');

const moodSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true,
    },
    mood: {
        type: String,
        enum: ['happy', 'good', 'neutral', 'sad', 'anxious', 'angry'],
        required: true,
    },
    note: {
        type: String,
        default: '',
        maxLength: 500,
    },
    timestamp: {
        type: Date,
        default: Date.now,
        index: true,
    },
});

// Compound index for efficient queries
moodSchema.index({ userId: 1, timestamp: -1 });

module.exports = mongoose.model('Mood', moodSchema);
