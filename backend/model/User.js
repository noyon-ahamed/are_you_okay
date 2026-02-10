const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true
    },
    firebaseUid: {
        type: String,
        unique: true,
        sparse: true, // Allow null for JWT-only users
        required: false
    },
    password: {
        type: String,
        required: true,
        minlength: 6
    },
    emailVerified: {
        type: Boolean,
        default: false
    },
    verificationToken: String,
    resetPasswordToken: String,
    resetPasswordExpires: Date,
    profilePicture: String,
    phone: {
        type: String,
        required: false, // Optional initially
        trim: true
    },
    role: {
        type: String,
        enum: ['user', 'admin'],
        default: 'user'
    },
    subscription: {
        plan: {
            type: String,
            enum: ['free', 'premium', 'family'],
            default: 'free'
        },
        startDate: Date,
        endDate: Date,
        isActive: {
            type: Boolean,
            default: false
        },
        stripeCustomerId: String
    },
    settings: {
        checkInTime: {
            type: String, // HH:mm format
            default: '09:00'
        },
        notificationEnabled: {
            type: Boolean,
            default: true
        },
        earthquakeAlerts: {
            type: Boolean,
            default: true
        }
    },
    fcmToken: String, // For push notifications
    lastActive: Date
}, {
    timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();

    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
