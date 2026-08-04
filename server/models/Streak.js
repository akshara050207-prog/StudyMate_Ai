const mongoose = require("mongoose");

const streakSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true },
    currentStreak: { type: Number, default: 1 },
    highestStreak: { type: Number, default: 1 },
    lastActiveDate: { type: Date, default: Date.now },
    friendStreaks: [
      {
        friendId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        friendName: String,
        friendAvatar: String,
        combinedDays: { type: Number, default: 1 },
        lastInteraction: { type: Date, default: Date.now }
      }
    ],
    weeklyActivity: [
      {
        day: String,
        minutesStudied: { type: Number, default: 0 },
        quizzesTaken: { type: Number, default: 0 }
      }
    ]
  },
  { timestamps: true }
);

module.exports = mongoose.model("Streak", streakSchema);
