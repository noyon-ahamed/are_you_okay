require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
const { connectDB } = require('./config/database');
const { requestLogger, logger } = require('./middleware/logger');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const { apiLimiter } = require('./middleware/rateLimiter');

// Import routes
const authRoutes = require('./routes/auth');
const checkinRoutes = require('./routes/checkin');
const emergencyRoutes = require('./routes/emergency');
const paymentRoutes = require('./routes/payment');
const aiRoutes = require('./routes/ai');
const earthquakeRoutes = require('./routes/earthquake');
const notificationRoutes = require('./routes/notification');



// Import background jobs
const startCheckInMonitor = require('./jobs/checkInMonitor');
const startEarthquakeMonitor = require('./jobs/earthquakeMonitor');
const startSubscriptionExpiry = require('./jobs/subscriptionExpiry');
const startUsageReset = require('./jobs/usageReset');
const startCleanup = require('./jobs/cleanup');

const app = express();
const server = http.createServer(app);

// Socket.io setup
const io = socketIo(server, {
    cors: {
        origin: process.env.FRONTEND_URL || "*",
        methods: ["GET", "POST"],
        credentials: true,
    },
});

// Middleware
app.use(cors({
    origin: process.env.FRONTEND_URL || "*",
    credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(requestLogger); // Custom request logger

// Make io accessible to routes
app.set('io', io);

// Connect to MongoDB
connectDB();

// API rate limiting (apply to all routes)
app.use('/api', apiLimiter);

// Health check (no rate limit)
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date(),
        uptime: process.uptime(),
    });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/checkin', checkinRoutes);
app.use('/api/emergency', emergencyRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/earthquake', earthquakeRoutes);
app.use('/api/notification', notificationRoutes);

// Socket.io connection handling
io.on('connection', (socket) => {
    logger.info('Client connected', { socketId: socket.id });

    // User joins their personal room
    socket.on('join', (userId) => {
        socket.join(`user_${userId}`);
        logger.info('User joined room', { userId, socketId: socket.id });
    });

    // Handle real-time location updates
    socket.on('location_update', async (data) => {
        const { userId, latitude, longitude } = data;
        // Broadcast to user's emergency contacts if needed
        socket.to(`user_${userId}`).emit('location_updated', { latitude, longitude });
    });

    socket.on('disconnect', () => {
        logger.info('Client disconnected', { socketId: socket.id });
    });
});

// 404 handler
app.use(notFound);

// Global error handler (must be last)
app.use(errorHandler);

// Start background jobs (existing code এর পরে add করো)
if (process.env.NODE_ENV === 'production' || process.env.ENABLE_JOBS === 'true') {
    startCheckInMonitor(io);
    startEarthquakeMonitor(io);
    startSubscriptionExpiry();
    startUsageReset();
    startCleanup();
    logger.info(' All background jobs started');
}

// Start server
const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
    logger.info(`🚀 Server running on port ${PORT}`);
    logger.info(`📡 Socket.io listening`);
    logger.info(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection', { reason, promise });
});

process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception', error);
    process.exit(1);
});