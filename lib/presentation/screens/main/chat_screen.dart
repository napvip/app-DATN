import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../config/app_colors.dart';
import '../../../data/datasources/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = ChatService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  String? _conversationId;
  List<ChatMessage> _messages = [];
  StreamSubscription? _msgSub;

  bool _loading = true;
  bool _sending = false;
  bool _hasError = false;

  // ảnh đang chờ gửi
  Uint8List? _pendingBytes;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (mounted) setState(() { _loading = true; _hasError = false; });
    try {
      final id = await _service.getOrCreateConversationId();
      _msgSub?.cancel();
      _msgSub = _service.messagesStream(id).listen((msgs) {
        if (!mounted) return;
        setState(() => _messages = msgs);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      });
      await _service.markUserRead(id);
      if (mounted) setState(() { _conversationId = id; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (animate) {
      _scrollCtrl.animateTo(max,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _scrollCtrl.jumpTo(max);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (!mounted) return;
    setState(() { _pendingBytes = bytes; });
  }

  void _cancelPending() => setState(() { _pendingBytes = null; });

  Future<void> _send() async {
    if (_conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa kết nối được. Vui lòng thử lại.')),
      );
      _init();
      return;
    }
    final text = _textCtrl.text.trim();
    final bytes = _pendingBytes;

    if (text.isEmpty && bytes == null) return;
    if (_sending || _uploadingImage) return;

    setState(() { _sending = true; _pendingBytes = null; });
    _textCtrl.clear();

    try {
      if (bytes != null) {
        setState(() => _uploadingImage = true);
        await _service.sendImageMessage(_conversationId!, bytes,
            caption: text.isEmpty ? null : text);
        setState(() => _uploadingImage = false);
      } else {
        await _service.sendTextMessage(_conversationId!, text);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi thất bại. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() { _sending = false; _uploadingImage = false; });
    }

    _focusNode.requestFocus();
  }

  // ── date separator helper ──────────────────────────────────────────────────

  bool _showDateSep(int i) {
    if (i == 0) return true;
    final prev = _messages[i - 1].createdAt;
    final curr = _messages[i].createdAt;
    return !DateUtils.isSameDay(prev, curr);
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(d, now)) return 'Hôm nay';
    if (DateUtils.isSameDay(d, now.subtract(const Duration(days: 1)))) return 'Hôm qua';
    return DateFormat('d MMMM yyyy', 'vi').format(d);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _hasError
              ? _buildErrorState()
              : Column(
                  children: [
                    Expanded(child: _buildMessageList()),
                    if (_pendingBytes != null) _buildImagePreviewBar(),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('B',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BeeGuard Support',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foreground)),
              Text('Đội ngũ hỗ trợ',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.mutedForeground),
          const SizedBox(height: 12),
          const Text('Không thể kết nối',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Kiểm tra kết nối mạng và thử lại',
              style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
          const SizedBox(height: 16),
          TextButton(onPressed: _init, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('B',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('BeeGuard Support',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Gửi tin nhắn để được hỗ trợ',
                style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final msg = _messages[i];
        return Column(
          children: [
            if (_showDateSep(i)) _DateChip(label: _dateLabel(msg.createdAt)),
            _MessageBubble(
              message: msg,
              onImageTap: (url) => _showImageOverlay(url),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagePreviewBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _pendingBytes!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Ảnh đã chọn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text('Nhấn gửi hoặc thêm chú thích bên dưới',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cancelPending,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.muted,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: AppColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 10
            : MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x0F000000))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image picker button
          _IconBtn(
            onTap: _pickImage,
            child: const Icon(Icons.image_outlined, size: 22, color: AppColors.mutedForeground),
          ),
          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          AnimatedBuilder(
            animation: _textCtrl,
            builder: (_, __) {
              final canSend = _textCtrl.text.trim().isNotEmpty || _pendingBytes != null;
              return _SendButton(
                canSend: canSend && !_sending && !_uploadingImage,
                loading: _sending || _uploadingImage,
                onTap: _send,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showImageOverlay(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const CircularProgressIndicator(color: Colors.white),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(ctx).padding.top + 8,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.07), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
            ),
          ),
          Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.07), thickness: 1)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String url) onImageTap;

  const _MessageBubble({required this.message, required this.onImageTap});

  @override
  Widget build(BuildContext context) {
    final isMe = !message.isAdmin;
    final time = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Admin avatar
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('B',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
            ),
          ],

          // Bubble content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Image
                if (message.hasImage)
                  GestureDetector(
                    onTap: () => onImageTap(message.imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                          height: 160,
                          color: AppColors.muted,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 120,
                          color: AppColors.muted,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppColors.mutedForeground),
                        ),
                      ),
                    ),
                  ),

                // Text
                if (message.hasText)
                  Container(
                    margin: message.hasImage ? const EdgeInsets.only(top: 2) : EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : AppColors.foreground,
                        height: 1.4,
                      ),
                    ),
                  ),

                // Time
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _IconBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool canSend;
  final bool loading;
  final VoidCallback onTap;

  const _SendButton({
    required this.canSend,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () { if (canSend) onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: canSend ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded,
                size: 18,
                color: Colors.white),
      ),
    );
  }
}
