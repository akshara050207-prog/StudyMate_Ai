const mongoose = require("mongoose");

const quizQuestionSchema = new mongoose.Schema({
  question: { type: String, required: true },
  options: [{ type: String, required: true }],
  correctIndex: { type: Number, required: true },
  explanation: { type: String, default: "" }
});

const flashcardSchema = new mongoose.Schema({
  front: { type: String, required: true },
  back: { type: String, required: true }
});

const materialSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true, default: "Study Material" },
    sourceType: { type: String, enum: ["pdf", "text"], default: "text" },
    sourceText: { type: String, required: true },
    summary: { type: String, default: "" },
    structuredNotes: { type: String, default: "" },
    quiz: [quizQuestionSchema],
    flashcards: [flashcardSchema]
  },
  { timestamps: true }
);

module.exports = mongoose.model("Material", materialSchema);
