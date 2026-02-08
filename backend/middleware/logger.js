const fs = require('fs');
const path = require('path');

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

// Request logger middleware
const requestLogger = (req, res, next) => {
    const start = Date.now();

    // Log after response
    res.on('finish', () => {
        const duration = Date.now() - start;

        const logEntry = {
            timestamp: new Date().toISOString(),
            method: req.method,
            path: req.path,
            query: req.query,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            userId: req.user?._id?.toString() || 'anonymous',
            ip: req.ip || req.connection.remoteAddress,
            userAgent: req.get('user-agent'),
        };

        // Log to console in development
        if (process.env.NODE_ENV === 'development') {
            const emoji = res.statusCode >= 400 ? '❌' : '✅';
            console.log(
                `${emoji} ${logEntry.method} ${logEntry.path} - ${logEntry.statusCode} - ${logEntry.duration}`
            );
        }

        // Write to file
        const logFile = path.join(logsDir, 'combined.log');
        fs.appendFileSync(logFile, JSON.stringify(logEntry) + '\n');

        // Log errors separately
        if (res.statusCode >= 400) {
            const errorFile = path.join(logsDir, 'error.log');
            fs.appendFileSync(errorFile, JSON.stringify(logEntry) + '\n');
        }
    });

    next();
};

// Custom logger functions
const logger = {
    info: (message, data = {}) => {
        const entry = {
            level: 'INFO',
            timestamp: new Date().toISOString(),
            message,
            ...data,
        };
        console.log('ℹ️', message, data);

        const logFile = path.join(logsDir, 'combined.log');
        fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
    },

    error: (message, error = {}) => {
        const entry = {
            level: 'ERROR',
            timestamp: new Date().toISOString(),
            message,
            error: error.message,
            stack: error.stack,
        };
        console.error('❌', message, error);

        const errorFile = path.join(logsDir, 'error.log');
        fs.appendFileSync(errorFile, JSON.stringify(entry) + '\n');
    },

    warn: (message, data = {}) => {
        const entry = {
            level: 'WARN',
            timestamp: new Date().toISOString(),
            message,
            ...data,
        };
        console.warn('⚠️', message, data);

        const logFile = path.join(logsDir, 'combined.log');
        fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
    },

    debug: (message, data = {}) => {
        if (process.env.NODE_ENV !== 'production') {
            const entry = {
                level: 'DEBUG',
                timestamp: new Date().toISOString(),
                message,
                ...data,
            };
            console.log('🐛', message, data);
        }
    },
};

module.exports = {
    requestLogger,
    logger,
};