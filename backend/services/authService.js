const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../model/User');
const { sendEmail } = require('./emailService');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = '30d';

/**
 * Register new user
 */
const register = async (email, password, name, phone) => {
    try {
        // Check if user already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            throw new Error('User already exists with this email');
        }

        // Generate email verification token
        const verificationToken = crypto.randomBytes(32).toString('hex');

        // Create user
        const user = await User.create({
            email,
            password,
            name,
            phone,
            verificationToken,
            emailVerified: false,
        });

        // Send verification email
        try {
            const verificationUrl = `${process.env.FRONTEND_URL}/verify-email/${verificationToken}`;
            await sendEmail({
                to: email,
                subject: 'Verify your email - Are You Okay',
                text: `Please verify your email by clicking: ${verificationUrl}`,
                html: `
                    <h2>Welcome to Are You Okay!</h2>
                    <p>Please verify your email address by clicking the link below:</p>
                    <a href="${verificationUrl}">Verify Email</a>
                    <p>Or copy this link: ${verificationUrl}</p>
                `,
            });
        } catch (emailError) {
            console.error('Failed to send verification email:', emailError);
            // Don't fail registration if email fails
        }

        // Generate JWT token
        const token = generateToken(user._id);

        return {
            user: {
                id: user._id,
                email: user.email,
                name: user.name,
                phone: user.phone,
                emailVerified: user.emailVerified,
            },
            token,
        };
    } catch (error) {
        throw error;
    }
};

/**
 * Login user
 */
const login = async (email, password) => {
    try {
        // Find user
        const user = await User.findOne({ email });
        if (!user) {
            throw new Error('Invalid email or password');
        }

        // Check password
        const isPasswordValid = await user.comparePassword(password);
        if (!isPasswordValid) {
            throw new Error('Invalid email or password');
        }

        // Update last active
        user.lastActive = new Date();
        await user.save();

        // Generate JWT token
        const token = generateToken(user._id);

        return {
            user: {
                id: user._id,
                email: user.email,
                name: user.name,
                phone: user.phone,
                emailVerified: user.emailVerified,
                profilePicture: user.profilePicture,
                role: user.role,
            },
            token,
        };
    } catch (error) {
        throw error;
    }
};

/**
 * Verify email
 */
const verifyEmail = async (token) => {
    try {
        const user = await User.findOne({ verificationToken: token });
        if (!user) {
            throw new Error('Invalid or expired verification token');
        }

        user.emailVerified = true;
        user.verificationToken = undefined;
        await user.save();

        return { message: 'Email verified successfully' };
    } catch (error) {
        throw error;
    }
};

/**
 * Request password reset
 */
const forgotPassword = async (email) => {
    try {
        const user = await User.findOne({ email });
        if (!user) {
            // Don't reveal if email exists
            return { message: 'If the email exists, a password reset link has been sent' };
        }

        // Generate reset token
        const resetToken = crypto.randomBytes(32).toString('hex');
        user.resetPasswordToken = resetToken;
        user.resetPasswordExpires = Date.now() + 3600000; // 1 hour
        await user.save();

        // Send reset email
        try {
            const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;
            await sendEmail({
                to: email,
                subject: 'Password Reset - Are You Okay',
                text: `Reset your password by clicking: ${resetUrl}`,
                html: `
                    <h2>Password Reset Request</h2>
                    <p>You requested a password reset. Click the link below to reset your password:</p>
                    <a href="${resetUrl}">Reset Password</a>
                    <p>Or copy this link: ${resetUrl}</p>
                    <p>This link will expire in 1 hour.</p>
                    <p>If you didn't request this, please ignore this email.</p>
                `,
            });
        } catch (emailError) {
            console.error('Failed to send reset email:', emailError);
            throw new Error('Failed to send password reset email');
        }

        return { message: 'Password reset email sent' };
    } catch (error) {
        throw error;
    }
};

/**
 * Reset password with token
 */
const resetPassword = async (token, newPassword) => {
    try {
        const user = await User.findOne({
            resetPasswordToken: token,
            resetPasswordExpires: { $gt: Date.now() },
        });

        if (!user) {
            throw new Error('Invalid or expired reset token');
        }

        // Update password
        user.password = newPassword;
        user.resetPasswordToken = undefined;
        user.resetPasswordExpires = undefined;
        await user.save();

        return { message: 'Password reset successful' };
    } catch (error) {
        throw error;
    }
};

/**
 * Generate JWT token
 */
const generateToken = (userId) => {
    return jwt.sign({ userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
};

/**
 * Verify JWT token
 */
const verifyToken = (token) => {
    try {
        return jwt.verify(token, JWT_SECRET);
    } catch (error) {
        throw new Error('Invalid or expired token');
    }
};

module.exports = {
    register,
    login,
    verifyEmail,
    forgotPassword,
    resetPassword,
    generateToken,
    verifyToken,
};
