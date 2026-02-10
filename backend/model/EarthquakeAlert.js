const mongoose = require('mongoose');

const earthquakeAlertSchema = new mongoose.Schema({
    eventId: {
        type: String,
        required: true, // ID from external API (e.g., USGS)
        unique: true
    },
    magnitude: {
        type: Number,
        required: true
    },
    place: {
        type: String,
        required: true
    },
    time: {
        type: Date,
        required: true
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            required: true
        }
    },
    depth: Number,
    tsunami: {
        type: Number, // 0 or 1
        default: 0
    },
    alertLevel: {
        type: String, // green, yellow, orange, red
        default: 'green'
    },
    usersNotifiedCount: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

// Create geospatial index for location-based queries
earthquakeAlertSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('EarthquakeAlert', earthquakeAlertSchema);
