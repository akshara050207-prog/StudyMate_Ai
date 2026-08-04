const mongoose = require("mongoose");

const roomSchema = new mongoose.Schema(
  {
    code: { type: String, required: true, unique: true, uppercase: true },
    title: { type: String, default: "" },
    topic: { type: String, required: true },
    description: { type: String, default: "" },
    subjectTag: { type: String, default: "General" },
    isPublic: { type: Boolean, default: false },
    hostId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    participants: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        name: { type: String },
        avatar: { type: String },
        score: { type: Number, default: 0 },
        joinedAt: { type: Date, default: Date.now }
      }
    ],
    currentQuiz: {
      questionIndex: { type: Number, default: 0 },
      questions: [
        {
          question: String,
          options: [String],
          correctIndex: Number,
          explanation: String
        }
      ],
      isActive: { type: Boolean, default: false }
    },
    pinnedNotes: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        userName: String,
        content: String,
        createdAt: { type: Date, default: Date.now }
      }
    ],
    isActive: { type: Boolean, default: true }
  },
  { timestamps: true }
);

module.exports = mongoose.model("Room", roomSchema);
