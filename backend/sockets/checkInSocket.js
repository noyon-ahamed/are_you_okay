const checkInService = require('../services/checkInService');

module.exports = (io, socket) => {
    socket.on('checkIn:create', async (data) => {
        try {
            // Assuming we have user info attached to socket via middleware or handshake
            const userId = socket.handshake.auth.userId;
            if (!userId) return;

            const checkIn = await checkInService.createCheckIn(userId, data);
            socket.emit('checkIn:success', checkIn);
        } catch (error) {
            socket.emit('checkIn:error', { message: error.message });
        }
    });
};
