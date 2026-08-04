import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _avatarPresets = [
    "https://api.dicebear.com/7.x/bottts/png?seed=Alex",
    "https://api.dicebear.com/7.x/bottts/png?seed=Sarah",
    "https://api.dicebear.com/7.x/bottts/png?seed=Mike",
    "https://api.dicebear.com/7.x/bottts/png?seed=Emma",
    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80",
    "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150&auto=format&fit=crop&q=80",
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80",
    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80",
  ];

  void _showEditProfileBottomSheet() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;

    final nameController = TextEditingController(text: user?.name ?? "");
    final bioController = TextEditingController(text: user?.bio ?? "");
    final phoneController = TextEditingController(text: user?.phone ?? "");
    final avatarUrlController = TextEditingController(text: user?.avatar ?? "");
    String selectedAvatar = user?.avatar ?? "";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                        const Icon(LucideIcons.userCog, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          "Edit Profile & Avatar",
                          style: AppTypography.headingMedium(isDark: isDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Avatar Selection Row
                    Text("Select Avatar Preset:", style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 14)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _avatarPresets.map((url) {
                          final isSelected = selectedAvatar == url;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedAvatar = url;
                                avatarUrlController.text = url;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(url),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: avatarUrlController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Custom Avatar Image URL",
                        hintText: "https://example.com/my-avatar.png",
                        prefixIcon: const Icon(LucideIcons.image, color: AppColors.primary),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setModalState(() => selectedAvatar = val.trim()),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Full Name",
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
                        labelText: "Bio & Study Headline",
                        prefixIcon: const Icon(LucideIcons.info, color: AppColors.primary),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: const Icon(LucideIcons.phone, color: AppColors.primary),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: "Save Changes",
                      icon: LucideIcons.save,
                      onPressed: () {
                        final newName = nameController.text.trim();
                        final newBio = bioController.text.trim();
                        final newPhone = phoneController.text.trim();

                        Navigator.pop(ctx);

                        auth.updateProfileDetails(
                          name: newName,
                          bio: newBio,
                          avatar: selectedAvatar,
                          phone: newPhone,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profile & Avatar updated instantly!"),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddProjectDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add Portfolio Project"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: "Project Title *",
                    hintText: "e.g. AI Study Assistant",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText: "Brief summary of what you built",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkCtrl,
                  decoration: InputDecoration(
                    labelText: "Project Link / URL",
                    hintText: "https://github.com/...",
                    prefixIcon: const Icon(LucideIcons.link, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                Navigator.pop(ctx);
                final auth = Provider.of<AuthService>(context, listen: false);

                final updatedUser = await ApiService.addPortfolioProject(
                  token: auth.token ?? "",
                  title: title,
                  description: descCtrl.text.trim(),
                  link: linkCtrl.text.trim(),
                );

                if (updatedUser != null && mounted) {
                  auth.updateUserState(updatedUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Project added to portfolio!")),
                  );
                }
              },
              child: const Text("Add Project", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteProject(String projectId) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final updatedUser = await ApiService.deletePortfolioProject(
      token: auth.token ?? "",
      projectId: projectId,
    );

    if (updatedUser != null && mounted) {
      auth.updateUserState(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project removed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: Navigator.canPop(context)
          ? AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text("My Profile", style: AppTypography.headingMedium(isDark: isDark)),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Header with Tap-to-Edit Avatar
            Center(
              child: GestureDetector(
                onTap: _showEditProfileBottomSheet,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      backgroundImage: (user?.avatar != null && user!.avatar.isNotEmpty)
                          ? NetworkImage(user.avatar)
                          : null,
                      child: (user?.avatar == null || user!.avatar.isEmpty)
                          ? const Icon(LucideIcons.user, size: 44, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(user?.name ?? "Student", style: AppTypography.headingMedium(isDark: isDark)),
            ),
            Center(
              child: Text(user?.email ?? "user@studymate.ai", style: AppTypography.caption(isDark: isDark)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      "Verified Account",
                      style: AppTypography.caption(isDark: isDark).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user?.bio ?? "Passionate learner & builder",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(isDark: isDark),
              ),
            ),
            const SizedBox(height: 16),

            // Prominent Edit Profile Button
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                icon: const Icon(LucideIcons.userCog, size: 18, color: AppColors.primary),
                label: const Text(
                  "Edit Profile & Avatar",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                onPressed: _showEditProfileBottomSheet,
              ),
            ),
            const SizedBox(height: 28),

            // Portfolio Projects Section Header
            Row(
              children: [
                const Icon(LucideIcons.folderKanban, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text("Portfolio & Projects", style: AppTypography.headingSmall(isDark: isDark)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddProjectDialog,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text("Add Project"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Projects List
            if (user?.projects == null || user!.projects.isEmpty) ...[
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(LucideIcons.briefcase, size: 36, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 10),
                        Text(
                          "No projects added yet",
                          style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Showcase your study projects, GitHub repos, or live demos on your profile.",
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...user.projects.map((project) => _buildProjectCard(project, isDark)),
            ],

            const SizedBox(height: 28),

            // Sign Out
            CustomButton(
              text: "Sign Out",
              icon: LucideIcons.logOut,
              isSecondary: true,
              onPressed: () async {
                final navigator = Navigator.of(context);
                await auth.logout();
                if (mounted) {
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectItem project, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.grey),
                  onPressed: () => _deleteProject(project.id),
                ),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                project.description,
                style: AppTypography.bodyMedium(isDark: isDark),
              ),
            ],
            if (project.link.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(LucideIcons.externalLink, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      project.link,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
