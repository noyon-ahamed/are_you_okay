const express = require('express');
const router = express.Router();
const paymentService = require('../services/paymentService');

// Stripe webhook requires raw body, usually handled by middleware in server.js or here
// Assuming body-parser is configured correctly or using express.raw type for this route

router.post('/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event;

    try {
        const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
        event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
    } catch (err) {
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    await paymentService.handleWebhook(event);
    res.json({ received: true });
});

module.exports = router;
