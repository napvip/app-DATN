import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'cloudinary_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderType; // "admin" | "customer"
  final String text;
  final String imageUrl;
  final DateTime createdAt;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.read,
  });

  bool get isAdmin => senderType == 'admin';
  bool get hasImage => imageUrl.isNotEmpty;
  bool get hasText => text.isNotEmpty;

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      senderType: d['senderType'] ?? 'customer',
      text: d['text'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: d['read'] == true,
    );
  }
}

class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadUserCount;

  const ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadUserCount,
  });
}

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _userName => _auth.currentUser?.displayName ?? 'Khách hàng';
  String get _userPhoto => _auth.currentUser?.photoURL ?? '';

  // ── Lấy hoặc tạo conversation cho user hiện tại ───────────────────────────

  Future<String> getOrCreateConversationId() async {
    final q = await _db
        .collection('conversations')
        .where('userId', isEqualTo: _uid)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return q.docs.first.id;

    final ref = await _db.collection('conversations').add({
      'userId': _uid,
      'userName': _userName,
      'userPhoto': _userPhoto,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'unreadUserCount': 0,
    });
    return ref.id;
  }

  // ── Stream tin nhắn ───────────────────────────────────────────────────────

  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
  }

  // ── Stream unread count từ admin (badge hiển thị trên UI) ─────────────────

  Stream<int> unreadUserCountStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((s) => (s.data()?['unreadUserCount'] as int?) ?? 0);
  }

  // ── Gửi tin nhắn văn bản ─────────────────────────────────────────────────

  Future<void> sendTextMessage(String conversationId, String text) async {
    if (text.trim().isEmpty) return;
    await _sendMessage(conversationId, text: text.trim());
  }

  // ── Gửi ảnh (upload Cloudinary trước) ────────────────────────────────────

  Future<void> sendImageMessage(
    String conversationId,
    Uint8List imageBytes, {
    String? caption,
  }) async {
    final url = await CloudinaryService.uploadImage(
      imageBytes,
      folder: 'chat',
    );
    await _sendMessage(conversationId, imageUrl: url, text: caption ?? '');
  }

  Future<void> _sendMessage(
    String conversationId, {
    String text = '',
    String imageUrl = '',
  }) async {
    final batch = _db.batch();

    final msgRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': _uid,
      'senderType': 'customer',
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    final lastMsg =
        imageUrl.isNotEmpty && text.isEmpty ? '[Ảnh]' : text.isEmpty ? '[Ảnh]' : text;

    batch.update(
      _db.collection('conversations').doc(conversationId),
      {
        'lastMessage': lastMsg,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
        'unreadUserCount': 0,
        // cập nhật thông tin user phòng khi tên/ảnh thay đổi
        'userName': _userName,
        'userPhoto': _userPhoto,
      },
    );

    await batch.commit();
  }

  // ── Đánh dấu đã đọc (user mở chat → unreadUserCount = 0) ─────────────────

  Future<void> markUserRead(String conversationId) async {
    await _db.collection('conversations').doc(conversationId).update({
      'unreadUserCount': 0,
    });
  }
}
