const { body, param, query, validationResult } = require('express-validator');

// Validation result checker
const validate = (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
        return res.status(400).json({
            error: 'Validation Error',
            errors: errors.array().map(err => ({
                field: err.path,
                message: err.msg,
            })),
        });
    }

    next();
};

// Common validations
const validators = {
    // User registration
    register: [
        body('name').trim().notEmpty().withMessage('Name is required'),
        body('email').isEmail().withMessage('Valid email is required'),
        body('phone').optional().matches(/^[0-9+\-\s()]+$/).withMessage('Invalid phone number'),
        validate,
    ],

    // Update profile
    updateProfile: [
        body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
        body('email').optional().isEmail().withMessage('Valid email is required'),
        body('phone').optional().matches(/^[0-9+\-\s()]+$/).withMessage('Invalid phone number'),
        validate,
    ],

    // Location
    location: [
        body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
        body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
        validate,
    ],

    // Emergency contact
    emergencyContact: [
        body('name').trim().notEmpty().withMessage('Contact name is required'),
        body('phone').matches(/^[0-9+\-\s()]+$/).withMessage('Invalid phone number'),
        body('email').optional().isEmail().withMessage('Valid email is required'),
        body('relation').optional().trim(),
        validate,
    ],

    // Check-in
    checkIn: [
        body('location').exists().withMessage('Location is required'),
        body('location.latitude').isFloat({ min: -90, max: 90 }),
        body('location.longitude').isFloat({ min: -180, max: 180 }),
        body('status').optional().isIn(['safe', 'need_help', 'emergency']),
        validate,
    ],

    // SOS alert
    sos: [
        body('location').exists().withMessage('Location is required'),
        body('location.latitude').isFloat({ min: -90, max: 90 }),
        body('location.longitude').isFloat({ min: -180, max: 180 }),
        body('customMessage').optional().trim().isLength({ max: 500 }),
        validate,
    ],

    // AI chat
    aiChat: [
        body('message').trim().notEmpty().withMessage('Message is required'),
        body('message').isLength({ max: 2000 }).withMessage('Message too long'),
        body('conversationId').optional().isMongoId().withMessage('Invalid conversation ID'),
        validate,
    ],

    // Payment
    payment: [
        body('plan').isIn(['monthly', 'yearly']).withMessage('Invalid plan'),
        body('gateway').isIn(['sslcommerz', 'stripe']).withMessage('Invalid payment gateway'),
        body('paymentMethod').optional().isIn(['bkash', 'nagad', 'rocket', 'card']),
        validate,
    ],

    // MongoDB ID param
    mongoId: [
        param('id').isMongoId().withMessage('Invalid ID'),
        validate,
    ],

    // Pagination
    pagination: [
        query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
        query('skip').optional().isInt({ min: 0 }).toInt(),
        validate,
    ],
};

module.exports = validators;