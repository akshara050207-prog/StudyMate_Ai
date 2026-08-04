const express = require("express");
const crypto = require("crypto");
const { saveRoom, findRoomByCode, getFeaturedRooms } = require("../db/postgres");
const verifyJWT = require("../middleware/verifyJWT");
const { generateRoomQuiz } = require("../services/mistralApiService");

const router = express.Router();

function generateRoomCode() {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
}

/**
 * GET /api/rooms/featured
 * Returns public Featured Group Rooms stored in PostgreSQL
 */
router.get("/featured", verifyJWT, async (req, res, next) => {
  try {
    let publicRooms = await getFeaturedRooms();

    // Auto-seed default Featured Group Rooms if database is empty
    if (publicRooms.length === 0) {
      const defaultHostId = req.user?.id || `usr_host_${crypto.randomBytes(4).toString("hex")}`;
      const defaultRooms = [
        {
          code: "CSAI01",
          title: "Artificial Intelligence & ML",
          topic: "Machine Learning, Neural Networks & Deep Learning (Mistral AI)",
          description: "Public collaborative study group for AI concepts and models.",
          subjectTag: "Computer Science",
          isPublic: true,
          hostId: defaultHostId,
          participants: [{ userId: defaultHostId, name: req.user?.name || "Study Host", avatar: "" }],
        },
        {
          code: "DSAL02",
          title: "Data Structures & Algorithms",
          topic: "Trees, Graphs, Dynamic Programming & Complexity",
          description: "Practice algorithmic thinking and data structure design together.",
          subjectTag: "Algorithms",
          isPublic: true,
          hostId: defaultHostId,
          participants: [{ userId: defaultHostId, name: req.user?.name || "Study Host", avatar: "" }],
        },
        {
          code: "WEBDEV3",
          title: "Full Stack Web Development",
          topic: "Node.js, Express, PostgreSQL, Flutter & APIs",
          description: "Discuss modern web frameworks, architecture & APIs.",
          subjectTag: "Web Dev",
          isPublic: true,
          hostId: defaultHostId,
          participants: [{ userId: defaultHostId, name: req.user?.name || "Study Host", avatar: "" }],
        },
        {
          code: "MATH04",
          title: "Mathematics & Statistics",
          topic: "Linear Algebra, Probability & Calculus",
          description: "Core mathematical foundations for computing and data science.",
          subjectTag: "Mathematics",
          isPublic: true,
          hostId: defaultHostId,
          participants: [{ userId: defaultHostId, name: req.user?.name || "Study Host", avatar: "" }],
        },
      ];

      for (const roomData of defaultRooms) {
        await saveRoom(roomData);
      }
      publicRooms = await getFeaturedRooms();
    }

    res.json({
      success: true,
      count: publicRooms.length,
      rooms: publicRooms,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/rooms/create
 * Creates a study room in PostgreSQL
 */
router.post("/create", verifyJWT, async (req, res, next) => {
  try {
    const { topic, title, description, subjectTag, isPublic } = req.body;
    if (!topic) {
      return res.status(400).json({ success: false, error: "Study room topic is required." });
    }

    const code = generateRoomCode();
    const room = await saveRoom({
      code,
      title: title || topic,
      topic,
      description: description || "",
      subjectTag: subjectTag || "General",
      isPublic: isPublic === true,
      hostId: req.user.id,
      participants: [
        {
          userId: req.user.id,
          name: req.user.name,
          avatar: req.user.avatar || "",
          score: 0,
        },
      ],
      isActive: true,
    });

    res.json({
      success: true,
      room,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/rooms/join
 * Join a room using room code
 */
router.post("/join", verifyJWT, async (req, res, next) => {
  try {
    const { code } = req.body;
    if (!code || code.trim().length === 0) {
      return res.status(400).json({ success: false, error: "Room code is required." });
    }

    const cleanCode = code.trim().toUpperCase();
    const room = await findRoomByCode(cleanCode);
    if (!room) {
      return res.status(404).json({ success: false, error: "Study room not found." });
    }

    const existing = room.participants.find((p) => p.userId === req.user.id);
    if (!existing) {
      room.participants.push({
        userId: req.user.id,
        name: req.user.name,
        avatar: req.user.avatar || "",
        score: 0,
      });
      await saveRoom(room);
    }

    res.json({
      success: true,
      room,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/rooms/:code
 */
router.get("/:code", verifyJWT, async (req, res, next) => {
  try {
    const cleanCode = (req.params.code || "").trim().toUpperCase();
    const room = await findRoomByCode(cleanCode);
    if (!room) {
      return res.status(404).json({ success: false, error: "Room not found." });
    }

    res.json({
      success: true,
      room,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/rooms/:code/start-quiz
 * Generate interactive room quiz using Mistral AI
 */
router.post("/:code/start-quiz", verifyJWT, async (req, res, next) => {
  try {
    const room = await findRoomByCode(req.params.code);
    if (!room) {
      return res.status(404).json({ success: false, error: "Room not found." });
    }

    const questions = await generateRoomQuiz(room.topic);

    room.currentQuiz = {
      questionIndex: 0,
      questions,
      isActive: true,
    };

    await saveRoom(room);

    res.json({
      success: true,
      quiz: room.currentQuiz,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
