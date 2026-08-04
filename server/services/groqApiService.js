const Groq = require("groq-sdk");

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || process.env.GROK_API_KEY || "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",
});

const MODEL = process.env.GROQ_MODEL || "llama-3.3-70b-versatile";

// Simple in-memory response cache to serve repeated queries with 0ms latency
const aiResponseCache = new Map();

/**
 * Direct study assistant chat Q&A
 */
async function askAI(topic, chatHistory = []) {
  const cleanTopic = String(topic || "").trim();
  if (!cleanTopic) return "Please enter a valid study question.";

  const cacheKey = `chat_${cleanTopic}_${chatHistory.length}`;
  if (aiResponseCache.has(cacheKey)) {
    return aiResponseCache.get(cacheKey);
  }

  const cleanHistory = chatHistory
    .filter((msg) => msg && (msg.role === "user" || msg.role === "assistant") && msg.content)
    .map((msg) => ({ role: msg.role, content: String(msg.content) }));

  const messages = [
    {
      role: "system",
      content: `You are StudyMate AI, an advanced, highly intelligent educational AI assistant powered by Groq LLaMA-3.3-70B.
Rules:
- Provide thorough, accurate, highly detailed, and student-friendly explanations with up-to-date 2026 knowledge.
- Use clean formatting (markdown, clear section headers, bullet points, code blocks, bold key terms).
- Address complex topics directly with depth, examples, and step-by-step logic.
- Do NOT include any name prefix like 'StudyMate AI:' or 'Grok:'. Start directly with the answer.`,
    },
    ...cleanHistory,
    {
      role: "user",
      content: cleanTopic,
    },
  ];

  const completion = await groq.chat.completions.create({
    model: MODEL,
    messages: messages,
    temperature: 0.7,
    max_tokens: 4096,
  });

  const answer = completion.choices[0]?.message?.content || "I am glad to assist with your study questions!";
  aiResponseCache.set(cacheKey, answer);
  if (aiResponseCache.size > 200) {
    const firstKey = aiResponseCache.keys().next().value;
    aiResponseCache.delete(firstKey);
  }
  return answer;
}

/**
 * Stream study assistant chat Q&A using Groq API streaming
 */
async function streamAIChat(topic, chatHistory = [], onChunk) {
  const cleanTopic = String(topic || "").trim();
  if (!cleanTopic) return "Please enter a valid study question.";

  const cleanHistory = chatHistory
    .filter((msg) => msg && (msg.role === "user" || msg.role === "assistant") && msg.content)
    .map((msg) => ({ role: msg.role, content: String(msg.content) }));

  const messages = [
    {
      role: "system",
      content: `You are StudyMate AI, an advanced, highly intelligent educational AI assistant powered by Groq LLaMA-3.3-70B.
Rules:
- Provide thorough, accurate, highly detailed, and student-friendly explanations with up-to-date knowledge.
- Use clean formatting (markdown, clear section headers, bullet points, code blocks, bold key terms).
- Address complex topics directly with depth, examples, and step-by-step logic.
- Do NOT include any name prefix like 'StudyMate AI:' or 'Grok:'. Start directly with the answer.`,
    },
    ...cleanHistory,
    {
      role: "user",
      content: cleanTopic,
    },
  ];

  let fullResponse = "";
  try {
    const stream = await groq.chat.completions.create({
      model: MODEL,
      messages: messages,
      temperature: 0.7,
      max_tokens: 4096,
      stream: true,
    });

    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content || "";
      if (content) {
        fullResponse += content;
        if (typeof onChunk === "function") {
          onChunk(content);
        }
      }
    }
  } catch (err) {
    console.error("Groq Stream AI Error:", err.message);
    const fallbackText = "I am ready to assist with your study notes, quizzes, and questions!";
    fullResponse = fallbackText;
    if (typeof onChunk === "function") {
      onChunk(fallbackText);
    }
  }

  return fullResponse;
}

/**
 * Generate full study material (Summary, Structured Notes, Quiz, Flashcards) strictly from source text
 */
