const rateLimit = require('express-rate-limit');
const { RATE_LIMITS } = require('../config/constants');

// General API rate limiter
const apiLimiter = rateLimit({
    windowMs: RATE_LIMITS.API_GENERAL.windowMs,
    max: RATE_LIMITS.API_GENERAL.max,
    message: {
        error: 'Too many requests',
        message: 'Please try again later',
    },
    standardHeaders: true,
    legacyHeaders: false,
    // Skip successful requests from counting
    skip: (req, res) => res.statusCode < 400,
});

// Check-in specific rate limiter
const checkInLimiter = rateLimit({
    windowMs: RATE_LIMITS.CHECK_IN.windowMs,
    max: RATE_LIMITS.CHECK_IN.max,
    message: {
        error: 'Too many check-ins',
        message: 'You can only check in 5 times per day',
    },
    keyGenerator: (req) => {
        // Rate limit per user
        return req.user?._id?.toString() || req.ip;
    },
});

// AI chat rate limiter
const aiChatLimiter = rateLimit({
    windowMs: RATE_LIMITS.AI_CHAT.windowMs,
    max: RATE_LIMITS.AI_CHAT.max,
    message: {
        error: 'Too many AI requests',
        message: 'Please wait a moment before sending more messages',
    },
    keyGenerator: (req) => {
        return req.user?._id?.toString() || req.ip;
    },
});

// SOS alert rate limiter (prevent spam)
const sosLimiter = rateLimit({
    windowMs: RATE_LIMITS.SOS.windowMs,
    max: RATE_LIMITS.SOS.max,
    message: {
        error: 'Too many SOS alerts',
        message: 'Please wait before sending another SOS alert',
    },
    keyGenerator: (req) => {
        return req.user?._id?.toString() || req.ip;
    },
    skipSuccessfulRequests: false, // Always count SOS attempts
});

// Payment rate limiter (prevent abuse)
const paymentLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 10,
    message: {
        error: 'Too many payment attempts',
        message: 'Please try again later',
    },
    keyGenerator: (req) => {
        return req.user?._id?.toString() || req.ip;
    },
});

// Auth rate limiter (prevent brute force)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 20, // 20 attempts
    message: {
        error: 'Too many authentication attempts',
        message: 'Please try again after 15 minutes',
    },
    skipSuccessfulRequests: true,
});

module.exports = {
    apiLimiter,
    checkInLimiter,
    aiChatLimiter,
    sosLimiter,
    paymentLimiter,
    authLimiter,
};