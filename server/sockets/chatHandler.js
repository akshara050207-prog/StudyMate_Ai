const { saveMessage } = require("../db/postgres");

module.exports = (io, socket) => {
  socket.on("join-user-chat", ({ userId }) => {
    if (userId) {
      socket.join(`user_${userId}`);
      console.log(`💬 User ${userId} registered for DM socket room user_${userId}`);
    }
  });

  socket.on("send-message", async (data) => {
    try {
      const { senderId, senderName, senderAvatar, receiverId, content } = data;

      if (!senderId || !receiverId || !content) return;

      const newMessage = await saveMessage({
        senderId,
        senderName,
        senderAvatar: senderAvatar || "",
        receiverId,
        content,
        isRead: false,
      });

      io.to(`user_${receiverId}`).emit("new-message", newMessage);
      io.to(`user_${senderId}`).emit("message-sent", newMessage);

      io.to(`user_${receiverId}`).emit("in-app-notification", {
        type: "chat",
        title: `Message from ${senderName}`,
        body: content.length > 40 ? content.substring(0, 40) + "..." : content,
        senderId,
      });
    } catch (err) {
      console.error("Error saving/emitting chat message:", err);
    }
  });

  socket.on("typing", ({ senderId, receiverId, isTyping }) => {
    io.to(`user_${receiverId}`).emit("user-typing", {
      senderId,
      isTyping,
    });
  });
};
