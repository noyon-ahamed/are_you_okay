const cron = require('node-cron');
const axios = require('axios');
const User = require('../model/User');
const EarthquakeAlert = require('../model/EarthquakeAlert');
const { sendNotification, sendMulticastNotification } = require('../config/firebase');
const { EARTHQUAKE } = require('../config/constants');
const { logger } = require('../middleware/logger');

// Store processed earthquake IDs to avoid duplicates
const processedEarthquakes = new Set();

// Haversine formula to calculate distance between two points
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;

    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;

    return distance;
};

// Fetch recent earthquakes from USGS API
const fetchEarthquakes = async () => {
    try {
        // Get earthquakes from last 1 hour with magnitude >= 4.5
        const now = new Date();
        const oneHourAgo = new Date(now - 60 * 60 * 1000);

        const response = await axios.get('https://earthquake.usgs.gov/fdsnws/event/1/query', {
            params: {
                format: 'geojson',
                starttime: oneHourAgo.toISOString(),
                minmagnitude: EARTHQUAKE.MIN_MAGNITUDE,
                orderby: 'time',
            },
            timeout: 10000,
        });

        return response.data.features || [];

    } catch (error) {
        logger.error('Failed to fetch earthquakes:', error);
        return [];
    }
};

// Process earthquake and alert nearby users
const processEarthquake = async (earthquake, io) => {
    try {
        const eventId = earthquake.id;

        // Skip if already processed
        if (processedEarthquakes.has(eventId)) {
            return;
        }

        const coords = earthquake.geometry.coordinates;
        const [longitude, latitude, depth] = coords;
        const magnitude = earthquake.properties.mag;
        const place = earthquake.properties.place;
        const timestamp = new Date(earthquake.properties.time);

        logger.info(`🌍 New earthquake detected: ${magnitude} at ${place}`);

        // Check if already in database
        const existing = await EarthquakeAlert.findOne({ eventId });
        if (existing) {
            processedEarthquakes.add(eventId);
            return;
        }

        // Find nearby users within radius
        const radiusInMeters = EARTHQUAKE.ALERT_RADIUS_KM * 1000;

        const nearbyUsers = await User.find({
            isActive: true,
            location: {
                $near: {
                    $geometry: {
                        type: 'Point',
                        coordinates: [longitude, latitude],
                    },
                    $maxDistance: radiusInMeters,
                },
            },
        }).select('_id name location fcmToken');

        if (nearbyUsers.length === 0) {
            logger.info('No users nearby this earthquake');
            processedEarthquakes.add(eventId);
            return;
        }

        // Create earthquake alert record
        const alert = await EarthquakeAlert.create({
            eventId,
            location: {
                type: 'Point',
                coordinates: [longitude, latitude],
            },
            magnitude,
            depth,
            place,
            timestamp,
            radiusKm: EARTHQUAKE.ALERT_RADIUS_KM,
            affectedUsers: nearbyUsers.map(u => u._id),
            notificationsSent: 0,
        });

        // Prepare notification
        const notificationTitle = '🚨 Earthquake Alert!';
        const notificationBody = `Magnitude ${magnitude} earthquake detected ${Math.round(depth)}km deep near ${place}. Take safety precautions!`;

        // Send push notifications to all nearby users
        const fcmTokens = nearbyUsers
            .filter(u => u.fcmToken)
            .map(u => u.fcmToken);

        if (fcmTokens.length > 0) {
            try {
                const response = await sendMulticastNotification(
                    fcmTokens,
                    {
                        title: notificationTitle,
                        body: notificationBody,
                    },
                    {
                        eventId,
                        magnitude: magnitude.toString(),
                        latitude: latitude.toString(),
                        longitude: longitude.toString(),
                    }
                );

                alert.notificationsSent = response.successCount;
                await alert.save();

                logger.info(`✅ Sent notifications to ${response.successCount}/${fcmTokens.length} users`);

            } catch (error) {
                logger.error('Failed to send multicast notification:', error);
            }
        }

        // Emit real-time event via Socket.io
        if (io) {
            nearbyUsers.forEach(user => {
                io.to(`user_${user._id}`).emit('earthquake_alert', {
                    magnitude,
                    place,
                    latitude,
                    longitude,
                    depth,
                    timestamp,
                    distance: calculateDistance(
                        latitude,
                        longitude,
                        user.location.coordinates[1],
                        user.location.coordinates[0]
                    ).toFixed(1),
                });
            });
        }

        // Mark as processed
        processedEarthquakes.add(eventId);

        logger.info(`✅ Earthquake alert processed: ${nearbyUsers.length} users notified`);

    } catch (error) {
        logger.error('Error processing earthquake:', error);
    }
};

// Main monitor function
const monitorEarthquakes = async (io) => {
    try {
        logger.info('🔍 Checking for earthquakes...');

        const earthquakes = await fetchEarthquakes();

        if (earthquakes.length === 0) {
            logger.info('No recent earthquakes found');
            return;
        }

        logger.info(`Found ${earthquakes.length} recent earthquake(s)`);

        // Process each earthquake
        for (const earthquake of earthquakes) {
            await processEarthquake(earthquake, io);
        }

        // Clear old processed IDs (keep last 1000)
        if (processedEarthquakes.size > 1000) {
            const array = Array.from(processedEarthquakes);
            processedEarthquakes.clear();
            array.slice(-500).forEach(id => processedEarthquakes.add(id));
        }

    } catch (error) {
        logger.error('Earthquake monitor error:', error);
    }
};

// Start cron job - runs every 2 minutes
const startEarthquakeMonitor = (io) => {
    logger.info('📅 Starting earthquake monitor cron job (every 2 minutes)');

    // Run every 2 minutes: */2 * * * *
    cron.schedule('*/2 * * * *', () => {
        monitorEarthquakes(io);
    });

    // Run immediately on startup
    if (process.env.NODE_ENV === 'development') {
        logger.info('🔧 Running initial earthquake check (dev mode)');
        // Uncomment to run on startup:
        // monitorEarthquakes(io);
    }
};

module.exports = startEarthquakeMonitor;