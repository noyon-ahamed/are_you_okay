const jwt = require('jsonwebtoken');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE || '30d'
    });
};

const generateResetToken = () => {
    const crypto = require('crypto');
    return crypto.randomBytes(20).toString('hex');
};

module.exports = { generateToken, generateResetToken };
