const mongoose = require("mongoose");

const otpVerificationSchema = new mongoose.Schema(
  {
    tempAuthToken: { type: String, required: true, index: true },
    googleId: { type: String, required: true },
    email: { type: String, required: true },
    name: { type: String, default: "" },
    avatar: { type: String, default: "" },
    phone: { type: String, default: "" },
    otpCode: { type: String, required: true },
    method: { type: String, enum: ["email", "phone"], required: true },
    expiresAt: { type: Date, required: true }
  },
  { timestamps: true }
);

// Auto expire after 10 minutes
otpVerificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model("OTPVerification", otpVerificationSchema);
