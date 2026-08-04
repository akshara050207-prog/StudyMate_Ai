require("dotenv").config();

const express = require("express");
const http = require("http");
const cors = require("cors");
const { Server } = require("socket.io");
const { initPostgresDatabase } = require("./db/postgres");

// Routes
const authRoute = require("./routes/auth");
const roomsRoute = require("./routes/rooms");
const chatRoute = require("./routes/chat");
const aiRoute = require("./routes/ai");
const profileRoute = require("./routes/profile");
const uploadRoute = require("./routes/upload");
const materialsRoute = require("./routes/materials");

// Middleware
const errorHandler = require("./middleware/errorHandler");

// Socket Handlers
const registerRoomHandlers = require("./sockets/roomHandler");
const registerChatHandlers = require("./sockets/chatHandler");

const app = express();
const server = http.createServer(app);

// Socket.io Setup
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
  },
});

// Express Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static("uploads"));

// PostgreSQL Database Connection Initialization
initPostgresDatabase();

// Root Health Check Route
app.get("/", (req, res) => {
  res.send("🚀 StudyMate AI Backend API & Realtime Server Running (PostgreSQL + Mistral AI + Brevo)");
});

// API Routes Registration
app.use("/api/auth", authRoute);
app.use("/api/rooms", roomsRoute);
app.use("/api/chat", chatRoute);
app.use("/api/ai", aiRoute);
app.use("/api/profile", profileRoute);
app.use("/api/materials", materialsRoute);
app.use("/api", uploadRoute);

// Socket.io Connection Logic
io.on("connection", (socket) => {
  console.log(`🔌 New client connected: ${socket.id}`);

  registerRoomHandlers(io, socket);
  registerChatHandlers(io, socket);

  socket.on("disconnect", () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
  });
});

// Global Error Handler
app.use(errorHandler);

// Start Server
const PORT = process.env.PORT || 3000;

server.listen(PORT, "0.0.0.0", () => {
  console.log(`=================================================`);
  console.log(`🚀 StudyMate AI Backend running on port ${PORT}`);
  console.log(`🐘 Database Engine: PostgreSQL (Neon Cloud DB)`);
  console.log(`🤖 AI Engine: Mistral AI`);
  console.log(`🔥 Auth Engine: Firebase Authentication (Gmail)`);
  console.log(`=================================================`);
});
