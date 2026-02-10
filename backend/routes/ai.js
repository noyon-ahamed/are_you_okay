const express = require('express');
const router = express.Router();
const aiService = require('../services/aiService');
const protect = require('../middleware/authMiddleware');
const { formatResponse } = require('../utils/responseFormatter');

router.post('/chat', protect, async (req, res, next) => {
    try {
        const { message, conversationId } = req.body;
        const result = await aiService.getAIResponse(req.user.id, message, conversationId);
        res.json(formatResponse(true, 'AI response received', result));
    } catch (error) {
        next(error);
    }
});

module.exports = router;
