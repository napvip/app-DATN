import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../data/datasources/article_service.dart';
import '../../../data/models/article_model.dart';

/// Tab "Cẩm nang" — đọc các bài viết về ong & kỹ thuật nuôi ong do admin đăng.
class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final _service = ArticleService();
  final _searchController = TextEditingController();

  String _search = '';
  String? _category; // null = tất cả danh mục
  bool _showSaved = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ArticleModel> _filter(List<ArticleModel> articles, Set<String> savedIds) {
    final q = _search.trim().toLowerCase();
    return articles.where((a) {
      if (_showSaved && !savedIds.contains(a.id)) return false;
      if (_category != null && a.category != _category) return false;
      if (q.isNotEmpty &&
          !a.title.toLowerCase().contains(q) &&
          !a.excerpt.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Set<String>>(
          stream: _service.getSavedArticleIds(),
          builder: (context, savedSnap) {
            final savedIds = savedSnap.data ?? <String>{};
            return StreamBuilder<List<ArticleModel>>(
              stream: _service.getPublishedArticles(),
              builder: (context, snap) {
                final loading =
                    snap.connectionState == ConnectionState.waiting;
                final all = snap.data ?? [];
                final articles = _filter(all, savedIds);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildSearch()),
                    SliverToBoxAdapter(child: _buildSegmented(savedIds.length)),
                    SliverToBoxAdapter(child: _buildCategoryChips()),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      )
                    else if (articles.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          icon: _showSaved
                              ? LucideIcons.bookmark
                              : LucideIcons.fileText,
                          title: _showSaved
                              ? 'Chưa lưu bài viết nào'
                              : 'Không có bài viết',
                          subtitle: _showSaved
                              ? 'Nhấn biểu tượng lưu để đọc lại sau'
                              : 'Hãy thử từ khoá hoặc danh mục khác',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        sliver: SliverList.separated(
                          itemCount: articles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final article = articles[i];
                            return _ArticleCard(
                              article: article,
                              isSaved: savedIds.contains(article.id),
                              onTap: () => context.push(
                                  '${AppRoutes.articleDetail}/${article.id}'),
                              onToggleSave: () => _service.toggleSave(
                                  article.id, !savedIds.contains(article.id)),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cẩm nang',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Kiến thức & kinh nghiệm nuôi ong',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm bài viết...',
          prefixIcon: const Icon(LucideIcons.search,
              size: 18, color: AppColors.gray400),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  color: AppColors.gray400,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmented(int savedCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegButton(
                label: 'Tất cả',
                isSelected: !_showSaved,
                onTap: () => setState(() => _showSaved = false),
              ),
            ),
            Expanded(
              child: _SegButton(
                label: savedCount > 0 ? 'Đã lưu ($savedCount)' : 'Đã lưu',
                isSelected: _showSaved,
                onTap: () => setState(() => _showSaved = true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _CategoryChip(
              label: 'Tất cả',
              isSelected: _category == null,
              onTap: () => setState(() => _category = null),
            ),
            for (final c in ArticleCategories.all)
              _CategoryChip(
                label: c,
                isSelected: _category == c,
                onTap: () => setState(() => _category = c),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Segmented toggle button (Tất cả / Đã lưu)
// =============================================================================

class _SegButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:
                  isSelected ? AppColors.foreground : AppColors.mutedForeground,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Category chip
// =============================================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : AppColors.muted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.secondaryForeground
                  : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Article card (thumbnail trái + nội dung phải)
// =============================================================================

class _ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  const _ArticleCard({
    required this.article,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.coverImage.isNotEmpty)
            CachedImage(
              imageUrl: article.coverImage,
              width: 92,
              height: 92,
              borderRadius: BorderRadius.circular(12),
            )
          else
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.fileText,
                  color: AppColors.gray400, size: 26),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        article.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggleSave,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          LucideIcons.bookmark,
                          size: 18,
                          color: isSaved
                              ? AppColors.primary
                              : AppColors.gray400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(article.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
