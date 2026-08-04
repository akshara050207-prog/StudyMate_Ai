import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/skeleton_loader.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoadingHistory = true;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    setState(() => _isLoadingHistory = true);
    try {
      final history = await ApiService.fetchAIChatHistory(auth.token!);
      if (mounted) {
        setState(() {
          _chatHistory = history;
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSendingMessage) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    _messageController.clear();

    final userMsgIndex = _chatHistory.length;
    final assistantMsgIndex = userMsgIndex + 1;

    setState(() {
      _chatHistory.add({"role": "user", "content": text});
      _chatHistory.add({"role": "assistant", "content": ""});
      _isSendingMessage = true;
    });
    _scrollToBottom();

    final buffer = StringBuffer();

    try {
      await AIService.streamChatMessage(
        text,
        token: auth.token,
        onChunk: (chunk) {
          if (mounted) {
            buffer.write(chunk);
            setState(() {
              _chatHistory[assistantMsgIndex]["content"] = buffer.toString();
            });
            _scrollToBottom();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        if (buffer.isEmpty) {
          setState(() {
            _chatHistory[assistantMsgIndex]["content"] = "⚠️ Unable to connect to StudyMate AI server. Please check your internet connection or try again later.";
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearHistory() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token != null) {
      await ApiService.clearAIChatHistory(auth.token!);
    }
    if (mounted) {
      setState(() {
        _chatHistory.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: canPop
          ? AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text("AI Chat Assistant", style: AppTypography.headingMedium(isDark: isDark)),
              actions: [
                if (_chatHistory.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 20),
                    onPressed: _clearHistory,
                    tooltip: "Clear Chat",
                  ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoadingHistory
                  ? ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, _) => const SkeletonLoader(height: 70, borderRadius: 16),
                    )
                  : _chatHistory.isEmpty
                      ? _buildEmptyChat(isDark)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: _chatHistory.length,
                          itemBuilder: (context, index) {
                            final msg = _chatHistory[index];
                            final isUser = msg['role'] == 'user';
                            final content = msg['content'] ?? '';
                            if (!isUser && content.isEmpty && _isSendingMessage) {
                              return _buildThinkingBubble(isDark);
                            }
                            if (!isUser && content.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return _buildMessageBubble(content, isUser, isDark);
                          },
                        ),
            ),
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles, size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              "Ask StudyMate AI Anything",
              textAlign: TextAlign.center,
              style: AppTypography.headingMedium(isDark: isDark),
            ),
            const SizedBox(height: 6),
            Text(
              "Ask questions on any subject. Powered by ChatGPT-4 & Mistral AI.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(isDark: isDark),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip("Explain Quantum Computing Simply", isDark),
                _suggestionChip("How does B-Tree indexing work?", isDark),
                _suggestionChip("Summarize Thermodynamics 2nd Law", isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String prompt, bool isDark) {
    return ActionChip(
      label: Text(prompt, style: const TextStyle(fontSize: 12)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
      onPressed: () {
        _messageController.text = prompt;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageBubble(String content, bool isUser, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: isUser
            ? Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
              )
            : MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14.5, height: 1.5),
                  h1: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                  h2: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
      ),
    );
  }

  Widget _buildThinkingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              "StudyMate AI is thinking...",
              style: AppTypography.caption(isDark: isDark).copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Ask anything about your studies...",
                filled: true,
                fillColor: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
