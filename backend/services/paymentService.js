const Stripe = require('stripe');
const stripe = Stripe(process.env.STRIPE_SECRET_KEY || 'sk_test_dummy');
const User = require('../model/User');

const createPaymentIntent = async (amount, currency = 'usd') => {
    return await stripe.paymentIntents.create({
        amount,
        currency,
        automatic_payment_methods: { enabled: true },
    });
};

const handleWebhook = async (event) => {
    // Handle specific stripe events
    if (event.type === 'payment_intent.succeeded') {
        const paymentIntent = event.data.object;
        // Update user subscription or credit balance
        console.log('Payment succeeded:', paymentIntent.id);
    }
};

module.exports = { createPaymentIntent, handleWebhook };
