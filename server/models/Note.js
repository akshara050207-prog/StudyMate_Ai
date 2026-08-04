const mongoose = require("mongoose");

const noteSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true },
    topic: { type: String, required: true },
    content: { type: String, required: true },
    summary: { type: String },
    flashcards: [
      {
        question: String,
        answer: String
      }
    ],
    fileUrl: { type: String },
    fileType: { type: String }
  },
  { timestamps: true }
);

module.exports = mongoose.model("Note", noteSchema);
