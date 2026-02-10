const express = require('express');
const router = express.Router();
const paymentService = require('../services/paymentService');
const subscriptionService = require('../services/subscriptionService');
const protect = require('../middleware/authMiddleware');
const { formatResponse } = require('../utils/responseFormatter');

router.post('/create-intent', protect, async (req, res, next) => {
    try {
        const { amount, currency } = req.body;
        const intent = await paymentService.createPaymentIntent(amount, currency);
        res.json(formatResponse(true, 'Payment intent created', { clientSecret: intent.client_secret }));
    } catch (error) {
        next(error);
    }
});

router.post('/subscribe', protect, async (req, res, next) => {
    try {
        const { plan } = req.body;
        const subscription = await subscriptionService.subscribeUser(req.user.id, plan);
        res.json(formatResponse(true, 'Subscription updated', subscription));
    } catch (error) {
        next(error);
    }
});

module.exports = router;
