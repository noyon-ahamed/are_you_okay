const moment = require('moment'); // You might need to install moment or use native Date

const formatDate = (date) => {
    return moment(date).format('YYYY-MM-DD HH:mm:ss');
};

const addDays = (date, days) => {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
};

const isExpired = (date) => {
    return new Date() > new Date(date);
};

module.exports = { formatDate, addDays, isExpired };
