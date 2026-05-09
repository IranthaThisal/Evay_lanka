import 'dart:convert';

import 'package:evay_app/models/news_model.dart';
import 'package:http/http.dart' as http;

class NewsApiService {
  static const String _apiKey = String.fromEnvironment('NEWS_API_KEY');
  static const String _baseUrl = String.fromEnvironment(
    'NEWS_API_BASE_URL',
    defaultValue: 'https://newsapi.org/v2/everything',
  );
  static const List<String> _requiredEvTerms = <String>[
    'electric vehicle',
    'electric car',
    'ev charging',
    'charging station',
    'battery electric',
    'plug-in hybrid',
    'fast charger',
    'range anxiety',
    'charging network',
    'tesla',
    'byd',
    'nio',
    'xpeng',
    'rivian',
    'lucid',
    'polestar',
    'vinfast',
  ];
  static const List<String> _blockedGeneralTerms = <String>[
    'dating',
    'celebrity',
    'fashion',
    'supermodel',
    'actor',
    'actress',
    'movie',
    'tv show',
    'netflix',
    'cosmopolitan',
    'kardashian',
    'jenner',
  ];

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<List<NewsModel>> fetchLatest({int limit = 10}) async {
    if (!isConfigured) {
      return <NewsModel>[];
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: <String, String>{
        'q':
            '"electric vehicle" OR "electric car" OR "EV charging" OR '
            '"charging station" OR "battery electric vehicle"',
        'searchIn': 'title,description',
        'language': 'en',
        'sortBy': 'publishedAt',
        'pageSize': '$limit',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: <String, String>{'X-Api-Key': _apiKey},
      );

      if (response.statusCode != 200) {
        return <NewsModel>[];
      }

      final body = jsonDecode(response.body);
      final articles =
          (body is Map<String, dynamic> && body['articles'] is List)
              ? List<Map<String, dynamic>>.from(body['articles'] as List)
              : <Map<String, dynamic>>[];

      final seenTitles = <String>{};
      final items = <NewsModel>[];

      for (final article in articles) {
        final title = (article['title'] ?? '').toString().trim();
        if (title.isEmpty || !seenTitles.add(title.toLowerCase())) {
          continue;
        }

        final description = (article['description'] ?? '').toString().trim();
        final source = article['source'];
        final sourceName =
            source is Map<String, dynamic>
                ? (source['name'] ?? 'EV News').toString()
                : 'EV News';

        if (!_looksLikeEvNews(title, description, sourceName)) {
          continue;
        }

        items.add(
          NewsModel(
            id: (article['url'] ?? title).toString(),
            title: title,
            summary:
                description.isEmpty
                    ? 'Latest EV industry update.'
                    : description,
            sourceName: sourceName,
            url: article['url']?.toString(),
            imageUrl: article['urlToImage']?.toString(),
            publishedAt:
                DateTime.tryParse((article['publishedAt'] ?? '').toString()) ??
                DateTime.now(),
          ),
        );
      }

      return items;
    } catch (_) {
      return <NewsModel>[];
    }
  }

  bool _looksLikeEvNews(String title, String description, String sourceName) {
    final haystack = '$title $description $sourceName'.toLowerCase();
    final hasRequiredTerm = _requiredEvTerms.any(haystack.contains);
    final hasBlockedTerm = _blockedGeneralTerms.any(haystack.contains);
    return hasRequiredTerm && !hasBlockedTerm;
  }
}
