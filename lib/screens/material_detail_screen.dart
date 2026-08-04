import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/material_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_card.dart';

class MaterialDetailScreen extends StatefulWidget {
  final MaterialModel material;

  const MaterialDetailScreen({super.key, required this.material});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Quiz state
  final Map<int, int> _selectedQuizAnswers = {};
  bool _quizSubmitted = false;

  // Flashcards state
  int _currentFlashcardIndex = 0;
  bool _showFlashcardBack = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _score {
    int count = 0;
    for (int i = 0; i < widget.material.quiz.length; i++) {
      if (_selectedQuizAnswers[i] == widget.material.quiz[i].correctIndex) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.material.title,
          style: AppTypography.headingMedium(isDark: isDark),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(LucideIcons.fileText, size: 20), text: "Summary"),
            Tab(icon: Icon(LucideIcons.bookOpen, size: 20), text: "Notes"),
            Tab(icon: Icon(LucideIcons.helpCircle, size: 20), text: "Quiz"),
            Tab(icon: Icon(LucideIcons.layers, size: 20), text: "Cards"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(isDark),
          _buildNotesTab(isDark),
          _buildQuizTab(isDark),
          _buildFlashcardsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "AI Core Executive Summary",
                        style: AppTypography.headingSmall(isDark: isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.material.summary,
                  style: AppTypography.bodyLarge(isDark: isDark).copyWith(height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomCard(
            child: Row(
              children: [
                Icon(LucideIcons.info, color: AppColors.accent, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Generated based strictly on your document context. Switch to Quiz or Flashcards for quick self-testing.",
                    style: AppTypography.caption(isDark: isDark).copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(bool isDark) {
    final bubbleMatches = RegExp(r'\[Bubble:\s*([^\]]+)\]').allMatches(widget.material.structuredNotes);
    final bubbles = bubbleMatches.map((m) => m.group(1) ?? '').where((b) => b.isNotEmpty).toList();

    final cleanNotes = widget.material.structuredNotes
        .replaceAll(RegExp(r'-\s*\[Bubble:\s*[^\]]+\]'), '')
        .replaceAll(RegExp(r'\[Bubble:\s*[^\]]+\]'), '')
        .trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last-Minute Revision Mind-Map Cloud Chips
          if (bubbles.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primarySubtle.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.zap, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "⚡ Last-Minute Exam Prep (Mind-Map Clouds)",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: bubbles.map((bubbleText) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(LucideIcons.cloud, size: 14, color: AppColors.primaryLight),
                                ),
                              ),
                              TextSpan(
                                text: bubbleText,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          CustomCard(
            child: MarkdownBody(
              data: cleanNotes,
              selectable: true,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet(
                h1: AppTypography.headingLarge(isDark: isDark).copyWith(fontSize: 22),
                h2: AppTypography.headingMedium(isDark: isDark).copyWith(fontSize: 18),
                p: AppTypography.bodyLarge(isDark: isDark).copyWith(height: 1.5),
                code: TextStyle(
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                listBullet: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTab(bool isDark) {
    if (widget.material.quiz.isEmpty) {
      return const Center(child: Text("No quiz questions generated for this document."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_quizSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.trophy, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Quiz Completed!",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Your Score: $_score / ${widget.material.quiz.length}",
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedQuizAnswers.clear();
                        _quizSubmitted = false;
                      });
                    },
                    style: TextButton.styleFrom(backgroundColor: Colors.white24),
                    child: const Text("Retake", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          ...widget.material.quiz.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Question ${idx + 1} of ${widget.material.quiz.length}",
                    style: AppTypography.caption(isDark: isDark).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.question,
                    style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ...q.options.asMap().entries.map((optEntry) {
                    final optIdx = optEntry.key;
                    final optText = optEntry.value;

                    final isSelected = _selectedQuizAnswers[idx] == optIdx;
                    final isCorrect = q.correctIndex == optIdx;

                    Color tileBg = isDark ? AppColors.backgroundDark : Colors.grey.shade100;
                    Color borderColor = Colors.transparent;

                    if (_quizSubmitted) {
                      if (isCorrect) {
                        tileBg = AppColors.success.withValues(alpha: 0.15);
                        borderColor = AppColors.success;
                      } else if (isSelected && !isCorrect) {
                        tileBg = AppColors.error.withValues(alpha: 0.15);
                        borderColor = AppColors.error;
                      }
                    } else if (isSelected) {
                      tileBg = AppColors.primary.withValues(alpha: 0.15);
                      borderColor = AppColors.primary;
                    }

                    return GestureDetector(
                      onTap: _quizSubmitted
                          ? null
                          : () {
                              setState(() {
                                _selectedQuizAnswers[idx] = optIdx;
                              });
                            },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.grey,
                                ),
                              ),
                              child: Text(
                                String.fromCharCode(65 + optIdx),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                optText,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (_quizSubmitted && q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.lightbulb, size: 18, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              q.explanation,
                              style: AppTypography.caption(isDark: isDark).copyWith(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          if (!_quizSubmitted) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _selectedQuizAnswers.length == widget.material.quiz.length
                  ? () => setState(() => _quizSubmitted = true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Submit Answers", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardsTab(bool isDark) {
    if (widget.material.flashcards.isEmpty) {
      return const Center(child: Text("No flashcards generated for this document."));
    }

    final card = widget.material.flashcards[_currentFlashcardIndex];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Card ${_currentFlashcardIndex + 1} of ${widget.material.flashcards.length}",
            style: AppTypography.caption(isDark: isDark).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                _showFlashcardBack = !_showFlashcardBack;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 240, maxHeight: 380),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _showFlashcardBack
                    ? (isDark ? AppColors.surfaceDark : Colors.teal.shade50)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _showFlashcardBack ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_showFlashcardBack ? AppColors.accent : AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _showFlashcardBack ? "ANSWER / DEFINITION" : "QUESTION / TERM",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _showFlashcardBack ? AppColors.accent : AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          _showFlashcardBack ? card.back : card.front,
                          textAlign: TextAlign.center,
                          style: AppTypography.headingMedium(isDark: isDark).copyWith(
                            fontSize: 17,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.rotateCw, size: 14, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Text("Tap card to flip", style: AppTypography.caption(isDark: isDark)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.outlined(
                onPressed: _currentFlashcardIndex > 0
                    ? () {
                        setState(() {
                          _currentFlashcardIndex--;
                          _showFlashcardBack = false;
                        });
                      }
                    : null,
                iconSize: 28,
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              IconButton.outlined(
                onPressed: _currentFlashcardIndex < widget.material.flashcards.length - 1
                    ? () {
                        setState(() {
                          _currentFlashcardIndex++;
                          _showFlashcardBack = false;
                        });
                      }
                    : null,
                iconSize: 28,
                icon: const Icon(LucideIcons.chevronRight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
