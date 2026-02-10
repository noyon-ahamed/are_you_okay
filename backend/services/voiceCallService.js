const twilio = require('twilio');
const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

const makeCall = async (to, message) => {
    try {
        const call = await client.calls.create({
            twiml: `<Response><Say>${message}</Say></Response>`,
            to,
            from: process.env.TWILIO_PHONE_NUMBER
        });
        return call.sid;
    } catch (error) {
        console.error('Error making call:', error);
        return null;
    }
};

module.exports = { makeCall };
