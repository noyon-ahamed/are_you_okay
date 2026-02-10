const axios = require('axios');
const EarthquakeAlert = require('../model/EarthquakeAlert');

const fetchEarthquakeData = async () => {
    try {
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
            const alert = await EarthquakeAlert.create({
                eventId: id,
                magnitude: properties.mag,
                place: properties.place,
                time: new Date(properties.time),
                location: {
                    type: 'Point',
                    coordinates: geometry.coordinates.slice(0, 2) // [lon, lat]
                },
                depth: geometry.coordinates[2],
                tsunami: properties.tsunami,
                alertLevel: properties.alert
            });
            newAlerts.push(alert);
        }
    }
    return newAlerts;
};

module.exports = { fetchEarthquakeData, processEarthquakeData };
