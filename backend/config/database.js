const mongoose = require('mongoose');

// MongoDB connection with retry logic
const connectDB = async (retries = 5) => {
    try {
        // Connection options
        const options = {
            useNewUrlParser: true,
            useUnifiedTopology: true,
            maxPoolSize: 10, // Maintain up to 10 socket connections
            serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
            socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
            family: 4, // Use IPv4, skip trying IPv6
        };

        // Connect to MongoDB
        const conn = await mongoose.connect(process.env.MONGODB_URI, options);

        console.log('✅ MongoDB Connected:', conn.connection.host);
        console.log('📊 Database Name:', conn.connection.name);

        // Connection event listeners
        mongoose.connection.on('connected', () => {
            console.log('📡 Mongoose connected to MongoDB');
        });

        mongoose.connection.on('error', (err) => {
            console.error('❌ Mongoose connection error:', err);
        });

        mongoose.connection.on('disconnected', () => {
            console.log('📴 Mongoose disconnected from MongoDB');
        });

        // Graceful shutdown
        process.on('SIGINT', async () => {
            await mongoose.connection.close();
            console.log('🛑 MongoDB connection closed due to app termination');
            process.exit(0);
        });

        return conn;

    } catch (error) {
        console.error('❌ MongoDB Connection Error:', error.message);

        if (retries > 0) {
            console.log(`⏳ Retrying connection... (${retries} attempts left)`);
            await new Promise(resolve => setTimeout(resolve, 5000)); // Wait 5s
            return connectDB(retries - 1);
        } else {
            console.error('💀 Failed to connect to MongoDB after multiple attempts');
            process.exit(1);
        }
    }
};

// Database health check
const checkDBHealth = async () => {
    try {
        const state = mongoose.connection.readyState;
        const states = {
            0: 'Disconnected',
            1: 'Connected',
            2: 'Connecting',
            3: 'Disconnecting',
        };

        return {
            status: state === 1 ? 'healthy' : 'unhealthy',
            state: states[state],
            host: mongoose.connection.host,
            name: mongoose.connection.name,
        };
    } catch (error) {
        return {
            status: 'unhealthy',
            error: error.message,
        };
    }
};

// Get database statistics
const getDBStats = async () => {
    try {
        const db = mongoose.connection.db;
        const stats = await db.stats();

        return {
            collections: stats.collections,
            dataSize: `${(stats.dataSize / 1024 / 1024).toFixed(2)} MB`,
            storageSize: `${(stats.storageSize / 1024 / 1024).toFixed(2)} MB`,
            indexes: stats.indexes,
            indexSize: `${(stats.indexSize / 1024 / 1024).toFixed(2)} MB`,
            objects: stats.objects,
        };
    } catch (error) {
        console.error('Error getting DB stats:', error);
        return null;
    }
};

// Clear all collections (USE WITH CAUTION - for development only)
const clearAllCollections = async () => {
    if (process.env.NODE_ENV !== 'development') {
        throw new Error('This operation is only allowed in development mode');
    }

    try {
        const collections = await mongoose.connection.db.collections();

        for (let collection of collections) {
            await collection.deleteMany({});
            console.log(`🗑️ Cleared collection: ${collection.collectionName}`);
        }

        console.log('✅ All collections cleared');
    } catch (error) {
        console.error('Error clearing collections:', error);
        throw error;
    }
};

module.exports = {
    connectDB,
    checkDBHealth,
    getDBStats,
    clearAllCollections, // Only use in development
};