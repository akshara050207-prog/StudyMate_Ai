const express = require("express");
const { getMessageHistory, findUserById } = require("../db/postgres");
const verifyJWT = require("../middleware/verifyJWT");

const router = express.Router();

router.get("/history/:friendId", verifyJWT, async (req, res, next) => {
  try {
    const currentUserId = req.user.id;
    const friendId = req.params.friendId;

    const messages = await getMessageHistory(currentUserId, friendId);

    res.json({
      success: true,
      messages,
    });
  } catch (error) {
    next(error);
  }
});

router.get("/users", verifyJWT, async (req, res, next) => {
  try {
    const me = await findUserById(req.user.id);
    const mockUsers = [
      { id: "usr_alex", name: "Alex Chen", email: "alex@example.com", avatar: "", bio: "CS Major & AI enthusiast" },
      { id: "usr_sarah", name: "Sarah Miller", email: "sarah@example.com", avatar: "", bio: "Full Stack Developer" },
    ];

    res.json({
      success: true,
      users: me ? mockUsers.filter((u) => u.id !== me.id) : mockUsers,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
