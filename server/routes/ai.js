const express = require("express");
const verifyJWT = require("../middleware/verifyJWT");
const { askAI, streamAIChat, generateFullStudyMaterial } = require("../services/groqApiService");
const { saveAIChatMessage, getAIChatHistory } = require("../db/postgres");

const router = express.Router();

/**
 * POST /api/ai/chat or /api/ai/ask
 * Freeform AI conversation powered by Groq LLaMA 3.3-70B with PostgreSQL history
 */
async function handleAIChat(req, res, next) {
  try {
    const message = req.body.message || req.body.topic || req.body.prompt;
    const userId = req.user?.id || req.body.userId || "anonymous_student";

    if (!message || String(message).trim().length === 0) {
      return res.status(400).json({ success: false, error: "Message content is required." });
    }

    const cleanMessage = String(message).trim();

    // Fetch previous messages for context
    const previousMessages = await getAIChatHistory(userId, 10);
    const formattedHistory = previousMessages.map((msg) => ({ role: msg.role, content: msg.content }));

    // Save user message
    const userMsg = await saveAIChatMessage({
      userId,
      role: "user",
      content: cleanMessage,
    });

    // Call Groq LLaMA AI assistant
    const aiAnswerText = await askAI(cleanMessage, formattedHistory);

    // Save assistant response
    const assistantMsg = await saveAIChatMessage({
      userId,
      role: "assistant",
      content: aiAnswerText,
    });

    res.json({
      success: true,
      answer: aiAnswerText,
      userMessage: userMsg,
      assistantMessage: assistantMsg,
    });
  } catch (error) {
    console.error("AI Chat Route Error:", error);
    res.status(500).json({
      success: false,
      error: "Unable to reach StudyMate AI server.",
    });
  }
}

/**
 * POST /api/ai/chat/stream
 * Streaming endpoint for live response generation
 */
router.post("/chat/stream", verifyJWT, async (req, res) => {
  const message = req.body.message || req.body.topic;
  if (!message || String(message).trim().length === 0) {
    return res.status(400).json({ success: false, error: "Message content is required." });
  }

  const userId = req.user?.id || req.body.userId || "anonymous_student";
  const cleanMessage = String(message).trim();

  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  try {
    const previousMessages = await getAIChatHistory(userId, 10);
    const formattedHistory = previousMessages.map((msg) => ({ role: msg.role, content: msg.content }));

    await saveAIChatMessage({ userId, role: "user", content: cleanMessage });

    const fullResponse = await streamAIChat(cleanMessage, formattedHistory, (chunk) => {
      res.write(`data: ${JSON.stringify({ chunk })}\n\n`);
    });

    await saveAIChatMessage({ userId, role: "assistant", content: fullResponse });
    res.write("data: [DONE]\n\n");
    res.end();
  } catch (err) {
    console.error("Streaming error:", err);
    res.write(`data: ${JSON.stringify({ error: "Server connection error" })}\n\n`);
    res.end();
  }
});

// Support both /chat and /ask endpoints
router.post("/chat", verifyJWT, handleAIChat);
router.post("/ask", verifyJWT, handleAIChat);

/**
 * GET /api/ai/chat/history
 */
router.get("/chat/history", async (req, res, next) => {
  try {
    const userId = req.user?.id || req.query.userId || "anonymous_student";
    const limit = parseInt(req.query.limit || "50");
    const messages = await getAIChatHistory(userId, limit);

    res.json({
      success: true,
      count: messages.length,
      messages,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/ai/generate
 */
router.post("/generate", async (req, res, next) => {
  try {
    const { text } = req.body;

    if (!text) {
      return res.status(400).json({ success: false, error: "Text content is required." });
    }

    const result = await generateFullStudyMaterial(text);

    res.json({
      success: true,
      result,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
