import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsSection extends StatefulWidget {
  final String blockadeId;

  const CommentsSection({super.key, required this.blockadeId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode(); 
  bool _isSending = false;

  CollectionReference get _commentsRef => FirebaseFirestore.instance
      .collection('postingan')
      .doc(widget.blockadeId)
      .collection('comments');

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk untuk berkomentar')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final fullName = userDoc.data()?['fullName'] ??
          userDoc.data()?['fullname'] ??
          'Anonim';

      await _commentsRef.add({
        'text': text,
        'fullName': fullName,
        'userId': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _commentController.clear();
      _commentFocusNode.unfocus(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim komentar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    await _commentsRef.doc(commentId).delete();
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final surface = theme.cardColor;
    final caption = theme.textTheme.bodySmall;
    final isDark = theme.brightness == Brightness.dark;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Icon(Icons.comment_outlined, color: accent, size: 18),
              const SizedBox(width: 6),
              Text(
                'Komentar',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _commentsRef.orderBy('createdAt', descending: false).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Belum ada komentar. Jadilah yang pertama!',
                  style: caption?.copyWith(color: theme.hintColor),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                final isOwner = data['userId'] == currentUid;
                final author = (data['fullName'] ?? 'Anonim').toString();
                final createdAt = _timeAgo(data['createdAt']);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: accent.withOpacity(0.15),
                        child: Text(
                          author.isNotEmpty ? author[0].toUpperCase() : 'A',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        author,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      Text(
                                        createdAt,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['text'] ?? '',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 12),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _commentFocusNode.requestFocus();
                                      _commentController.text = '@$author ';
                                    },
                                    child: Text(
                                      'balas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  
                                  if (isOwner) ...[
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () => showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Hapus Komentar'),
                                          content: const Text('Yakin ingin menghapus komentar ini?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteComment(doc.id);
                                              },
                                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: const Text(
                                        'hapus',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        Divider(color: theme.dividerColor),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withOpacity(0.15),
                child: Icon(Icons.person, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode, 
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    hintStyle: caption?.copyWith(color: theme.hintColor),
                    filled: true,
                    fillColor: surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _sendComment,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isSending ? theme.disabledColor : accent,
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}