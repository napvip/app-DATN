import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/article_model.dart';

/// Service đọc bài viết cẩm nang (admin đăng) và quản lý bài viết đã lưu
/// của người dùng hiện tại.
class ArticleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'articles';

  String? get _currentUserId => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // Danh sách bài viết đã xuất bản (sort client-side, tránh composite index)
  // ---------------------------------------------------------------------------

  Stream<List<ArticleModel>> getPublishedArticles() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ArticleModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ---------------------------------------------------------------------------
  // Chi tiết một bài viết
  // ---------------------------------------------------------------------------

  Future<ArticleModel?> getArticleById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return ArticleModel.fromMap(doc.data()!, doc.id);
  }

  // ---------------------------------------------------------------------------
  // Bài viết đã lưu — users/{uid}/saved_articles/{articleId}
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>>? get _savedRef {
    final uid = _currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('saved_articles');
  }

  /// Stream tập hợp id các bài đã lưu (để lọc danh sách / hiện trạng thái nút).
  Stream<Set<String>> getSavedArticleIds() {
    final ref = _savedRef;
    if (ref == null) return Stream.value(<String>{});
    return ref.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> toggleSave(String articleId, bool save) async {
    final ref = _savedRef;
    if (ref == null) throw Exception('Chưa đăng nhập');
    if (save) {
      await ref.doc(articleId).set({
        'savedAt': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      await ref.doc(articleId).delete();
    }
  }
}
