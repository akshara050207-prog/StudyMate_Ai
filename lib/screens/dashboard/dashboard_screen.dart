import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/material_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/skeleton_loader.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../material_detail_screen.dart';
import '../study_rooms/study_rooms_screen.dart';
import '../upload_study_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<MaterialModel> _recentMaterials = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentMaterials();
  }

  Future<void> _loadRecentMaterials() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) {
      setState(() => _isLoadingRecent = false);
      return;
    }

    try {
      final materials = await ApiService.fetchUserMaterials(auth.token!);
      if (mounted) {
        setState(() {
          _recentMaterials = materials.take(4).toList();
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecent = false);
    }
  }

  void _showEditNameModal() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    final nameController = TextEditingController(text: user?.name ?? "");
    final bioController = TextEditingController(text: user?.bio ?? "");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(LucideIcons.userCheck, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Edit Name & Headline",
                    style: AppTypography.headingMedium(isDark: isDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Update your display name shown at the top of the HomeScreen.",
                style: AppTypography.bodySmall(isDark: isDark),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Your Full Name",
                  prefixIcon: const Icon(LucideIcons.user, color: AppColors.primary),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bioController,
                maxLines: 2,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Study Bio / Status",
                  prefixIcon: const Icon(LucideIcons.info, color: AppColors.primary),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: "Save Display Name",
                icon: LucideIcons.checkCircle2,
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final newBio = bioController.text.trim();
                  Navigator.pop(ctx);

                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final updatedUser = await ApiService.updateProfile(
                    token: auth.token ?? "",
                    name: newName,
                    bio: newBio,
                  );

                  if (mounted) {
                    final userObj = updatedUser ??
                        UserModel(
                          id: user?.id ?? "usr_me",
                          email: user?.email ?? "user@studymate.ai",
                          name: newName.isNotEmpty ? newName : (user?.name ?? "Student"),
                          avatar: user?.avatar ?? "",
                          bio: newBio.isNotEmpty ? newBio : (user?.bio ?? ""),
                          phone: user?.phone ?? "",
                          isVerifiedGmail: true,
                          projects: user?.projects ?? [],
                        );
                    auth.updateUserState(userObj);
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text("Name & profile headline updated successfully!"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthService>(context).currentUser;

    return RefreshIndicator(
      onRefresh: _loadRecentMaterials,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Row with Direct Name Edit Access
            GestureDetector(
              onTap: _showEditNameModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: (user?.avatar != null && user!.avatar.isNotEmpty)
                          ? NetworkImage(user.avatar)
                          : null,
                      child: (user?.avatar == null || user!.avatar.isEmpty)
                          ? const Icon(LucideIcons.user, size: 22, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Welcome back,",
                                style: AppTypography.caption(isDark: isDark),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.pencil, size: 12, color: AppColors.primary),
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? "Authenticated User",
                                  style: AppTypography.headingMedium(isDark: isDark).copyWith(fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(LucideIcons.edit3, size: 15, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Verified",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hero CTA Card: PDF / Notes Upload
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadStudyScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "CORE FEATURE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Upload Document or Notes",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Generate accurate Summaries, Quizzes, Flashcards & Structured Notes.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.arrowRight, color: AppColors.primary, size: 22),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).moveY(begin: 10, end: 0),
            const SizedBox(height: 28),

            // Quick AI Shortcuts
            Text("AI Shortcuts", style: AppTypography.headingSmall(isDark: isDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickShortcutCard(
                    context: context,
                    icon: LucideIcons.bot,
                    title: "AI Chat",
                    subtitle: "Ask StudyMate AI anything",
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickShortcutCard(
                    context: context,
                    icon: LucideIcons.users,
                    title: "Study Rooms",
                    subtitle: "Collaborate in real-time",
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudyRoomsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Recent Activity", style: AppTypography.headingSmall(isDark: isDark)),
                if (_recentMaterials.isNotEmpty)
                  Text(
                    "${_recentMaterials.length} Items",
                    style: AppTypography.caption(isDark: isDark),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingRecent) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, _) => const SkeletonLoader(height: 72, borderRadius: 16),
              ),
            ] else if (_recentMaterials.isEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(LucideIcons.filePlus, color: AppColors.textSecondaryLight, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("No study materials yet", style: AppTypography.headingSmall(isDark: isDark)),
                          const SizedBox(height: 2),
                          Text(
                            "Upload a PDF or paste notes to generate your first AI study package.",
                            style: AppTypography.caption(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentMaterials.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final mat = _recentMaterials[index];
                  return CustomCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MaterialDetailScreen(material: mat)),
                      );
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mat.title,
                                style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${mat.quiz.length} Quiz Questions • ${mat.flashcards.length} Flashcards",
                                style: AppTypography.caption(isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickShortcutCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.caption(isDark: isDark), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
