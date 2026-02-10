const jwt = require('jsonwebtoken');
const User = require('../model/User');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

/**
 * Authenticate user via JWT token
 * Extracts token from Authorization header
 * Verifies token and attaches user to request
 */
const authenticate = async (req, res, next) => {
    try {
        // Get token from header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                error: 'No token provided',
            });
        }

        const token = authHeader.substring(7); // Remove 'Bearer ' prefix

        // Verify token
        let decoded;
        try {
            decoded = jwt.verify(token, JWT_SECRET);
        } catch (error) {
            return res.status(401).json({
                success: false,
                error: 'Invalid or expired token',
            });
        }

        // Get user from database
        const user = await User.findById(decoded.userId).select('-password');

        if (!user) {
            return res.status(401).json({
                success: false,
                error: 'User not found',
            });
        }

        // Attach user to request
        req.user = user;
        req.userId = user._id;

        next();
    } catch (error) {
        console.error('Auth middleware error:', error);
        return res.status(500).json({
            success: false,
            error: 'Authentication failed',
        });
    }
};

/**
 * Check if user is admin
 */
const requireAdmin = async (req, res, next) => {
    if (!req.user || req.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            error: 'Admin access required',
        });
    }
    next();
};

/**
 * Optional auth - attaches user if token is valid, but doesn't fail if no token
 */
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.substring(7);
            const decoded = jwt.verify(token, JWT_SECRET);
            const user = await User.findById(decoded.userId).select('-password');

            if (user) {
                req.user = user;
                req.userId = user._id;
            }
        }

        next();
    } catch (error) {
        // Ignore errors for optional auth
        next();
    }
};

module.exports = authenticate;
module.exports.authenticate = authenticate;
module.exports.requireAdmin = requireAdmin;
module.exports.optionalAuth = optionalAuth;