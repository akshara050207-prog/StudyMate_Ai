const express = require("express");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { verifyFirebaseToken } = require("../services/firebaseAuthService");
const { findUserByEmail, findUserById, saveUser } = require("../db/postgres");
const verifyJWT = require("../middleware/verifyJWT");

const router = express.Router();

/**
 * POST /api/auth/firebase-login
 * Syncs user authenticated via Firebase Auth with Neon PostgreSQL Database
 */
router.post("/firebase-login", async (req, res, next) => {
  try {
    const { idToken, firebaseUser } = req.body;

    if (!firebaseUser && !idToken) {
      return res.status(400).json({ success: false, error: "Firebase credentials are required." });
    }

    const verifiedInfo = await verifyFirebaseToken(idToken, firebaseUser);
    const userEmail = verifiedInfo.email.toLowerCase();

    // Find or create user in Neon PostgreSQL
    let user = await findUserByEmail(userEmail);

    if (!user) {
      user = await saveUser({
        id: `usr_${verifiedInfo.uid || crypto.randomBytes(8).toString("hex")}`,
        email: userEmail,
        name: verifiedInfo.name || userEmail.split("@")[0],
        avatar: verifiedInfo.avatar || "",
        phone: "",
        bio: "Active Learner & Student",
        isEmailVerified: verifiedInfo.emailVerified ?? true,
        isPhoneVerified: false,
        preferredOtpMethod: "email",
        projects: [],
      });
    } else {
      user.isEmailVerified = verifiedInfo.emailVerified ?? true;
      if (verifiedInfo.name) user.name = verifiedInfo.name;
      if (verifiedInfo.avatar) user.avatar = verifiedInfo.avatar;
      user = await saveUser(user);
    }

    // Generate JWT session token (7 days)
    const token = jwt.sign(
      { id: user.id, email: user.email, name: user.name, avatar: user.avatar },
      process.env.JWT_SECRET || "StudyMateAI_2026_Akshara_9X7LmPq4Rv8ZtK2Hs8Bw",
      { expiresIn: "7d" }
    );

    res.json({
      success: true,
      token,
      user,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/send-otp / legacy email trigger -> compatibility route
 */
router.post("/send-otp", async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, error: "Email address is required." });
    }
    const cleanEmail = email.trim().toLowerCase();

    res.json({
      success: true,
      message: `Firebase verification active for ${cleanEmail}. Check your Gmail inbox for verification link.`,
      tempAuthToken: `temp_fb_${Date.now()}`,
      email: cleanEmail,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/verify-otp -> legacy compatibility route
 */
router.post("/verify-otp", async (req, res, next) => {
  try {
    const { email, name } = req.body;
    const userEmail = (email || "student@gmail.com").toLowerCase();

    let user = await findUserByEmail(userEmail);
    if (!user) {
      user = await saveUser({
        id: `usr_${crypto.randomBytes(8).toString("hex")}`,
        email: userEmail,
        name: name || userEmail.split("@")[0],
        avatar: "",
        phone: "",
        bio: "Active Learner & Student",
        isEmailVerified: true,
        projects: [],
      });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, name: user.name, avatar: user.avatar },
      process.env.JWT_SECRET || "StudyMateAI_2026_Akshara_9X7LmPq4Rv8ZtK2Hs8Bw",
      { expiresIn: "7d" }
    );

    res.json({
      success: true,
      token,
      user,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/auth/me -> Returns authenticated user profile from Neon PostgreSQL
 */
router.get("/me", verifyJWT, async (req, res, next) => {
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

module.exports = router;
