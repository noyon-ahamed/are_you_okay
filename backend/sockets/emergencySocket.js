const emergencyService = require('../services/emergencyService');

module.exports = (io, socket) => {
    socket.on('emergency:sos', async (data) => {
        try {
            const userId = socket.handshake.auth.userId;
            if (!userId) return;

            const result = await emergencyService.triggerSOS(userId, data.location);
            socket.emit('emergency:sent', result);

            // Broadcast to specific rooms if implemented
            io.to(`emergency_contacts_${userId}`).emit('emergency:alert', { userId, location: data.location });

        } catch (error) {
            socket.emit('emergency:error', { message: error.message });
        }
    });

    socket.on('join_emergency_room', (userId) => {
        // Authenticate if the requestor is an emergency contact
        socket.join(`emergency_contacts_${userId}`);
    });
};
