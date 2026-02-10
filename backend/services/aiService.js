const Anthropic = require('@anthropic-ai/sdk');
const AIConversation = require('../model/AIConversation');

const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY,
});

const getAIResponse = async (userId, userMessage, conversationId = null) => {
    let conversation;
    if (conversationId) {
        conversation = await AIConversation.findById(conversationId);
    } else {
        conversation = await AIConversation.create({ user: userId, messages: [] });
    }

    // Add user message to history
    conversation.messages.push({ role: 'user', content: userMessage });

    // Prepare context for API (last 10 messages for context window management)
    const contextMessages = conversation.messages.slice(-10).map(m => ({
        role: m.role,
        content: m.content
    }));

    const msg = await anthropic.messages.create({
        model: "claude-3-haiku-20240307",
        max_tokens: 1024,
        messages: contextMessages
    });

    const aiResponse = msg.content[0].text;

    // Save AI response
    conversation.messages.push({ role: 'assistant', content: aiResponse });
    await conversation.save();

    return { response: aiResponse, conversationId: conversation._id };
};

module.exports = { getAIResponse };
