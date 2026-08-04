import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'home_screen.dart';
import 'ai_assistant/ai_assistant_screen.dart';
import 'study_rooms/study_rooms_screen.dart';
import 'upload_study_screen.dart';
import 'materials_list_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentUser != null) {
        final socket = Provider.of<SocketService>(context, listen: false);
        socket.initSocket(auth.currentUser!.id);
      }
    });
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    AIAssistantScreen(),
    StudyRoomsScreen(),
    UploadStudyScreen(),
    MaterialsListScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    "StudyMate AI",
    "AI Chat Assistant",
    "Group Study Rooms",
    "PDF Upload & Analysis",
    "My Study Materials",
    "My Profile & Portfolio",
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: isWideScreen
            ? null
            : AppBar(
                leading: Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(LucideIcons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    tooltip: "Open Sidebar Menu",
                  ),
                ),
                title: Text(
                  _titles[_currentIndex],
                  style: AppTypography.headingMedium(isDark: isDark),
                ),
                centerTitle: true,
                actions: [
                  if (_currentIndex == 0)
                    IconButton(
                      icon: const Icon(LucideIcons.sparkles, color: AppColors.primary),
                      onPressed: () => setState(() => _currentIndex = 1),
                      tooltip: "AI Assistant",
                    ),
                ],
              ),
        drawer: isWideScreen
            ? null
            : AppDrawer(
                selectedIndex: _currentIndex,
                onItemSelected: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
        body: Row(
          children: [
            if (isWideScreen)
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() => _currentIndex = index);
                },
                labelType: NavigationRailLabelType.selected,
                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                selectedIconTheme: const IconThemeData(color: AppColors.primary),
                unselectedIconTheme: IconThemeData(color: isDark ? Colors.white60 : Colors.black54),
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Icon(LucideIcons.sparkles, color: AppColors.primary, size: 28),
                ),
                destinations: const [
                  NavigationRailDestination(icon: Icon(LucideIcons.home), label: Text("Home")),
                  NavigationRailDestination(icon: Icon(LucideIcons.bot), label: Text("AI Chat")),
                  NavigationRailDestination(icon: Icon(LucideIcons.users), label: Text("Rooms")),
                  NavigationRailDestination(icon: Icon(LucideIcons.fileUp), label: Text("Upload")),
                  NavigationRailDestination(icon: Icon(LucideIcons.folder), label: Text("Materials")),
                  NavigationRailDestination(icon: Icon(LucideIcons.user), label: Text("Profile")),
                ],
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
