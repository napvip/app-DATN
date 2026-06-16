import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/app_colors.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../data/datasources/article_service.dart';
import '../../../data/models/article_model.dart';

/// Trang đọc chi tiết một bài viết cẩm nang.
class ArticleDetailScreen extends StatefulWidget {
  final String articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _service = ArticleService();
  late Future<ArticleModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getArticleById(widget.articleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
        actions: [
          StreamBuilder<Set<String>>(
            stream: _service.getSavedArticleIds(),
            builder: (context, snap) {
              final isSaved = snap.data?.contains(widget.articleId) ?? false;
              return IconButton(
                tooltip: isSaved ? 'Bỏ lưu' : 'Lưu bài viết',
                icon: Icon(
                  LucideIcons.bookmark,
                  color: isSaved ? AppColors.primary : AppColors.foreground,
                ),
                onPressed: () async {
                  await _service.toggleSave(widget.articleId, !isSaved);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSaved ? 'Đã bỏ lưu' : 'Đã lưu bài viết'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<ArticleModel?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final article = snap.data;
          if (article == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Không tìm thấy bài viết'),
              ),
            );
          }
          return _buildContent(context, article);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ArticleModel article) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.coverImage.isNotEmpty) ...[
            CachedImage(
              imageUrl: article.coverImage,
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              article.category,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryForeground,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (article.authorName.isNotEmpty) ...[
                Text(
                  article.authorName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray600,
                  ),
                ),
                const Text('  ·  ',
                    style: TextStyle(color: AppColors.gray400)),
              ],
              Text(
                DateFormat('dd/MM/yyyy').format(article.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          HtmlWidget(
            article.content,
            textStyle: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.gray800,
            ),
          ),
        ],
      ),
    );
  }
}
