const { findRoomByCode, saveRoom } = require("../db/postgres");
const { refereeConflict, generateRoomQuiz } = require("../services/mistralApiService");

module.exports = (io, socket) => {
  socket.on("join-room", async ({ roomCode, user }) => {
    try {
      const code = roomCode.toUpperCase();
      socket.join(`room_${code}`);
      console.log(`⚡ Socket ${socket.id} joined room_${code}`);

      const room = await findRoomByCode(code);
      if (room) {
        io.to(`room_${code}`).emit("room-updated", room);
        io.to(`room_${code}`).emit("user-joined-room", {
          user,
          message: `${user.name || "A student"} joined the study room!`,
        });
      }
    } catch (err) {
      console.error("Error in join-room socket:", err.message);
    }
  });

  socket.on("leave-room", ({ roomCode, user }) => {
    const code = roomCode.toUpperCase();
    socket.leave(`room_${code}`);
    io.to(`room_${code}`).emit("user-left-room", {
      user,
      message: `${user.name || "A student"} left the room.`,
    });
  });

  socket.on("start-room-quiz", async ({ roomCode, topic }) => {
    try {
      const code = roomCode.toUpperCase();
      const questions = await generateRoomQuiz(topic);

      const room = await findRoomByCode(code);
      if (room) {
        room.currentQuiz = {
          questionIndex: 0,
          questions,
          isActive: true,
        };
        await saveRoom(room);

        io.to(`room_${code}`).emit("quiz-started", {
          quiz: room.currentQuiz,
        });
      }
    } catch (err) {
      console.error("Error starting room quiz:", err);
    }
  });

  socket.on("submit-quiz-answer", async ({ roomCode, userId, questionIndex, selectedOption }) => {
    try {
      const code = roomCode.toUpperCase();
      const room = await findRoomByCode(code);

      if (room && room.currentQuiz && room.currentQuiz.questions[questionIndex]) {
        const question = room.currentQuiz.questions[questionIndex];
        const isCorrect = selectedOption === question.correctIndex;
        const points = isCorrect ? 10 : 0;

        const participant = room.participants.find((p) => p.userId === userId);
        if (participant && isCorrect) {
          participant.score = (participant.score || 0) + points;
          await saveRoom(room);
        }

        io.to(`room_${code}`).emit("answer-result", {
          userId,
          questionIndex,
          isCorrect,
          correctIndex: question.correctIndex,
          explanation: question.explanation,
          scoreboard: room.participants,
        });
      }
    } catch (err) {
      console.error("Error submitting quiz answer:", err);
    }
  });

  socket.on("post-pinned-note", async ({ roomCode, note }) => {
    try {
      const code = roomCode.toUpperCase();
      const room = await findRoomByCode(code);

      if (room) {
        if (!room.pinnedNotes) room.pinnedNotes = [];
        room.pinnedNotes.push(note);
        await saveRoom(room);

        io.to(`room_${code}`).emit("pinned-note-added", note);
      }
    } catch (err) {
      console.error("Error posting pinned note:", err);
    }
  });

  socket.on("request-ai-referee", async ({ roomCode, topic, explanationA, userA, explanationB, userB }) => {
    try {
      const code = roomCode.toUpperCase();
      io.to(`room_${code}`).emit("referee-evaluating", {
        message: "🤖 AI Referee (Mistral AI) is analyzing both student explanations...",
      });

      const verdict = await refereeConflict(topic, explanationA, userA, explanationB, userB);

      io.to(`room_${code}`).emit("referee-verdict", {
        topic,
        verdict,
        userA,
        userB,
      });
    } catch (err) {
      console.error("Error in AI Referee socket:", err);
    }
  });
};
