const EmergencyContact = require('../model/EmergencyContact');
const User = require('../model/User');

const addContact = async (userId, contactData) => {
    // Limit contacts for free users if needed
    const contactsCount = await EmergencyContact.countDocuments({ user: userId });
    if (contactsCount >= 5) throw new Error('Maximum contacts limit reached');

    return await EmergencyContact.create({
        user: userId,
        ...contactData
    });
};

const getContacts = async (userId) => {
    return await EmergencyContact.find({ user: userId }).sort({ priority: 1 });
};

const triggerSOS = async (userId, location) => {
    const user = await User.findById(userId);
    const contacts = await EmergencyContact.find({ user: userId });

    // Logic to send alerts (SMS, notifications, etc.) would be called here
    // This will be integrated with notificationService

    return {
        message: 'SOS triggered successfully',
        contactsNotified: contacts.length
    };
};

module.exports = { addContact, getContacts, triggerSOS };
