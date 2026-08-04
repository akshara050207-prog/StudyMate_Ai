import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/room_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/skeleton_loader.dart';
import 'room_detail_screen.dart';

class StudyRoomsScreen extends StatefulWidget {
  const StudyRoomsScreen({super.key});

  @override
  State<StudyRoomsScreen> createState() => _StudyRoomsScreenState();
}

class _StudyRoomsScreenState extends State<StudyRoomsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();

  // Featured rooms state
  List<RoomModel> _featuredRooms = [];
  bool _isLoadingFeatured = true;
  String _selectedSubjectFilter = "All";

  final List<String> _subjectFilters = [
    "All",
    "Computer Science",
    "Algorithms",
    "Web Dev",
    "Mathematics",
    "General"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeaturedRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadFeaturedRooms() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) {
      setState(() => _isLoadingFeatured = false);
      return;
    }

    setState(() => _isLoadingFeatured = true);
    try {
      final rooms = await ApiService.fetchFeaturedRooms(auth.token!);
      if (mounted) {
        setState(() {
          _featuredRooms = rooms;
          _isLoadingFeatured = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFeatured = false);
      }
    }
  }

  void _joinFeaturedRoom(RoomModel room) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final joinedRoom = await ApiService.joinRoom(
      roomId: room.id,
      token: auth.token ?? "",
    );

    if (mounted) {
      final targetRoom = joinedRoom ?? room;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomDetailScreen(room: targetRoom),
        ),
      );
    }
  }

  void _joinRoomByCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final room = await ApiService.joinRoom(
      code: code,
      token: auth.token ?? "",
    );

    if (mounted && context.mounted) {
      if (room != null) {
        _codeController.clear();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomDetailScreen(room: room),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid room code or room no longer active."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCreateRoomDialog({bool isPublic = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedTag = "Computer Science";

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isPublic ? "Create Featured Group Room" : "Create Private Room",
                style: AppTypography.headingMedium(isDark: isDark),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPublic
                          ? "Featured rooms are discoverable to all study groups by subject tag."
                          : "Private rooms can be joined by friends using a generated room code.",
                      style: AppTypography.caption(isDark: isDark),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Room Title *",
                        hintText: "e.g. AI & Neural Networks Hub",
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: topicCtrl,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Study Topic *",
                        hintText: "e.g. Deep Learning, Backpropagation",
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (isPublic) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTag,
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: "Subject Tag",
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ["Computer Science", "Algorithms", "Web Dev", "Mathematics", "General"]
                            .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedTag = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: "Description (Optional)",
                          hintText: "Welcome message & study goal...",
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final topic = topicCtrl.text.trim();
                    if (topic.isEmpty) return;

                    Navigator.pop(ctx);
                    final auth = Provider.of<AuthService>(context, listen: false);

                    final room = await ApiService.createRoom(
                      topic: topic,
                      title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : topic,
                      description: descCtrl.text.trim(),
                      subjectTag: selectedTag,
                      isPublic: isPublic,
                      token: auth.token ?? "",
                    );

                    if (mounted && context.mounted) {
                      if (room != null) {
                        if (isPublic) _loadFeaturedRooms();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailScreen(room: room),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Create Room", style: TextStyle(color: Colors.white)),
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
    final canPop = Navigator.canPop(context);

    final tabBarWidget = Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(LucideIcons.globe, size: 18), text: "Featured Group Rooms"),
          Tab(icon: Icon(LucideIcons.lock, size: 18), text: "Private Code Rooms"),
        ],
      ),
    );

    return Scaffold(
      appBar: canPop
          ? AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text("Group Study Rooms", style: AppTypography.headingMedium(isDark: isDark)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: tabBarWidget,
              ),
            )
          : null,
      body: Column(
        children: [
          if (!canPop) tabBarWidget,
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeaturedRoomsTab(isDark),
                _buildPrivateRoomsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRoomsTab(bool isDark) {
    final filteredRooms = _featuredRooms.where((r) {
      if (_selectedSubjectFilter == "All") return true;
      return r.subjectTag.toLowerCase() == _selectedSubjectFilter.toLowerCase();
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadFeaturedRooms,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Public Room Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Featured Public Rooms",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Browse subject topics and join group study discussions instantly.",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateRoomDialog(isPublic: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text("Create", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Subject Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _subjectFilters.map((filter) {
                  final isSelected = _selectedSubjectFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubjectFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDark : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Featured Rooms List
            if (_isLoadingFeatured) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, _) => const SkeletonLoader(height: 120, borderRadius: 18),
              )
            ] else if (filteredRooms.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(LucideIcons.searchX, size: 48, color: AppColors.textSecondaryLight),
                      const SizedBox(height: 12),
                      Text("No Featured Rooms Found", style: AppTypography.headingSmall(isDark: isDark)),
                      const SizedBox(height: 4),
                      Text("Be the first to create a public room for this subject!", style: AppTypography.caption(isDark: isDark)),
                    ],
                  ),
                ),
              )
            ] else ...[
              ...filteredRooms.map((room) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  room.subjectTag,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(LucideIcons.users, size: 14, color: AppColors.textSecondaryLight),
                              const SizedBox(width: 4),
                              Text(
                                "${room.participants.length} Active",
                                style: AppTypography.caption(isDark: isDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            room.title,
                            style: AppTypography.headingSmall(isDark: isDark).copyWith(fontSize: 17),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Topic: ${room.topic}",
                            style: AppTypography.bodyMedium(isDark: isDark).copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (room.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              room.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(isDark: isDark),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _joinFeaturedRoom(room),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(LucideIcons.logIn, size: 16, color: Colors.white),
                                label: const Text("Join Room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateRoomsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            padding: const EdgeInsets.all(20),
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
                      child: const Icon(LucideIcons.keyRound, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Join Private Room via Code",
                        style: AppTypography.headingSmall(isDark: isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: "ENTER 6-CHAR CODE",
                    hintStyle: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: "Enter Private Room",
                  icon: LucideIcons.arrowRight,
                  onPressed: _joinRoomByCode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.plus, color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Create New Private Room",
                        style: AppTypography.headingSmall(isDark: isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Generates a unique 6-digit room code to share exclusively with your study group.",
                  style: AppTypography.bodyMedium(isDark: isDark),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: "Create Private Room",
                  isSecondary: true,
                  icon: LucideIcons.lock,
                  onPressed: () => _showCreateRoomDialog(isPublic: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
