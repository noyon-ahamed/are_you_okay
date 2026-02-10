module.exports = (io, socket) => {
    socket.on('join_notifications', (userId) => {
        socket.join(`notifications_${userId}`);
    });

    // This is mostly for server-to-client, so we might not have many listeners here
    // But we can listen for read receipts
    socket.on('notification:read', (notificationId) => {
        // Mark notification as read in DB
    });
};
