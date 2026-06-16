import 'package:cloud_firestore/cloud_firestore.dart';

/// Danh mục bài viết — danh sách cố định, dùng chung với web admin.
/// Lưu trong Firestore dưới dạng chuỗi nhãn (label) cho đơn giản.
class ArticleCategories {
  ArticleCategories._();

  static const String beekeeping = 'Kỹ thuật nuôi ong';
  static const String disease = 'Bệnh & sâu hại';
  static const String harvest = 'Thu hoạch mật';
  static const String breed = 'Giống ong';
  static const String season = 'Mùa vụ & thời tiết';
  static const String other = 'Khác';

  /// Thứ tự hiển thị trong bộ lọc.
  static const List<String> all = [
    beekeeping,
    disease,
    harvest,
    breed,
    season,
    other,
  ];
}

/// Bài viết cẩm nang nuôi ong do admin đăng. Collection `articles`.
class ArticleModel {
  final String id;
  final String title;

  /// Mô tả ngắn hiển thị ở danh sách.
  final String excerpt;

  /// Nội dung đầy đủ — HTML xuất từ CKEditor bên web admin.
  final String content;

  final String category;

  /// Ảnh bìa (Cloudinary URL). Có thể rỗng.
  final String coverImage;

  /// 'published' | 'draft' — app chỉ hiển thị bài 'published'.
  final String status;

  final String authorName;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.category,
    required this.coverImage,
    required this.status,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublished => status == 'published';

  factory ArticleModel.fromMap(Map<String, dynamic> map, String docId) {
    return ArticleModel(
      id: docId,
      title: map['title'] ?? '',
      excerpt: map['excerpt'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? ArticleCategories.other,
      coverImage: map['coverImage'] ?? '',
      status: map['status'] ?? 'draft',
      authorName: map['authorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'category': category,
      'coverImage': coverImage,
      'status': status,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
