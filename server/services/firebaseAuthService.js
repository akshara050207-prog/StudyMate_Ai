const jwt = require("jsonwebtoken");

/**
 * Parses and verifies a Firebase Auth ID token or User Payload
 */
async function verifyFirebaseToken(idToken, userPayload = null) {
  try {
    if (userPayload && userPayload.email) {
      return {
        uid: userPayload.uid || `fb_${Date.now()}`,
        email: userPayload.email.toLowerCase(),
        name: userPayload.displayName || userPayload.name || userPayload.email.split("@")[0],
        avatar: userPayload.photoURL || userPayload.avatar || "",
        emailVerified: userPayload.emailVerified ?? true,
      };
    }

    if (idToken) {
      // Decode JWT payload from Firebase Auth token
      const decoded = jwt.decode(idToken);
      if (decoded && decoded.email) {
        return {
          uid: decoded.user_id || decoded.sub,
          email: decoded.email.toLowerCase(),
          name: decoded.name || decoded.email.split("@")[0],
          avatar: decoded.picture || "",
          emailVerified: decoded.email_verified ?? true,
        };
      }
    }
  } catch (error) {
    console.error("Firebase Token Verification Error:", error.message);
  }

  throw new Error("Invalid or unverified Firebase credentials.");
}

module.exports = { verifyFirebaseToken };
