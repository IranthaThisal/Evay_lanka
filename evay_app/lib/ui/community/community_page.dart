import 'dart:io';
import 'dart:typed_data';
import 'package:evay_app/models/news_model.dart';
import 'package:evay_app/services/news_api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _controller = TextEditingController();
  final NewsApiService _newsApiService = NewsApiService();
  File? _image;
  Uint8List? _imageBytes;
  late Future<List<NewsModel>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsApiService.fetchLatest(limit: 8);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pick image
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      _imageBytes = await picked.readAsBytes();
      _image = null;
    } else {
      _image = File(picked.path);
      _imageBytes = null;
    }
    setState(() {});
  }

  /// Upload image
  Future<String?> _uploadImage(String postId) async {
    if (_image == null && _imageBytes == null) return null;

    final ref = FirebaseStorage.instance.ref().child(
      'posts/$postId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (_imageBytes != null) {
      await ref.putData(_imageBytes!);
    } else {
      await ref.putFile(_image!);
    }

    return await ref.getDownloadURL();
  }

  /// Create post
  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_controller.text.trim().isEmpty &&
        _image == null &&
        _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot post empty content")),
      );
      return;
    }

    final doc = FirebaseFirestore.instance.collection('posts').doc();
    final imageUrl = await _uploadImage(doc.id);

    await doc.set({
      'userId': user.uid,
      'userName': user.displayName ?? "User",
      'userAvatar': user.photoURL ?? "",
      'content': _controller.text.trim(),
      'images':
          imageUrl != null
              ? [
                {'url': imageUrl},
              ]
              : [],
      'likesCount': 0,
      'likedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    _controller.clear();
    _image = null;
    _imageBytes = null;
    setState(() {});
  }

  Future<void> _refreshNews() async {
    final future = _newsApiService.fetchLatest(limit: 8);
    setState(() {
      _newsFuture = future;
    });
    await future;
  }

  Widget _buildPost(DocumentSnapshot doc) {
    final palette = context.evayPalette;
    final cs = Theme.of(context).colorScheme;
    final data = doc.data() as Map<String, dynamic>;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final content = (data['content'] ?? '').toString();
    final likesCount = (data['likesCount'] ?? 0);

    final likedBy =
        (data['likedBy'] is List) ? List<String>.from(data['likedBy']) : [];

    final hasLiked = userId != null && likedBy.contains(userId);

    final images =
        (data['images'] is List)
            ? List<Map<String, dynamic>>.from(data['images'])
            : [];

    final isOwner = userId == data['userId'];
    final createdAt = _toDateTime(data['createdAt']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header (avatar + name)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      data['userAvatar'] != ""
                          ? NetworkImage(data['userAvatar'])
                          : null,
                  child:
                      data['userAvatar'] == ""
                          ? const Icon(Icons.person)
                          : null,
                ),
                const SizedBox(width: 10),
                Text(
                  data['userName'] ?? "User",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (createdAt != null)
                  Text(
                    _formatTimestamp(createdAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                const Spacer(),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => doc.reference.delete(),
                  ),
              ],
            ),
          ),

          /// Content
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(content),
            ),

          /// Image
          if (images.isNotEmpty && images[0]['url'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Image.network(
                images[0]['url'],
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),

          /// Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    hasLiked ? Icons.favorite : Icons.favorite_border,
                    color: hasLiked ? palette.danger : cs.onSurface,
                  ),
                  onPressed:
                      userId == null
                          ? null
                          : () async {
                            if (hasLiked) {
                              await doc.reference.update({
                                'likesCount': (likesCount - 1).clamp(0, 9999),
                                'likedBy': FieldValue.arrayRemove([userId]),
                              });
                            } else {
                              await doc.reference.update({
                                'likesCount': likesCount + 1,
                                'likedBy': FieldValue.arrayUnion([userId]),
                              });
                            }
                          },
                ),
                Text('$likesCount'),

                const SizedBox(width: 16),

                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true, // IMPORTANT
                      backgroundColor: Colors.transparent,
                      builder:
                          (_) => DraggableScrollableSheet(
                            initialChildSize: 0.7,
                            minChildSize: 0.5,
                            maxChildSize: 0.95,
                            expand: false,
                            builder: (context, scrollController) {
                              return CommentSheet(
                                postId: doc.id,
                                scrollController: scrollController,
                              );
                            },
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsModel news) {
    final palette = context.evayPalette;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: palette.newsCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.newsBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((news.imageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                news.imageUrl!,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.newsChip,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'EV News',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(news.publishedAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  news.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  news.summary,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  news.sourceName,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _formatTimestamp(DateTime dateTime) {
    return DateFormat('MMM d, y - h:mm a').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: "What's happening?"),
            ),
            const SizedBox(height: 8),
            if (_imageBytes != null)
              Image.memory(_imageBytes!, height: 120)
            else if (_image != null)
              Image.file(_image!, height: 120),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                ElevatedButton(
                  onPressed: _createPost,
                  child: const Text("Post"),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh news',
                  onPressed: _refreshNews,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (!_newsApiService.isConfigured)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.evayPalette.warningBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.evayPalette.warningBorder),
                ),
                child: const Text(
                  'EV news is ready. Start the app with --dart-define=NEWS_API_KEY=your_key to show live EV industry headlines in this feed.',
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, postSnapshot) {
                  if (!postSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return FutureBuilder<List<NewsModel>>(
                    future: _newsFuture,
                    builder: (context, newsSnapshot) {
                      final docs = postSnapshot.data!.docs;
                      final news = newsSnapshot.data ?? <NewsModel>[];
                      final feedItems =
                          <Map<String, dynamic>>[
                            ...docs.map(
                              (doc) => <String, dynamic>{
                                'type': 'post',
                                'createdAt':
                                    _toDateTime(
                                      (doc.data() as Map<String, dynamic>)['createdAt'],
                                    ) ??
                                    DateTime.fromMillisecondsSinceEpoch(0),
                                'data': doc,
                              },
                            ),
                            ...news.map(
                              (item) => <String, dynamic>{
                                'type': 'news',
                                'createdAt': item.publishedAt,
                                'data': item,
                              },
                            ),
                          ]..sort(
                            (a, b) => (b['createdAt'] as DateTime).compareTo(
                              a['createdAt'] as DateTime,
                            ),
                          );

                      return RefreshIndicator(
                        onRefresh: _refreshNews,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: feedItems.length,
                          itemBuilder: (_, i) {
                            final item = feedItems[i];
                            if (item['type'] == 'news') {
                              return _buildNewsCard(item['data'] as NewsModel);
                            }
                            return _buildPost(item['data'] as DocumentSnapshot);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentSheet extends StatefulWidget {
  final String postId;
  final ScrollController scrollController;

  const CommentSheet({
    super.key,
    required this.postId,
    required this.scrollController,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).dividerColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const Text(
            "Comments",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 10),

          /// COMMENTS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final commentTime = _toDateTime(data['createdAt']);
                    final isOwner = currentUser?.uid == data['userId'];
                    final avatarUrl = (data['userAvatar'] ?? '').toString();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child:
                            avatarUrl.isEmpty
                                ? const Icon(Icons.person, size: 18)
                                : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              (data['userName'] ?? 'User').toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (commentTime != null)
                            Text(
                              DateFormat('MMM d - h:mm a').format(
                                commentTime.toLocal(),
                              ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text((data['text'] ?? '').toString()),
                      ),
                      trailing:
                          isOwner
                              ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed:
                                    () => docs[i].reference.delete(),
                              )
                              : null,
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT FIELD (fixed at bottom)
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (controller.text.trim().isEmpty || currentUser == null) {
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .add({
                          'userId': currentUser.uid,
                          'userName':
                              currentUser.displayName?.trim().isNotEmpty == true
                                  ? currentUser.displayName!.trim()
                                  : 'User',
                          'userAvatar': currentUser.photoURL ?? '',
                          'text': controller.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                    controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
