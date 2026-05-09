class NewsModel {
  final String id;
  final String title;
  final String summary;
  final String sourceName;
  final String? url;
  final String? imageUrl;
  final DateTime publishedAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.sourceName,
    this.url,
    this.imageUrl,
    DateTime? publishedAt,
  }) : publishedAt = publishedAt ?? DateTime.now();

  factory NewsModel.fromMap(Map<String, dynamic> map, {required String id}) {
    final p = map['publishedAt'];
    DateTime published;
    if (p is String) {
      published = DateTime.tryParse(p) ?? DateTime.now();
    } else {
      published = DateTime.now();
    }

    return NewsModel(
      id: id,
      title: map['title'] ?? '',
      summary: map['summary'] ?? '',
      sourceName: map['sourceName'] ?? 'EV News',
      url: map['url'],
      imageUrl: map['imageUrl'],
      publishedAt: published,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'summary': summary,
    'sourceName': sourceName,
    'url': url,
    'imageUrl': imageUrl,
    'publishedAt': publishedAt.toIso8601String(),
  };
}
