const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/authMiddleware');
const Mood = require('../model/Mood');

// Save mood entry
router.post('/', authenticate, async (req, res) => {
    try {
        const { mood, note } = req.body;

        if (!mood) {
            return res.status(400).json({ error: 'Mood is required' });
        }

        const validMoods = ['happy', 'good', 'neutral', 'sad', 'anxious', 'angry'];
        if (!validMoods.includes(mood)) {
            return res.status(400).json({ error: `Invalid mood. Must be one of: ${validMoods.join(', ')}` });
        }

        // Check if mood already saved today (allow update)
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        let moodEntry = await Mood.findOne({
            userId: req.user._id,
            timestamp: { $gte: today },
        });

        if (moodEntry) {
            // Update existing mood for today
            moodEntry.mood = mood;
            moodEntry.note = note || '';
            moodEntry.timestamp = new Date();
            await moodEntry.save();
        } else {
            // Create new mood entry
            moodEntry = await Mood.create({
                userId: req.user._id,
                mood,
                note: note || '',
            });
        }

        res.json({
            success: true,
            mood: moodEntry,
            message: 'Mood saved successfully',
        });

    } catch (error) {
        console.error('Save Mood Error:', error);
        res.status(500).json({ error: 'Failed to save mood' });
    }
});

// Get mood history
router.get('/history', authenticate, async (req, res) => {
    try {
        const { limit = 30, skip = 0 } = req.query;

        const moods = await Mood.find({ userId: req.user._id })
            .sort({ timestamp: -1 })
            .limit(parseInt(limit))
            .skip(parseInt(skip))
            .select('-__v');

        const total = await Mood.countDocuments({ userId: req.user._id });

        res.json({
            success: true,
            moods,
            pagination: {
                total,
                limit: parseInt(limit),
                skip: parseInt(skip),
                hasMore: total > parseInt(skip) + parseInt(limit),
            },
        });

    } catch (error) {
        console.error('Mood History Error:', error);
        res.status(500).json({ error: 'Failed to fetch mood history' });
    }
});

// Get mood stats (distribution over last N days)
router.get('/stats', authenticate, async (req, res) => {
    try {
        const { days = 30 } = req.query;
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - parseInt(days));

        const moods = await Mood.find({
            userId: req.user._id,
            timestamp: { $gte: startDate },
        }).select('mood timestamp');

        // Count distribution
        const distribution = {};
        const validMoods = ['happy', 'good', 'neutral', 'sad', 'anxious', 'angry'];
        validMoods.forEach(m => distribution[m] = 0);

        moods.forEach(entry => {
            distribution[entry.mood] = (distribution[entry.mood] || 0) + 1;
        });

        // Get today's mood
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayMood = await Mood.findOne({
            userId: req.user._id,
            timestamp: { $gte: today },
        });

        res.json({
            success: true,
            stats: {
                totalEntries: moods.length,
                distribution,
                days: parseInt(days),
                todayMood: todayMood?.mood || null,
            },
        });

    } catch (error) {
        console.error('Mood Stats Error:', error);
        res.status(500).json({ error: 'Failed to fetch mood stats' });
    }
});

module.exports = router;
