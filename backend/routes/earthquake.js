const express = require('express');
const router = express.Router();
const earthquakeService = require('../services/earthquakeService');
const EarthquakeAlert = require('../model/EarthquakeAlert');
const { formatResponse } = require('../utils/responseFormatter');

router.get('/latest', async (req, res, next) => {
    try {
        const alerts = await EarthquakeAlert.find().sort({ time: -1 }).limit(20);
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
