import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/material_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_card.dart';
import '../widgets/skeleton_loader.dart';
import 'material_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MaterialModel> _materials = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoadingMaterials = true;
  bool _isLoadingChat = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) {
      setState(() {
        _isLoadingMaterials = false;
        _isLoadingChat = false;
      });
      return;
    }

    // Load Materials
    ApiService.fetchUserMaterials(auth.token!).then((mats) {
      if (mounted) {
        setState(() {
          _materials = mats;
          _isLoadingMaterials = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingMaterials = false);
    });

    // Load AI Chat History
    ApiService.fetchAIChatHistory(auth.token!).then((chats) {
      if (mounted) {
        setState(() {
          _chatHistory = chats;
          _isLoadingChat = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingChat = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Real History", style: AppTypography.headingMedium(isDark: isDark)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(LucideIcons.fileText, size: 18), text: "PDFs"),
            Tab(icon: Icon(LucideIcons.helpCircle, size: 18), text: "Quizzes"),
            Tab(icon: Icon(LucideIcons.layers, size: 18), text: "Flashcards"),
            Tab(icon: Icon(LucideIcons.messageSquare, size: 18), text: "Chat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPdfsTab(isDark),
          _buildQuizzesTab(isDark),
          _buildFlashcardsTab(isDark),
          _buildChatTab(isDark),
        ],
      ),
    );
  }

  Widget _buildPdfsTab(bool isDark) {
    if (_isLoadingMaterials) {
      return _buildSkeletonList();
    }
    final pdfs = _materials.where((m) => m.sourceType == "pdf" || m.title.isNotEmpty).toList();
    if (pdfs.isEmpty) {
      return _buildEmptyIllustration(
        icon: LucideIcons.fileX,
        title: "No PDFs uploaded",
        subtitle: "Upload your first PDF to generate AI study materials.",
        isDark: isDark,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: pdfs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final mat = pdfs[index];
        return CustomCard(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialDetailScreen(material: mat)));
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mat.title, style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("PDF Document • Summary & Notes Generated", style: AppTypography.caption(isDark: isDark)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizzesTab(bool isDark) {
    if (_isLoadingMaterials) {
      return _buildSkeletonList();
    }
    final withQuiz = _materials.where((m) => m.quiz.isNotEmpty).toList();
    if (withQuiz.isEmpty) {
      return _buildEmptyIllustration(
        icon: LucideIcons.helpCircle,
        title: "No Quiz generated",
        subtitle: "Generated MCQs from uploaded PDFs will appear here.",
        isDark: isDark,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: withQuiz.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final mat = withQuiz[index];
        return CustomCard(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialDetailScreen(material: mat)));
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.helpCircle, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mat.title, style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("${mat.quiz.length} Questions Quiz Available", style: AppTypography.caption(isDark: isDark)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashcardsTab(bool isDark) {
    if (_isLoadingMaterials) {
      return _buildSkeletonList();
    }
    final withCards = _materials.where((m) => m.flashcards.isNotEmpty).toList();
    if (withCards.isEmpty) {
      return _buildEmptyIllustration(
        icon: LucideIcons.layers,
        title: "No Flashcards",
        subtitle: "Generated flashcard decks from your study materials will show here.",
        isDark: isDark,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: withCards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final mat = withCards[index];
        return CustomCard(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialDetailScreen(material: mat)));
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.layers, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mat.title, style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("${mat.flashcards.length} Flashcard Deck", style: AppTypography.caption(isDark: isDark)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatTab(bool isDark) {
    if (_isLoadingChat) {
      return _buildSkeletonList();
    }
    if (_chatHistory.isEmpty) {
      return _buildEmptyIllustration(
        icon: LucideIcons.messageSquareX,
        title: "No Chat History",
        subtitle: "Your past conversations with StudyMate AI will be listed here.",
        isDark: isDark,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _chatHistory.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final msg = _chatHistory[index];
        final isUser = msg["role"] == "user";
        return CustomCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isUser ? LucideIcons.user : LucideIcons.bot,
                color: isUser ? AppColors.primary : AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg["content"] ?? "",
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const SkeletonLoader(height: 70, borderRadius: 16),
    );
  }

  Widget _buildEmptyIllustration({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTypography.headingMedium(isDark: isDark), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTypography.bodyMedium(isDark: isDark), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}