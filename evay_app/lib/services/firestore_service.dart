import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evay_app/models/post_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addPost(PostModel post) async {
    await _db.collection('posts').add(post.toMap());
  }

  Stream<List<PostModel>> postsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => PostModel.fromMap(d.data(), id: d.id))
                  .toList(),
        );
  }

  Future<List<PostModel>> fetchPostsOnce({int limit = 20}) async {
    final snap =
        await _db
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
    return snap.docs.map((d) => PostModel.fromMap(d.data(), id: d.id)).toList();
  }
}
