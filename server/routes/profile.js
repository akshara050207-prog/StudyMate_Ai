const express = require("express");
const { findUserById, saveUser } = require("../db/postgres");
const verifyJWT = require("../middleware/verifyJWT");

const router = express.Router();

// GET user profile with projects from PostgreSQL
router.get("/", verifyJWT, async (req, res, next) => {
  try {
    const user = await findUserById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, error: "User profile not found." });
    }

    res.json({
      success: true,
      user,
    });
  } catch (error) {
    next(error);
  }
});

// UPDATE user basic info (name, bio, avatar, phone)
router.put("/", verifyJWT, async (req, res, next) => {
  try {
    const { name, bio, avatar, phone } = req.body;

    let user = await findUserById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, error: "User not found." });
    }

    if (name) user.name = name;
    if (bio !== undefined) user.bio = bio;
    if (avatar !== undefined) user.avatar = avatar;
    if (phone !== undefined) user.phone = phone;

    user = await saveUser(user);

    res.json({
      success: true,
      user,
    });
  } catch (error) {
    next(error);
  }
});

// ADD portfolio project to profile
router.post("/projects", verifyJWT, async (req, res, next) => {
  try {
    const { title, description, link } = req.body;

    if (!title || title.trim().length === 0) {
      return res.status(400).json({ success: false, error: "Project title is required." });
    }

    let user = await findUserById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, error: "User not found." });
    }

    if (!user.projects) user.projects = [];
    user.projects.push({
      id: `proj_${Date.now()}`,
      title: title.trim(),
      description: (description || "").trim(),
      link: (link || "").trim(),
    });

    user = await saveUser(user);

    res.status(201).json({
      success: true,
      user,
    });
  } catch (error) {
    next(error);
  }
});

// DELETE portfolio project from profile
router.delete("/projects/:projectId", verifyJWT, async (req, res, next) => {
  try {
    let user = await findUserById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, error: "User not found." });
    }

    if (user.projects) {
      user.projects = user.projects.filter((p) => p.id !== req.params.projectId);
      user = await saveUser(user);
    }

    res.json({
      success: true,
      user,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
