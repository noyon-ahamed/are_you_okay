const twilio = require('twilio');
const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

const sendSMS = async (to, body) => {
    try {
        const message = await client.messages.create({
            body,
            from: process.env.TWILIO_PHONE_NUMBER,
            to
        });
        return message.sid;
    } catch (error) {
        console.error('Error sending SMS:', error);
        return null; // Or throw error based on preference
    }
};

module.exports = { sendSMS };
