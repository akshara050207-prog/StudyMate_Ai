import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../screens/auth/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer User Header - Tapping opens Profile & Edit Profile
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onItemSelected(5);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: (user?.avatar != null && user!.avatar.isNotEmpty)
                          ? NetworkImage(user.avatar)
                          : null,
                      child: (user?.avatar == null || user!.avatar.isEmpty)
                          ? const Icon(LucideIcons.user, size: 24, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? "Authenticated User",
                                  style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.edit3, size: 14, color: AppColors.primary),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? "user@studymate.ai",
                            style: AppTypography.caption(isDark: isDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.shieldCheck, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                "Tap to Edit Profile & Portfolio",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Navigation List Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _drawerTile(
                    context: context,
                    icon: LucideIcons.home,
                    label: "Home Dashboard",
                    index: 0,
                    isDark: isDark,
                  ),
                  _drawerTile(
                    context: context,
                    icon: LucideIcons.bot,
                    label: "AI Chat Assistant",
                    index: 1,
                    isDark: isDark,
                  ),
                  _drawerTile(
                    context: context,
                    icon: LucideIcons.users,
                    label: "Group Study Rooms",
                    index: 2,
                    isDark: isDark,
                  ),
                  _drawerTile(
                    context: context,
                    icon: LucideIcons.fileUp,
                    label: "PDF Upload & Analysis",
                    index: 3,
                    isDark: isDark,
                  ),
                  _drawerTile(
                    context: context,
                    icon: LucideIcons.folderOpen,
                    label: "My Study Materials",
                    index: 4,
                    isDark: isDark,
                  ),
                  _drawerTile(
                    context: context,
                    icon: LucideIcons.folderKanban,
                    label: "My Profile & Portfolio",
                    index: 5,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Sign Out
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
                title: const Text(
                  "Sign Out",
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14.5,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          onItemSelected(index);
        },
      ),
    );
  }
}
