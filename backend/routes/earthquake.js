const express = require('express');
const router = express.Router();
const earthquakeService = require('../services/earthquakeService');
const EarthquakeAlert = require('../model/EarthquakeAlert');
const { formatResponse } = require('../utils/responseFormatter');

const authenticate = require('../middleware/authMiddleware');

router.get('/latest', authenticate, async (req, res, next) => {
    try {
        const { lat, lng } = req.query;
        let query = {};

        // If frontend passes location, use it. Otherwise, look up user DB location.
        let filterLat = lat ? parseFloat(lat) : null;
        let filterLng = lng ? parseFloat(lng) : null;

        if (!filterLat || !filterLng) {
            const User = require('../model/User');
            const user = await User.findById(req.user._id);
            if (user && user.location && user.location.coordinates.length === 2 && user.location.coordinates[0] !== 0) {
                filterLng = user.location.coordinates[0];
                filterLat = user.location.coordinates[1];
            }
        }

        // Apply $near filtering if we have valid coordinates
        if (filterLat && filterLng) {
            query.location = {
                $near: {
                    $geometry: {
                        type: 'Point',
                        coordinates: [filterLng, filterLat] // MongoDB format is [lon, lat]
                    },
                    $maxDistance: 1000000 // 1000 km
                }
            };
        }

        const alerts = await EarthquakeAlert.find(query).sort({ time: -1 }).limit(20);
        res.json(formatResponse(true, 'Latest earthquake alerts', alerts));
    } catch (error) {
        next(error);
    }
});

router.post('/fetch-now', async (req, res, next) => {
    try {
        const data = await earthquakeService.fetchEarthquakeData();
        const newAlerts = await earthquakeService.processEarthquakeData(data);
        res.json(formatResponse(true, 'Earthquake data fetched', { newAlertsCount: newAlerts.length }));
    } catch (error) {
        next(error);
    }
});

module.exports = router;
