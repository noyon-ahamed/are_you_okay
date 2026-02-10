const mongoose = require('mongoose');

/**
 * AppConfig Schema
 * Single document for app-wide configuration
 * This uses a singleton pattern - only one document should exist
 */
const AppConfigSchema = new mongoose.Schema({
    // Feature flags
    adsEnabled: {
        type: Boolean,
        default: true,
        description: 'Toggle ads globally'
    },
    maintenanceMode: {
        type: Boolean,
        default: false,
        description: 'Enable maintenance mode'
    },

    // Version control
    minAppVersion: {
        android: {
            type: String,
            default: '1.0.0'
        },
        ios: {
            type: String,
            default: '1.0.0'
        }
    },

    // Feature availability
    features: {
        checkIn: {
            type: Boolean,
            default: true
        },
        sos: {
            type: Boolean,
            default: true
        },
        aiChat: {
            type: Boolean,
            default: true
        },
        earthquakeAlerts: {
            type: Boolean,
            default: true
        },
        payment: {
            type: Boolean,
            default: true
        }
    },

    // Global settings
    settings: {
        maxEmergencyContacts: {
            type: Number,
            default: 10
        },
        checkInGracePeriodHours: {
            type: Number,
            default: 72
        }
    },

    // Announcements
    announcement: {
        enabled: {
            type: Boolean,
            default: false
        },
        message: String,
        type: {
            type: String,
            enum: ['info', 'warning', 'error', 'success'],
            default: 'info'
        },
        dismissible: {
            type: Boolean,
            default: true
        }
    }
}, {
    timestamps: true
});

/**
 * Get or create singleton config
 */
AppConfigSchema.statics.getSingleton = async function () {
    let config = await this.findOne();
    if (!config) {
        config = await this.create({});
    }
    return config;
};

module.exports = mongoose.model('AppConfig', AppConfigSchema);
