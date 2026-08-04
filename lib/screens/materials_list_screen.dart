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
import 'upload_study_screen.dart';

class MaterialsListScreen extends StatefulWidget {
  const MaterialsListScreen({super.key});

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  List<MaterialModel> _materials = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final materials = await ApiService.fetchUserMaterials(auth.token!);
      if (mounted) {
        setState(() {
          _materials = materials;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteMaterial(String id) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Study Package?"),
        content: const Text("Are you sure you want to delete this study package? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteMaterial(id, auth.token!);
      if (success && mounted) {
        setState(() {
          _materials.removeWhere((m) => m.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Material deleted successfully.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _materials.where((m) {
      return m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.summary.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: Navigator.canPop(context)
          ? AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text("My Study Materials", style: AppTypography.headingMedium(isDark: isDark)),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.plus),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UploadStudyScreen()),
                    ).then((_) => _fetchMaterials());
                  },
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetchMaterials,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "Search saved packages...",
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? ListView.separated(
                        itemCount: 4,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, _) => const SkeletonLoader(height: 100, borderRadius: 16),
                      )
                    : filtered.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return CustomCard(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MaterialDetailScreen(material: item),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.sourceType == "pdf"
                                                ? AppColors.primary.withValues(alpha: 0.15)
                                                : AppColors.accent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                item.sourceType == "pdf" ? LucideIcons.fileText : LucideIcons.alignLeft,
                                                size: 14,
                                                color: item.sourceType == "pdf" ? AppColors.primary : AppColors.accent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.sourceType.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: item.sourceType == "pdf" ? AppColors.primary : AppColors.accent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.grey),
                                          onPressed: () => _deleteMaterial(item.id),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.title,
                                      style: AppTypography.headingSmall(isDark: isDark),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.summary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMedium(isDark: isDark),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(LucideIcons.helpCircle, size: 14, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${item.quiz.length} Questions",
                                          style: AppTypography.caption(isDark: isDark),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(LucideIcons.layers, size: 14, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${item.flashcards.length} Cards",
                                          style: AppTypography.caption(isDark: isDark),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.folderOpen, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            "No Study Materials Yet",
            style: AppTypography.headingMedium(isDark: isDark),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Upload a PDF or paste notes to generate your first AI summary, quiz & flashcard deck.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(isDark: isDark),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadStudyScreen()),
              ).then((_) => _fetchMaterials());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
            label: const Text("Create Study Package", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
