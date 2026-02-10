const CheckIn = require('../model/CheckIn');
const User = require('../model/User');

const createCheckIn = async (userId, data) => {
    const checkIn = await CheckIn.create({
        user: userId,
        status: data.status,
        location: data.location,
        notes: data.notes
    });

    // Update user's last active and potentially clear any missed check-in flags
    await User.findByIdAndUpdate(userId, { lastActive: new Date() });

    return checkIn;
};

const getCheckInHistory = async (userId, limit = 10) => {
    return await CheckIn.find({ user: userId })
        .sort({ createdAt: -1 })
        .limit(limit);
};

module.exports = { createCheckIn, getCheckInHistory };
