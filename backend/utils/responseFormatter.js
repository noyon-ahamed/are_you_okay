const formatResponse = (success, message, data = null, statusCode = 200) => {
    return {
        success,
        message,
        data,
        timestamp: new Date().toISOString()
    };
};

module.exports = { formatResponse };
