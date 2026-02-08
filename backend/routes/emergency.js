const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/authMiddleware');
const EmergencyContact = require('../models/EmergencyContact');
const EmergencyAlert = require('../models/EmergencyAlert');
const User = require('../models/User');
const Subscription = require('../models/Subscription');
const twilioClient = require('../config/twilio');
const { PRICING, ALERT_MESSAGES } = require('../config/constants');

// Get all emergency contacts
router.get('/contacts', authenticate, async (req, res) => {
    try {
        const contacts = await EmergencyContact.find({ userId: req.user._id })
            .sort({ priority: 1 })
            .select('-__v');

        res.json({
            success: true,
            contacts,
            count: contacts.length,
        });

    } catch (error) {
        console.error('Get Contacts Error:', error);
        res.status(500).json({ error: 'Failed to fetch contacts' });
    }
});

// Add emergency contact
router.post('/contacts', authenticate, async (req, res) => {
    try {
        const { name, phone, email, relation, priority } = req.body;

        // Validate required fields
        if (!name || !phone) {
            return res.status(400).json({ error: 'Name and phone required' });
        }

        // Check subscription limits
        const subscription = await Subscription.findOne({ userId: req.user._id });
        const contactCount = await EmergencyContact.countDocuments({
            userId: req.user._id
        });

        const maxContacts = subscription?.plan === 'premium' ? 10 : 3;

        if (contactCount >= maxContacts) {
            return res.status(403).json({
                error: `Maximum ${maxContacts} contacts allowed on ${subscription?.plan} plan`,
                upgradeRequired: subscription?.plan === 'free',
            });
        }

        // Create contact
        const contact = await EmergencyContact.create({
            userId: req.user._id,
            name,
            phone,
            email: email || '',
            relation: relation || 'Other',
            priority: priority || contactCount + 1,
        });

        res.json({
            success: true,
            contact,
            message: 'Emergency contact added',
        });

    } catch (error) {
        console.error('Add Contact Error:', error);
        res.status(500).json({ error: 'Failed to add contact' });
    }
});

// Update emergency contact
router.put('/contacts/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        const { name, phone, email, relation, priority } = req.body;

        const contact = await EmergencyContact.findOne({
            _id: id,
            userId: req.user._id,
        });

        if (!contact) {
            return res.status(404).json({ error: 'Contact not found' });
        }

        // Update fields
        if (name) contact.name = name;
        if (phone) contact.phone = phone;
        if (email !== undefined) contact.email = email;
        if (relation) contact.relation = relation;
        if (priority !== undefined) contact.priority = priority;

        await contact.save();

        res.json({
            success: true,
            contact,
            message: 'Contact updated',
        });

    } catch (error) {
        console.error('Update Contact Error:', error);
        res.status(500).json({ error: 'Failed to update contact' });
    }
});

// Delete emergency contact
router.delete('/contacts/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;

        const contact = await EmergencyContact.findOneAndDelete({
            _id: id,
            userId: req.user._id,
        });

        if (!contact) {
            return res.status(404).json({ error: 'Contact not found' });
        }

        res.json({
            success: true,
            message: 'Contact deleted',
        });

    } catch (error) {
        console.error('Delete Contact Error:', error);
        res.status(500).json({ error: 'Failed to delete contact' });
    }
});

// Send verification OTP to contact
router.post('/contacts/:id/verify', authenticate, async (req, res) => {
    try {
        const { id } = req.params;

        const contact = await EmergencyContact.findOne({
            _id: id,
            userId: req.user._id,
        });

        if (!contact) {
            return res.status(404).json({ error: 'Contact not found' });
        }

        // Generate OTP (simple 6-digit)
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Send SMS
        const message = await twilioClient.messages.create({
            body: `Your verification code for Are You Okay emergency contact: ${otp}. Valid for 10 minutes.`,
            from: process.env.TWILIO_PHONE_NUMBER,
            to: contact.phone,
        });

        // Store OTP (you'll need to add this field to model)
        contact.verificationOTP = otp;
        contact.verificationExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 min
        await contact.save();

        res.json({
            success: true,
            message: 'Verification code sent',
            // Don't send OTP in production, only in dev
            ...(process.env.NODE_ENV === 'development' && { otp }),
        });

    } catch (error) {
        console.error('Verify Contact Error:', error);
        res.status(500).json({ error: 'Failed to send verification' });
    }
});

