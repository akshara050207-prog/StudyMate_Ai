import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../../services/ai_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

class RoomDetailScreen extends StatefulWidget {
  final RoomModel room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late RoomModel _currentRoom;
  int _currentQuestionIndex = 0;
  int? _selectedOption;
  bool _hasAnswered = false;
  String? _refereeResult;
  bool _isRefereeLoading = false;

  final _explanationAController = TextEditingController();
  final _explanationBController = TextEditingController();
  final _noteController = TextEditingController();
  final List<String> _pinnedNotes = [];

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = Provider.of<SocketService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);

      socket.joinRoom(_currentRoom.code, {
        "userId": auth.currentUser?.id ?? "",
        "name": auth.currentUser?.name ?? "User",
        "avatar": auth.currentUser?.avatar ?? "",
      });

      socket.socket?.on("quiz-started", (data) {
        if (mounted) {
          setState(() {
            var rawQuiz = data['quiz'] ?? {};
            var rawQs = rawQuiz['questions'] as List? ?? [];
            List<QuizQuestion> questions = rawQs.map((q) => QuizQuestion.fromJson(q)).toList();
            _currentRoom = RoomModel(
              id: _currentRoom.id,
              code: _currentRoom.code,
              title: _currentRoom.title,
              topic: _currentRoom.topic,
              description: _currentRoom.description,
              subjectTag: _currentRoom.subjectTag,
              isPublic: _currentRoom.isPublic,
              hostId: _currentRoom.hostId,
              participants: _currentRoom.participants,
              questions: questions,
              isQuizActive: true,
            );
            _currentQuestionIndex = 0;
            _hasAnswered = false;
            _selectedOption = null;
          });
        }
      });

      socket.socket?.on("answer-result", (data) {
        if (mounted) {
          setState(() {
            _hasAnswered = true;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    final socket = Provider.of<SocketService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    socket.leaveRoom(_currentRoom.code, {"userId": auth.currentUser?.id});
    super.dispose();
  }

  void _startRoomQuiz() {
    final socket = Provider.of<SocketService>(context, listen: false);
    socket.startRoomQuiz(_currentRoom.code, _currentRoom.topic);

    if (_currentRoom.questions.isEmpty) {
      setState(() {
        _currentRoom = RoomModel(
          id: _currentRoom.id,
          code: _currentRoom.code,
          title: _currentRoom.title,
          topic: _currentRoom.topic,
          description: _currentRoom.description,
          subjectTag: _currentRoom.subjectTag,
          isPublic: _currentRoom.isPublic,
          hostId: _currentRoom.hostId,
          participants: _currentRoom.participants,
          questions: [
            QuizQuestion(
              question: "What is the primary function of Normalization in DBMS?",
              options: [
                "Reduce data redundancy and anomalies",
                "Increase hard drive storage size",
                "Encrypt user passwords",
                "Speed up raw image rendering"
              ],
              correctIndex: 0,
              explanation: "Normalization organizes tables to minimize data duplication and insertion/update anomalies.",
            ),
            QuizQuestion(
              question: "Which normal form eliminates partial dependency?",
              options: ["1NF", "2NF", "3NF", "BCNF"],
              correctIndex: 1,
              explanation: "Second Normal Form (2NF) ensures every non-prime attribute is fully dependent on the primary key.",
            ),
          ],
          isQuizActive: true,
        );
      });
    }
  }

  void _submitAnswer(int optionIndex) {
    if (_hasAnswered) return;
    setState(() {
      _selectedOption = optionIndex;
      _hasAnswered = true;
    });

    final socket = Provider.of<SocketService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    socket.submitQuizAnswer(
      _currentRoom.code,
      auth.currentUser?.id ?? "user_1",
      _currentQuestionIndex,
      optionIndex,
    );
  }

  void _triggerAIRefereeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(LucideIcons.bot, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text("AI Referee Judge", style: AppTypography.headingSmall(isDark: isDark)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "When student explanations conflict, let StudyMate AI judge the most accurate answer!",
                      style: AppTypography.caption(isDark: isDark),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _explanationAController,
                      decoration: const InputDecoration(
                        labelText: "Student A's Explanation",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _explanationBController,
                      decoration: const InputDecoration(
                        labelText: "Student B's Explanation",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_isRefereeLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                    if (_refereeResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _refereeResult!,
                          style: AppTypography.bodyMedium(isDark: isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Close"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    setDialogState(() {
                      _isRefereeLoading = true;
                    });

                    final aiService = AIService();
                    final verdict = await aiService.getRefereeVerdict(
                      _currentRoom.topic,
                      _explanationAController.text,
                      "Student A",
                      _explanationBController.text,
                      "Student B",
                    );

                    setDialogState(() {
                      _refereeResult = verdict;
                      _isRefereeLoading = false;
                    });
                  },
                  child: const Text("Judge Verdict", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questions = _currentRoom.questions;
    final hasQuiz = questions.isNotEmpty && _currentQuestionIndex < questions.length;
    final currentQ = hasQuiz ? questions[_currentQuestionIndex] : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          children: [
            Text(_currentRoom.topic, style: AppTypography.headingSmall(isDark: isDark)),
            Text("Room Code: ${_currentRoom.code}", style: AppTypography.caption(isDark: isDark)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.bot, color: AppColors.accent),
            tooltip: "Call AI Referee",
            onPressed: _triggerAIRefereeDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Live Scoreboard", style: AppTypography.headingSmall(isDark: isDark)),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentRoom.participants.length,
                itemBuilder: (context, index) {
                  final p = _currentRoom.participants[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: p.avatar.isNotEmpty ? NetworkImage(p.avatar) : null,
                          child: p.avatar.isEmpty ? Text(p.name[0]) : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 13)),
                            Text("${p.score} pts", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            if (!hasQuiz) ...[
              CustomCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(LucideIcons.sparkles, size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      "Ready to Battle?",
                      style: AppTypography.headingMedium(isDark: isDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Click below to generate synchronized StudyMate AI questions for all room members.",
                      style: AppTypography.bodyMedium(isDark: isDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: "Start AI Room Quiz",
                      icon: LucideIcons.play,
                      onPressed: _startRoomQuiz,
                    ),
                  ],
                ),
              ),
            ] else ...[
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Question ${_currentQuestionIndex + 1}/${questions.length}",
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text("10 Pts", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentQ!.question,
                      style: AppTypography.headingMedium(isDark: isDark).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(currentQ.options.length, (optIdx) {
                      final isSelected = _selectedOption == optIdx;
                      final isCorrect = optIdx == currentQ.correctIndex;

                      Color optionColor = isDark ? AppColors.surfaceDark : AppColors.backgroundLight;
                      BorderSide borderSide = BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight);

                      if (_hasAnswered) {
                        if (isCorrect) {
                          optionColor = AppColors.success.withValues(alpha: 0.2);
                          borderSide = const BorderSide(color: AppColors.success, width: 2);
                        } else if (isSelected && !isCorrect) {
                          optionColor = AppColors.error.withValues(alpha: 0.2);
                          borderSide = const BorderSide(color: AppColors.error, width: 2);
                        }
                      }

                      return GestureDetector(
                        onTap: () => _submitAnswer(optIdx),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: optionColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.fromBorderSide(borderSide),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                                child: Text(
                                  String.fromCharCode(65 + optIdx),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentQ.options[optIdx],
                                  style: AppTypography.bodyMedium(isDark: isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_hasAnswered) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "💡 Explanation: ${currentQ.explanation}",
                          style: AppTypography.bodyMedium(isDark: isDark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_currentQuestionIndex < questions.length - 1)
                        CustomButton(
                          text: "Next Question",
                          onPressed: () {
                            setState(() {
                              _currentQuestionIndex++;
                              _hasAnswered = false;
                              _selectedOption = null;
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text("Room Doubt Drop & Pinned Notes", style: AppTypography.headingSmall(isDark: isDark)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: "Drop a note or question for the room...",
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.send, color: AppColors.primary),
                  onPressed: () {
                    final text = _noteController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _pinnedNotes.add(text);
                        _noteController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._pinnedNotes.map((note) => CustomCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.pin, size: 16, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(child: Text(note, style: AppTypography.bodyMedium(isDark: isDark))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
