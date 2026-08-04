import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_card.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token != null) {
      final list = await ApiService.fetchChatUsers(auth.token!);
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _users = [
            UserModel(
              id: "friend_1",
              email: "priya@studymate.ai",
              name: "Priya Sharma",
              avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Priya",
              bio: "Database & Flutter enthusiast",
              isVerifiedGmail: true,
              projects: [],
            ),
            UserModel(
              id: "friend_2",
              email: "rahul@studymate.ai",
              name: "Rahul Verma",
              avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Rahul",
              bio: "Python & Data Science student",
              isVerifiedGmail: true,
              projects: [],
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Direct Messages", style: AppTypography.headingMedium(isDark: isDark)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final friend = _users[index];
                return CustomCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(friend: friend),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: friend.avatar.isNotEmpty
                                ? NetworkImage(friend.avatar)
                                : null,
                            child: friend.avatar.isEmpty
                                ? Text(friend.name[0])
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.cardDark : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  friend.name,
                                  style: AppTypography.headingSmall(isDark: isDark),
                                ),
                                if (friend.isVerifiedGmail) ...[
                                  const SizedBox(width: 6),
                                  const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 16),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              friend.bio.isNotEmpty ? friend.bio : "Available for group study",
                              style: AppTypography.caption(isDark: isDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.messageSquare, color: AppColors.primary, size: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
