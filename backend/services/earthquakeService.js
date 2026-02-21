const axios = require('axios');
const EarthquakeAlert = require('../model/EarthquakeAlert');
const User = require('../model/User');
const { sendNotification } = require('../config/firebase');
const { logger } = require('../middleware/logger');

const fetchEarthquakeData = async () => {
    try {
        // Fetch M4.5+ earthquakes from the past day to keep DB lean but updated
        const response = await axios.get(process.env.EARTHQUAKE_API_URL || 'https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&minmagnitude=4.5&orderby=time&limit=20');
        return response.data;
    } catch (error) {
        console.error('Error fetching earthquake data:', error);
        throw error;
    }
};

const processEarthquakeData = async (data) => {
    const features = data.features;
    let newAlerts = [];

    for (const feature of features) {
        const { id, properties, geometry } = feature;

        const existing = await EarthquakeAlert.findOne({ eventId: id });
        if (!existing) {
            const earthquakeLon = geometry.coordinates[0];
            const earthquakeLat = geometry.coordinates[1];
            const magnitude = properties.mag;

            const alert = await EarthquakeAlert.create({
                eventId: id,
                magnitude: magnitude,
                place: properties.place,
                time: new Date(properties.time),
                location: {
                    type: 'Point',
                    coordinates: [earthquakeLon, earthquakeLat]
                },
                depth: geometry.coordinates[2],
                tsunami: properties.tsunami,
                alertLevel: properties.alert
            });
            newAlerts.push(alert);

            // Notify nearby users if magnitude >= 4.5
            if (magnitude >= 4.5) {
                try {
                    // Find users within 1000 km (1,000,000 meters)
                    const nearbyUsers = await User.find({
                        isActive: true,
                        fcmToken: { $exists: true, $ne: '' },
                        'settings.notificationEnabled': true,
                        'settings.earthquakeAlerts': true,
                        location: {
                            $near: {
                                $geometry: {
                                    type: 'Point',
                                    coordinates: [earthquakeLon, earthquakeLat]
                                },
                                $maxDistance: 1000000 // 1000 km in meters
                            }
                        }
                    });

                    if (nearbyUsers.length > 0) {
                        logger.info(`Alerting ${nearbyUsers.length} users about Earthquake: ${properties.place}`);
                        let notifiedCount = 0;

                        for (const user of nearbyUsers) {
                            try {
                                await sendNotification(user.fcmToken, {
                                    title: '⚠️ ভূমিকম্প সতর্কতা!',
                                    body: `${properties.place} এ ${magnitude} মাত্রার ভূমিকম্প শনাক্ত হয়েছে। নিরাপদে থাকুন!`,
                                    data: {
                                        type: 'earthquake',
                                        eventId: id
                                    }
                                });
                                notifiedCount++;
                            } catch (err) {
                                logger.error(`Failed to send earthquake FCM to user ${user._id}:`, err);
                            }
                        }

                        // Update alert with notified count
                        await EarthquakeAlert.findByIdAndUpdate(alert._id, {
                            usersNotifiedCount: notifiedCount
                        });
                    }
                } catch (err) {
                    logger.error('Error finding nearby users for earthquake alert:', err);
                }
            }
        }
    }
    return newAlerts;
};

module.exports = { fetchEarthquakeData, processEarthquakeData };
