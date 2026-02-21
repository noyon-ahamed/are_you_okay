module.exports = {
    // App Info
    APP_NAME: 'Are You Okay',
    APP_VERSION: '1.0.0',

    // Pricing (BDT)
    PRICING: {
        MONTHLY: {
            BDT: 299,
            USD: 3.5
        },
        YEARLY: {
            BDT: 2999,
            USD: 35
        }
    },

    // Free tier limits
    FREE_LIMITS: {
        AI_CONVERSATIONS: 5,
        AI_VOICE_CALLS: 0,
        SMS_ALERTS: 5,
        VOICE_CALL_MINUTES: 0,
        EMERGENCY_CONTACTS: 5,
        CHECK_INS: -1 // unlimited
    },

    // Premium limits
    PREMIUM_LIMITS: {
        AI_CONVERSATIONS: -1, // unlimited
        AI_VOICE_CALLS: 10,
        SMS_ALERTS: -1, // unlimited
        VOICE_CALL_MINUTES: 60,
        EMERGENCY_CONTACTS: 10,
        CHECK_INS: -1 // unlimited
    },

    // Check-in settings
    CHECK_IN: {
        GRACE_PERIOD_HOURS: 72, // 3 days (72h inactivity triggers emergency alert)
        REMINDER_HOURS: [8, 14, 21], // 8 AM, 2 PM, 9 PM
        STREAK_RESET_HOURS: 72
    },

    // Emergency settings
    EMERGENCY: {
        SOS_COOLDOWN_MINUTES: 5, // Prevent spam
        AUTO_CALL_DELAY_SECONDS: 30, // Wait before auto-calling
        MAX_RETRY_ATTEMPTS: 3
    },

    // Earthquake settings
    EARTHQUAKE: {
        MIN_MAGNITUDE: 4.5,
        ALERT_RADIUS_KM: 100,
        CHECK_INTERVAL_MS: 120000, // 2 minutes
        ALERT_BEFORE_MINUTES: 5 // Alert 5 min before estimated arrival
    },

    // AI settings
    AI: {
        MODEL: 'claude-sonnet-4-20250514',
        MAX_TOKENS: 1024,
        TEMPERATURE: 0.7,
        SYSTEM_PROMPT: `You are a helpful medical assistant for the "Are You Okay" safety app.
Provide caring, accurate medical advice in Bengali or English based on user preference.
Always recommend seeing a doctor for serious issues.
Keep responses concise and actionable.`
    },

    // Twilio settings
    TWILIO: {
        SMS_FROM: process.env.TWILIO_PHONE_NUMBER,
        VOICE_FROM: process.env.TWILIO_PHONE_NUMBER,
        TTS_LANGUAGE: 'bn-IN', // Bengali
        TTS_VOICE: 'woman'
    },

    // Notification settings
    NOTIFICATION: {
        BATCH_SIZE: 100,
        RETRY_ATTEMPTS: 3,
        TTL_DAYS: 30 // Delete after 30 days
    },

    // Rate limiting
    RATE_LIMITS: {
        CHECK_IN: {
            windowMs: 24 * 60 * 60 * 1000, // 24 hours
            max: 5 // 5 check-ins per day max
        },
        AI_CHAT: {
            windowMs: 60 * 60 * 1000, // 1 hour
            max: 20 // 20 messages per hour
        },
        SOS: {
            windowMs: 60 * 1000, // 1 minute
            max: 3 // 3 SOS per minute
        },
        API_GENERAL: {
            windowMs: 15 * 60 * 1000, // 15 minutes
            max: 100 // 100 requests per 15 min
        }
    },

    // Alert messages (Bengali + English)
    ALERT_MESSAGES: {
        MISSED_CHECKIN: {
            EN: 'Emergency Alert: Your relative \'{userName}\' has not checked in for the last 2 days. Please check on them. Phone: {userPhone}.',
            BN: 'জরুরি সতর্কতা: আপনার নিকটজন \'{userName}\' গত ২ দিন চেক-ইন করেননি। অনুগ্রহ করে তাকে দেখুন। ফোন: {userPhone}।'
        },
        SOS: {
            EN: 'EMERGENCY: {userName} has sent an SOS alert! Current location: {location}. Message: {message}',
            BN: 'জরুরি: {userName} একটি SOS সতর্কতা পাঠিয়েছেন! বর্তমান অবস্থান: {location}। বার্তা: {message}'
        },
        EARTHQUAKE: {
            EN: 'Earthquake Alert: Magnitude {magnitude} earthquake detected near {location}. Take safety precautions immediately!',
            BN: 'ভূমিকম্প সতর্কতা: {location} এর কাছে {magnitude} মাত্রার ভূমিকম্প শনাক্ত হয়েছে। অবিলম্বে নিরাপত্তা ব্যবস্থা নিন!'
        }
    },

    // URLs
    URLS: {
        PRIVACY_POLICY: 'https://areyouokay.com/privacy',
        TERMS_OF_SERVICE: 'https://areyouokay.com/terms',
        SUPPORT_EMAIL: 'support@areyouokay.com',
        HELP_CENTER: 'https://areyouokay.com/help'
    }
};