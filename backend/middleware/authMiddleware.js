const { verifyIdToken } = require('../config/firebase');
const User = require('../models/User');

const authenticate = async (req, res, next) => {
    try {
        // Get token from header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'No authentication token provided'
            });
        }

        const token = authHeader.split('Bearer ')[1];

        if (!token) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Invalid token format'
            });
        }

        // Verify Firebase token
        const decodedToken = await verifyIdToken(token);

        // Find or create user in MongoDB
        let user = await User.findOne({ firebaseUid: decodedToken.uid });

        if (!user) {
            // Auto-create user on first request
            user = await User.create({
                firebaseUid: decodedToken.uid,
                email: decodedToken.email || '',
                phone: decodedToken.phone_number || '',
                name: decodedToken.name || 'User',
                profilePicture: decodedToken.picture || '',
            });

            console.log('✅ New user auto-created:', user._id);
        }

        // Attach user to request
        req.user = user;
        req.firebaseUser = decodedToken;

        next();

    } catch (error) {
        console.error('Auth Middleware Error:', error.message);

        if (error.code === 'auth/id-token-expired') {
            return res.status(401).json({
                error: 'Token expired',
                message: 'Please login again'
            });
        }

        if (error.code === 'auth/argument-error') {
            return res.status(401).json({
                error: 'Invalid token',
                message: 'Authentication token is invalid'
            });
        }

        res.status(401).json({
            error: 'Authentication failed',
            message: error.message
        });
    }
};

// Optional auth - doesn't fail if no token
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return next(); // Continue without auth
        }

        const token = authHeader.split('Bearer ')[1];

        if (token) {
            const decodedToken = await verifyIdToken(token);
            const user = await User.findOne({ firebaseUid: decodedToken.uid });

            if (user) {
                req.user = user;
                req.firebaseUser = decodedToken;
            }
        }

        next();

    } catch (error) {
        // Silently fail, continue without auth
        next();
    }
};

module.exports = authenticate;
module.exports.optionalAuth = optionalAuth;