const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const verifyJWT = require("../middleware/verifyJWT");
const { extractCleanPdfText } = require("../services/pdfService");
const { saveMaterial, getMaterialsByUserId } = require("../db/postgres");
const { generateFullStudyMaterial } = require("../services/groqApiService");

const router = express.Router();

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, "../uploads");
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueName = Date.now() + "-" + file.originalname.replace(/[^a-zA-Z0-9.]/g, "_");
    cb(null, uniqueName);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB limit
});

/**
 * POST /api/materials/generate
 * Accepts PDF upload or raw text, generates study material via Groq LLaMA 3.3-70B, saves to PostgreSQL
 */
router.post("/generate", verifyJWT, upload.single("file"), async (req, res, next) => {
  try {
    let sourceText = req.body.text || "";
    let sourceType = "text";
    let documentTitle = req.body.title || "Custom Notes";

    if (req.file) {
      sourceType = "pdf";
      documentTitle = req.file.originalname.replace(/\.[^/.]+$/, "");
      if (req.file.mimetype === "application/pdf" || req.file.originalname.endsWith(".pdf")) {
        const dataBuffer = fs.readFileSync(req.file.path);
        sourceText = await extractCleanPdfText(dataBuffer);
      } else {
        return res.status(400).json({ success: false, error: "Only PDF files are supported." });
      }
    }

    if (!sourceText || sourceText.trim().length < 50) {
      return res.status(400).json({
        success: false,
        error: "Unable to extract readable text from this PDF.",
      });
    }

    // Call Mistral AI for structured study material generation
    const generatedData = await generateFullStudyMaterial(sourceText);

    // Save Material in PostgreSQL
    const material = await saveMaterial({
      userId: req.user.id,
      title: generatedData.title || documentTitle,
      sourceType,
      sourceText: sourceText.slice(0, 5000),
      summary: generatedData.summary,
      structuredNotes: generatedData.structuredNotes,
      quiz: generatedData.quiz,
      flashcards: generatedData.flashcards,
    });

    res.status(201).json({
      success: true,
      material,
    });
  } catch (error) {
    console.error("Material Generation Route Error:", error);
    next(error);
  }
});

/**
 * GET /api/materials
 * Get list of saved study materials from PostgreSQL
 */
router.get("/", verifyJWT, async (req, res, next) => {
  try {
    const materials = await getMaterialsByUserId(req.user.id);

    res.json({
      success: true,
      count: materials.length,
      materials,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