// Trigger SOS alert
router.post('/sos', authenticate, async (req, res) => {
    try {
        const { location, customMessage } = req.body;

        if (!location || !location.latitude || !location.longitude) {
            return res.status(400).json({ error: 'Location required' });
        }

        const user = await User.findById(req.user._id);
        const subscription = await Subscription.findOne({ userId: req.user._id });

        // Get all emergency contacts
        const contacts = await EmergencyContact.find({ userId: req.user._id })
            .sort({ priority: 1 });

        if (contacts.length === 0) {
            return res.status(400).json({
                error: 'No emergency contacts found. Please add contacts first.'
            });
        }

        // Create emergency alert
        const alert = await EmergencyAlert.create({
            userId: req.user._id,
            alertType: 'manual_sos',
            triggeredBy: 'user',
            location: {
                type: 'Point',
                coordinates: [location.longitude, location.latitude],
            },
            message: ALERT_MESSAGES.SOS.EN,
            customMessage: customMessage || '',
            contactsNotified: [],
        });

        // Send alerts to contacts
        const alertPromises = contacts.map(async (contact) => {
            const contactInfo = {
                contactId: contact._id,
                name: contact.name,
                phone: contact.phone,
                email: contact.email,
            };

            try {
                // Send SMS
                const smsMessage = customMessage ||
                    `EMERGENCY: ${user.name} has sent an SOS alert! Location: https://maps.google.com/?q=${location.latitude},${location.longitude}`;

                const sms = await twilioClient.messages.create({
                    body: smsMessage,
                    from: process.env.TWILIO_PHONE_NUMBER,
                    to: contact.phone,
                });

                contactInfo.smsStatus = 'sent';
                contactInfo.smsSentAt = new Date();
                contactInfo.smsMessageId = sms.sid;

            } catch (error) {
                console.error(`Failed to send SMS to ${contact.name}:`, error);
                contactInfo.smsStatus = 'failed';
            }

            return contactInfo;
        });

        const results = await Promise.all(alertPromises);

        // Update alert with notification results
        alert.contactsNotified = results;
        await alert.save();

        // Emit real-time event
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${req.user._id}`).emit('sos_sent', {
                alertId: alert._id,
                contactsNotified: results.length,
            });
        }

        res.json({
            success: true,
            alert,
            contactsNotified: results.length,
            message: 'SOS alert sent to emergency contacts',
        });

    } catch (error) {
        console.error('SOS Error:', error);
        res.status(500).json({ error: 'Failed to send SOS alert' });
    }
});

// Get alert history
router.get('/alerts/history', authenticate, async (req, res) => {
    try {
        const { limit = 20, skip = 0 } = req.query;

        const alerts = await EmergencyAlert.find({ userId: req.user._id })
            .sort({ triggeredAt: -1 })
            .limit(parseInt(limit))
            .skip(parseInt(skip))
            .select('-__v');

        const total = await EmergencyAlert.countDocuments({ userId: req.user._id });

        res.json({
            success: true,
            alerts,
            pagination: {
                total,
                limit: parseInt(limit),
                skip: parseInt(skip),
                hasMore: total > parseInt(skip) + parseInt(limit),
            },
        });

    } catch (error) {
        console.error('Alert History Error:', error);
        res.status(500).json({ error: 'Failed to fetch alert history' });
    }
});

// Mark alert as resolved
router.put('/alerts/:id/resolve', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        const { note } = req.body;

        const alert = await EmergencyAlert.findOne({
            _id: id,
            userId: req.user._id,
        });

        if (!alert) {
            return res.status(404).json({ error: 'Alert not found' });
        }

        alert.resolved = true;
        alert.resolvedAt = new Date();
        alert.resolvedBy = 'user';
        alert.resolutionNote = note || 'Marked as safe by user';
        await alert.save();

        res.json({
            success: true,
            alert,
            message: 'Alert marked as resolved',
        });

    } catch (error) {
        console.error('Resolve Alert Error:', error);
        res.status(500).json({ error: 'Failed to resolve alert' });
    }
});

module.exports = router;