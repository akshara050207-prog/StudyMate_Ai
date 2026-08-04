const mongoose = require("mongoose");

const projectSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, default: "" },
  link: { type: String, default: "" },
  createdAt: { type: Date, default: Date.now }
});

const userSchema = new mongoose.Schema(
  {
    googleId: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    avatar: { type: String, default: "" },
    bio: { type: String, default: "Passionate learner & builder" },
    phone: { type: String, default: "" },
    isVerifiedGmail: { type: Boolean, default: true },
    isEmailVerified: { type: Boolean, default: true },
    isPhoneVerified: { type: Boolean, default: false },
    preferredOtpMethod: { type: String, enum: ["email", "phone"], default: "email" },
    projects: [projectSchema],
    lastActiveDate: { type: Date, default: Date.now }
  },
  { timestamps: true }
);

module.exports = mongoose.model("User", userSchema);
