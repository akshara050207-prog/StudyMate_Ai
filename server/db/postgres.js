let Pool;
try {
  Pool = require("pg").Pool;
} catch (e) {
  // pg module fallback
  Pool = null;
}

const crypto = require("crypto");

const connectionString = process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/studymate_ai";

// Create PostgreSQL connection pool if pg package exists
const pool = Pool
  ? new Pool({
      connectionString,
      connectionTimeoutMillis: 3000,
    })
  : null;

let isPostgresConnected = false;

// In-Memory Storage Fallback (Guarantees zero-downtime if PostgreSQL is initializing or unavailable)
const memoryDb = {
  users: new Map(),
  otpVerifications: new Map(),
  materials: new Map(),
  aiChatHistory: [],
  rooms: new Map(),
  messages: [],
  notes: new Map(),
};

async function initPostgresDatabase() {
  if (!pool) {
    console.log("ℹ️ PostgreSQL 'pg' module not loaded yet. Running with active in-memory database engine.");
    return;
  }

  try {
    const client = await pool.connect();
    isPostgresConnected = true;
    console.log("🐘 PostgreSQL Database Connected Successfully!");

    // Create Tables if not exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(255) PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        avatar TEXT DEFAULT '',
        phone VARCHAR(50) DEFAULT '',
        bio TEXT DEFAULT 'Active Learner & Student',
        is_email_verified BOOLEAN DEFAULT true,
        is_phone_verified BOOLEAN DEFAULT false,
        preferred_otp_method VARCHAR(20) DEFAULT 'email',
        projects JSONB DEFAULT '[]',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS otp_verifications (
        id VARCHAR(255) PRIMARY KEY,
        temp_auth_token VARCHAR(255) UNIQUE NOT NULL,
        email VARCHAR(255) NOT NULL,
        name VARCHAR(255) DEFAULT '',
        avatar TEXT DEFAULT '',
        phone VARCHAR(50) DEFAULT '',
        otp_code VARCHAR(10) NOT NULL,
        method VARCHAR(20) DEFAULT 'email',
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS materials (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        title TEXT NOT NULL,
        source_type VARCHAR(50) DEFAULT 'text',
        source_text TEXT,
        summary TEXT,
        structured_notes TEXT,
        quiz JSONB DEFAULT '[]',
        flashcards JSONB DEFAULT '[]',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS ai_chat_history (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS rooms (
        id VARCHAR(255) PRIMARY KEY,
        code VARCHAR(20) UNIQUE NOT NULL,
        title VARCHAR(255) NOT NULL,
        topic TEXT NOT NULL,
        description TEXT DEFAULT '',
        subject_tag VARCHAR(100) DEFAULT 'General',
        is_public BOOLEAN DEFAULT true,
        host_id VARCHAR(255) NOT NULL,
        participants JSONB DEFAULT '[]',
        current_quiz JSONB DEFAULT NULL,
        pinned_notes JSONB DEFAULT '[]',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS messages (
        id VARCHAR(255) PRIMARY KEY,
        sender_id VARCHAR(255) NOT NULL,
        sender_name VARCHAR(255) NOT NULL,
        sender_avatar TEXT DEFAULT '',
        receiver_id VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS notes (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    client.release();
    console.log("⚡ PostgreSQL Schemas & Tables Verified!");
  } catch (err) {
    isPostgresConnected = false;
    console.warn(`⚠️ PostgreSQL Connection Warning (${err.message}). Using active fallback engine.`);
  }
}

// User Operations
async function findUserByEmail(email) {
  if (isPostgresConnected && pool) {
    try {
      const res = await pool.query("SELECT * FROM users WHERE email = $1 LIMIT 1", [email]);
      if (res.rows.length > 0) return mapUserRow(res.rows[0]);
    } catch (_) {}
  }
  for (const user of memoryDb.users.values()) {
    if (user.email === email) return user;
  }
  return null;
}

async function findUserById(id) {
  if (isPostgresConnected && pool) {
    try {
      const res = await pool.query("SELECT * FROM users WHERE id = $1 LIMIT 1", [id]);
      if (res.rows.length > 0) return mapUserRow(res.rows[0]);
    } catch (_) {}
  }
  return memoryDb.users.get(id) || null;
}

async function saveUser(userData) {
  const id = userData.id || `usr_${crypto.randomBytes(8).toString("hex")}`;
  const user = {
    id,
    email: userData.email,
    name: userData.name || userData.email.split("@")[0],
    avatar: userData.avatar || "",
    phone: userData.phone || "",
    bio: userData.bio || "Active Learner & Student",
    isEmailVerified: userData.isEmailVerified ?? true,
    isPhoneVerified: userData.isPhoneVerified ?? false,
    preferredOtpMethod: userData.preferredOtpMethod || "email",
    projects: userData.projects || [],
    createdAt: userData.createdAt || new Date(),
    updatedAt: new Date(),
  };

  if (isPostgresConnected && pool) {
    try {
      await pool.query(
        `INSERT INTO users (id, email, name, avatar, phone, bio, is_email_verified, is_phone_verified, preferred_otp_method, projects)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
         ON CONFLICT (id) DO UPDATE SET
           name = EXCLUDED.name,
           avatar = EXCLUDED.avatar,
           phone = EXCLUDED.phone,
           bio = EXCLUDED.bio,
           is_email_verified = EXCLUDED.is_email_verified,
           is_phone_verified = EXCLUDED.is_phone_verified,
           preferred_otp_method = EXCLUDED.preferred_otp_method,
           projects = EXCLUDED.projects,
           updated_at = CURRENT_TIMESTAMP`,
        [
          user.id,
          user.email,
          user.name,
          user.avatar,
          user.phone,
          user.bio,
          user.isEmailVerified,
          user.isPhoneVerified,
          user.preferredOtpMethod,
          JSON.stringify(user.projects),
        ]
      );
    } catch (err) {
      console.error("Postgres saveUser error:", err.message);
    }
  }

  memoryDb.users.set(user.id, user);
  return user;
}

function mapUserRow(row) {
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    avatar: row.avatar,
    phone: row.phone,
    bio: row.bio,
    isEmailVerified: row.is_email_verified,
    isPhoneVerified: row.is_phone_verified,
    preferredOtpMethod: row.preferred_otp_method,
    projects: typeof row.projects === "string" ? JSON.parse(row.projects) : row.projects || [],
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// OTP Operations
async function saveOtp(otpData) {
  const id = `otp_${crypto.randomBytes(8).toString("hex")}`;
  const record = {
    id,
    tempAuthToken: otpData.tempAuthToken,
    email: otpData.email,
    name: otpData.name || "",
    avatar: otpData.avatar || "",
    phone: otpData.phone || "",
    otpCode: otpData.otpCode,
    method: otpData.method || "email",
    expiresAt: otpData.expiresAt,
    createdAt: new Date(),
  };

  if (isPostgresConnected && pool) {
    try {
      await pool.query(
        `INSERT INTO otp_verifications (id, temp_auth_token, email, name, avatar, phone, otp_code, method, expires_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [record.id, record.tempAuthToken, record.email, record.name, record.avatar, record.phone, record.otpCode, record.method, record.expiresAt]
      );
    } catch (_) {}
  }

  memoryDb.otpVerifications.set(record.tempAuthToken, record);
  return record;
}

async function findOtpByTokenAndCode(tempAuthToken, otpCode) {
  if (isPostgresConnected && pool) {
    try {
      const res = await pool.query(
        "SELECT * FROM otp_verifications WHERE temp_auth_token = $1 AND otp_code = $2 LIMIT 1",
        [tempAuthToken, otpCode]
      );
      if (res.rows.length > 0) {
        const row = res.rows[0];
        return {
          id: row.id,
          tempAuthToken: row.temp_auth_token,
          email: row.email,
          name: row.name,
          avatar: row.avatar,
          phone: row.phone,
          otpCode: row.otp_code,
          method: row.method,
          expiresAt: row.expires_at,
        };
      }
    } catch (_) {}
  }
  const record = memoryDb.otpVerifications.get(tempAuthToken);
  if (record && record.otpCode === otpCode) return record;
  return null;
}

async function deleteOtpByToken(tempAuthToken) {
  if (isPostgresConnected && pool) {
    try {
      await pool.query("DELETE FROM otp_verifications WHERE temp_auth_token = $1", [tempAuthToken]);
    } catch (_) {}
  }
  memoryDb.otpVerifications.delete(tempAuthToken);
}

// Materials Operations
async function saveMaterial(mat) {
  const id = mat.id || `mat_${crypto.randomBytes(8).toString("hex")}`;
  const material = {
    id,
    userId: mat.userId,
    title: mat.title,
    sourceType: mat.sourceType || "text",
    sourceText: mat.sourceText || "",
    summary: mat.summary || "",
    structuredNotes: mat.structuredNotes || "",
    quiz: mat.quiz || [],
    flashcards: mat.flashcards || [],
    createdAt: new Date(),
  };

  if (isPostgresConnected && pool) {
    try {
      await pool.query(
        `INSERT INTO materials (id, user_id, title, source_type, source_text, summary, structured_notes, quiz, flashcards)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          material.id,
          material.userId,
          material.title,
          material.sourceType,
          material.sourceText,
          material.summary,
          material.structuredNotes,
          JSON.stringify(material.quiz),
          JSON.stringify(material.flashcards),
        ]
      );
    } catch (_) {}
  }

  memoryDb.materials.set(material.id, material);
  return material;
}

async function getMaterialsByUserId(userId) {
  if (isPostgresConnected && pool) {
    try {
      const res = await pool.query("SELECT * FROM materials WHERE user_id = $1 ORDER BY created_at DESC", [userId]);
      if (res.rows.length > 0) {
        return res.rows.map((row) => ({
          id: row.id,
          userId: row.user_id,
          title: row.title,
          sourceType: row.source_type,
          summary: row.summary,
          structuredNotes: row.structured_notes,
          quiz: typeof row.quiz === "string" ? JSON.parse(row.quiz) : row.quiz,
          flashcards: typeof row.flashcards === "string" ? JSON.parse(row.flashcards) : row.flashcards,
          createdAt: row.created_at,
        }));
      }
    } catch (_) {}
  }
  return Array.from(memoryDb.materials.values())
    .filter((m) => m.userId === userId)
    .sort((a, b) => b.createdAt - a.createdAt);
}

// AI Chat Operations
async function saveAIChatMessage(msg) {
  const id = `aichat_${crypto.randomBytes(8).toString("hex")}`;
  const doc = { id, userId: msg.userId, role: msg.role, content: msg.content, createdAt: new Date() };

  if (isPostgresConnected && pool) {
    try {
      await pool.query("INSERT INTO ai_chat_history (id, user_id, role, content) VALUES ($1, $2, $3, $4)", [
        doc.id,
        doc.userId,
        doc.role,
        doc.content,
      ]);
    } catch (_) {}
  }

  memoryDb.aiChatHistory.push(doc);
  return doc;
}

async function getAIChatHistory(userId, limit = 50) {
  if (isPostgresConnected && pool) {
    try {
      const res = await pool.query(
        "SELECT * FROM ai_chat_history WHERE user_id = $1 ORDER BY created_at ASC LIMIT $2",
        [userId, limit]
      );
      if (res.rows.length > 0) {
        return res.rows.map((r) => ({ id: r.id, userId: r.user_id, role: r.role, content: r.content, createdAt: r.created_at }));
      }
    } catch (_) {}
  }
  return memoryDb.aiChatHistory.filter((m) => m.userId === userId).slice(-limit);
}

// Rooms Operations
async function saveRoom(roomData) {
  const id = roomData.id || `rm_${crypto.randomBytes(8).toString("hex")}`;
  const room = {
    id,
    code: roomData.code,
    title: roomData.title,
    topic: roomData.topic,
    description: roomData.description || "",
    subjectTag: roomData.subjectTag || "General",
    isPublic: roomData.isPublic ?? true,
    hostId: roomData.hostId,
    participants: roomData.participants || [],
    currentQuiz: roomData.currentQuiz || null,
    pinnedNotes: roomData.pinnedNotes || [],
    isActive: roomData.isActive ?? true,
    createdAt: roomData.createdAt || new Date(),
  };

  if (isPostgresConnected && pool) {
    try {
      await pool.query(
        `INSERT INTO rooms (id, code, title, topic, description, subject_tag, is_public, host_id, participants, current_quiz, pinned_notes, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
         ON CONFLICT (id) DO UPDATE SET
           title = EXCLUDED.title,
           topic = EXCLUDED.topic,
           description = EXCLUDED.description,
           participants = EXCLUDED.participants,
           current_quiz = EXCLUDED.current_quiz,
           pinned_notes = EXCLUDED.pinned_notes,
           is_active = EXCLUDED.is_active`,
        [
          room.id,
          room.code,
          room.title,
          room.topic,
          room.description,
          room.subjectTag,
          room.isPublic,
          room.hostId,
          JSON.stringify(room.participants),
          room.currentQuiz ? JSON.stringify(room.currentQuiz) : null,
          JSON.stringify(room.pinnedNotes),
          room.isActive,
        ]
      );
    } catch (_) {}
  }

  memoryDb.rooms.set(room.code, room);
  return room;
}

async function findRoomByCode(code) {
  const cleanCode = code.toUpperCase();
  if (isPostgresConnected && pool) {
    try {
      const res = await pool.query("SELECT * FROM rooms WHERE code = $1 LIMIT 1", [cleanCode]);
      if (res.rows.length > 0) return mapRoomRow(res.rows[0]);
    } catch (_) {}
  }
  return memoryDb.rooms.get(cleanCode) || null;
}

async function getFeaturedRooms() {
  if (isPostgresConnected && pool) {
    try {
      const res = await pool.query("SELECT * FROM rooms WHERE is_public = true AND is_active = true ORDER BY created_at DESC");
      if (res.rows.length > 0) return res.rows.map(mapRoomRow);
    } catch (_) {}
  }
  return Array.from(memoryDb.rooms.values()).filter((r) => r.isPublic && r.isActive);
}

function mapRoomRow(row) {
  return {
    id: row.id,
    code: row.code,
    title: row.title,
    topic: row.topic,
    description: row.description,
    subjectTag: row.subject_tag,
    isPublic: row.is_public,
    hostId: row.host_id,
    participants: typeof row.participants === "string" ? JSON.parse(row.participants) : row.participants || [],
    currentQuiz: typeof row.current_quiz === "string" ? JSON.parse(row.current_quiz) : row.current_quiz,
    pinnedNotes: typeof row.pinned_notes === "string" ? JSON.parse(row.pinned_notes) : row.pinned_notes || [],
    isActive: row.is_active,
    createdAt: row.created_at,
  };
}

// Messages Operations
async function saveMessage(msg) {
  const id = `msg_${crypto.randomBytes(8).toString("hex")}`;
  const message = {
    id,
    senderId: msg.senderId,
    senderName: msg.senderName,
    senderAvatar: msg.senderAvatar || "",
    receiverId: msg.receiverId,
    content: msg.content,
    isRead: msg.isRead ?? false,
    createdAt: new Date(),
  };

  if (isPostgresConnected && pool) {
    try {
      await pool.query(
        `INSERT INTO messages (id, sender_id, sender_name, sender_avatar, receiver_id, content, is_read)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [message.id, message.senderId, message.senderName, message.senderAvatar, message.receiverId, message.content, message.isRead]
      );
    } catch (_) {}
  }

  memoryDb.messages.push(message);
  return message;
}

async function getMessageHistory(userA, userB) {
  if (isPostgresConnected && pool) {
    try {
      const res = await pool.query(
        `SELECT * FROM messages
         WHERE (sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1)
         ORDER BY created_at ASC LIMIT 100`,
        [userA, userB]
      );
      if (res.rows.length > 0) {
        return res.rows.map((r) => ({
          id: r.id,
          senderId: r.sender_id,
          senderName: r.sender_name,
          senderAvatar: r.sender_avatar,
          receiverId: r.receiver_id,
          content: r.content,
          isRead: r.is_read,
          createdAt: r.created_at,
        }));
      }
    } catch (_) {}
  }

  return memoryDb.messages.filter(
    (m) => (m.senderId === userA && m.receiverId === userB) || (m.senderId === userB && m.receiverId === userA)
  );
}

module.exports = {
  pool,
  initPostgresDatabase,
  findUserByEmail,
  findUserById,
  saveUser,
  saveOtp,
  findOtpByTokenAndCode,
  deleteOtpByToken,
  saveMaterial,
  getMaterialsByUserId,
  saveAIChatMessage,
  getAIChatHistory,
  saveRoom,
  findRoomByCode,
  getFeaturedRooms,
  saveMessage,
  getMessageHistory,
};
