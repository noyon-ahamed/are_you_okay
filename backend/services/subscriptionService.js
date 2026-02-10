const User = require('../model/User');
const { addDays } = require('../utils/dateHelper');

const PLANS = {
    free: { price: 0, duration: 36500 }, // basically forever
    premium: { price: 9.99, duration: 30 },
    family: { price: 19.99, duration: 30 }
};

const subscribeUser = async (userId, planName) => {
    const plan = PLANS[planName];
    if (!plan) throw new Error('Invalid plan');

    const user = await User.findById(userId);
    user.subscription = {
        plan: planName,
        startDate: new Date(),
        endDate: addDays(new Date(), plan.duration),
        isActive: true
    };
    await user.save();
    return user.subscription;
};

const checkSubscriptionStatus = async (userId) => {
    const user = await User.findById(userId);
    if (!user.subscription.isActive) return false;

    // Check if expired
    if (new Date() > user.subscription.endDate) {
        user.subscription.isActive = false;
        await user.save();
        return false;
    }
    return true;
};

module.exports = { subscribeUser, checkSubscriptionStatus };
