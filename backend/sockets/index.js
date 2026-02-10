const checkInSocket = require('./checkInSocket');
const emergencySocket = require('./emergencySocket');
const notificationSocket = require('./notificationSocket');
const logger = require('../middleware/logger').logger || console;

const initSockets = (io) => {
    io.on('connection', (socket) => {
        logger.info(`New client connected: ${socket.id}`);

        socket.on('disconnect', () => {
            logger.info(`Client disconnected: ${socket.id}`);
        });

        // Initialize modules
        checkInSocket(io, socket);
        emergencySocket(io, socket);
        notificationSocket(io, socket);
    });
};

module.exports = initSockets;
