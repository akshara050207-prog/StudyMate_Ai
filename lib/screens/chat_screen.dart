import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/message.dart';
import '../services/ai_service.dart';
import '../services/upload_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final AIService aiService = AIService();
  final UploadService uploadService = UploadService();

  final List<Message> messages = [];

  bool isLoading = false;

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    String userMessage = controller.text.trim();

    setState(() {
      messages.add(
        Message(
          text: userMessage,
          isUser: true,
        ),
      );
      isLoading = true;
    });

    controller.clear();
    scrollToBottom();

    try {
      final aiReply = await AIService.sendMessage(userMessage);

      setState(() {
        messages.add(
          Message(
            text: aiReply,
            isUser: false,
          ),
        );
      });
    } catch (e) {
      setState(() {
        messages.add(
           Message(
            text: "Something went wrong. Please try again.",
            isUser: false,
          ),
        );
      });
    }

    setState(() {
      isLoading = false;
    });

    scrollToBottom();
  }

  Future<void> pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    String path = result.files.single.path!;

    await uploadService.uploadFile(path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("PDF Uploaded Successfully"),
      ),
    );
  }

  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null) return;

    String path = result.files.single.path!;

    await uploadService.uploadFile(path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Image Uploaded Successfully"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xff6C63FF),
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              "StudyMate AI",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      "👋 Hello!\nAsk me anything...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(
                      top: 15,
                      bottom: 10,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(
                        message: messages[index].text,
                        isUser: messages[index].isUser,
                      );
                    },
                  ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text("StudyMate AI is typing..."),
                ],
              ),
            ),          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.attach_file,
                      color: Color(0xff6C63FF),
                    ),
                    onSelected: (value) {
                      if (value == "pdf") {
                        pickPdf();
                      } else {
                        pickImage();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: "pdf",
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                            SizedBox(width: 10),
                            Text("Upload PDF"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "image",
                        child: Row(
                          children: [
                            Icon(Icons.image,
                                color: Colors.green),
                            SizedBox(width: 10),
                            Text("Upload Image"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffF3F4F8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Ask anything...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    height: 52,
                    width: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xff6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}