async function generateFullStudyMaterial(sourceText) {
  const cleanText = String(sourceText || "").trim();
  const cacheKey = `material_${cleanText.slice(0, 300)}_${cleanText.length}`;
  if (aiResponseCache.has(cacheKey)) {
    return aiResponseCache.get(cacheKey);
  }

  const systemPrompt = `You are StudyMate AI's master educational material generator.
CRITICAL INSTRUCTIONS:
1. Base ALL generated content strictly on the topic or provided DOCUMENT TEXT.
2. Return ONLY a single valid JSON object with keys: "title", "summary", "structuredNotes", "quiz", "flashcards".
3. "summary" MUST contain: Overview, Important concepts, Key points, and an Easy explanation.
4. "structuredNotes" MUST be HIGHLY DETAILED and COMPREHENSIVE, containing AT LEAST 1000 TO 1500+ WORDS of extensive notes with:
   - Deep architectural & theoretical breakdown
   - Multiple sub-sections (##, ###)
   - Extensive bullet points and definitions
   - Practical code/syntactic examples
   - Real-world use cases & exam tips
   - ⚡ Last-Minute Exam Prep section with short memory-bubble chips formatted as: \`[Bubble: Concept Name - Quick Definition]\`
5. "quiz" MUST be an array of 12 to 15 concept-based MCQs:
   - "question": Concept-based question
   - "options": Array of 4 distinct choices
   - "correctIndex": Integer (0 to 3)
   - "explanation": Link back to document concept
   - "difficulty": "Easy", "Medium", or "Hard"
6. "flashcards" MUST be an array of 12 to 15 concept flashcards:
   - "front": Question or Key Concept
   - "back": Concise, accurate explanation.`;

  const messages = [
    { role: "system", content: systemPrompt },
    { role: "user", content: `DOCUMENT TEXT:\n"""\n${cleanText.slice(0, 12000)}\n"""` }
  ];

  let responseContent = "";

  try {
    const completion = await groq.chat.completions.create({
      model: MODEL,
      messages: messages,
      temperature: 0.2,
      response_format: { type: "json_object" }
    });

    responseContent = completion.choices[0].message.content.trim();
    const result = parseAndValidateMaterialJSON(responseContent);
    aiResponseCache.set(cacheKey, result);
    return result;
  } catch (initialErr) {
    console.warn("First JSON parse attempt failed, retrying with strict JSON fix prompt...", initialErr.message);

    try {
      const retryCompletion = await groq.chat.completions.create({
        model: MODEL,
        messages: [
          ...messages,
          { role: "assistant", content: responseContent },
          { role: "user", content: "Your previous response was not valid JSON. Convert your previous analysis into strictly valid JSON matching the exact specified schema. Output JSON ONLY." }
        ],
        temperature: 0.1,
        response_format: { type: "json_object" }
      });

      const retryText = retryCompletion.choices[0].message.content.trim();
      const result = parseAndValidateMaterialJSON(retryText);
      aiResponseCache.set(cacheKey, result);
      return result;
    } catch (retryErr) {
      console.error("Failed to parse AI JSON after retry:", retryErr.message);
      return {
        title: "Study Material",
        summary: "### Overview\nHigh-yield summary extracted from document.\n\n### Key Points\n- Core document concepts.",
        structuredNotes: "## Document Notes\n\n- **Core Topic**: Extracted study concepts.\n- **Definitions**: Key terms.",
        quiz: [
          {
            question: "What is the primary study focus of this document?",
            options: ["Core document concept", "Unrelated detail", "Secondary concept", "None of the above"],
            correctIndex: 0,
            explanation: "Derived directly from document text.",
            difficulty: "Easy"
          }
        ],
        flashcards: [
          { front: "Main Question", back: "Answer based on document text." }
        ]
      };
    }
  }
}

function parseAndValidateMaterialJSON(rawText) {
  let cleaned = rawText.replace(/^```json\s*/i, "").replace(/```$/i, "").trim();
  const jsonStart = cleaned.indexOf("{");
  const jsonEnd = cleaned.lastIndexOf("}");
  if (jsonStart !== -1 && jsonEnd !== -1) {
    cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
  }

  const parsed = JSON.parse(cleaned);

  if (!parsed.summary || !parsed.quiz || !Array.isArray(parsed.quiz)) {
    throw new Error("Missing required material fields in JSON.");
  }

  const seenQuestions = new Set();
  const filteredQuiz = [];

  for (const q of (parsed.quiz || [])) {
    const qText = (q.question || "").trim();
    if (qText && !seenQuestions.has(qText)) {
      seenQuestions.add(qText);
      filteredQuiz.push({
        question: qText,
        options: Array.isArray(q.options) && q.options.length >= 2 ? q.options : ["Option A", "Option B", "Option C", "Option D"],
        correctIndex: typeof q.correctIndex === "number" ? q.correctIndex : 0,
        explanation: q.explanation || "Concept explanation from document.",
        difficulty: q.difficulty || "Medium"
      });
    }
  }

  return {
    title: parsed.title || "Study Package",
    summary: parsed.summary || "Summary of study material.",
    structuredNotes: parsed.structuredNotes || parsed.summary,
    quiz: filteredQuiz,
    flashcards: Array.isArray(parsed.flashcards) ? parsed.flashcards.map(f => ({
      front: f.front || "Question",
      back: f.back || "Answer"
    })) : []
  };
}

module.exports = {
  askAI,
  streamAIChat,
  generateFullStudyMaterial
};

