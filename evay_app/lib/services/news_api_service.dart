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

  static List<NewsModel>? _cachedItems;
  static DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<List<NewsModel>> fetchLatest({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    if (!isConfigured) {
      return const <NewsModel>[];
    }

    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedItems != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheTtl) {
      return _cachedItems!;
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
      final response = await http
          .get(uri, headers: <String, String>{'X-Api-Key': _apiKey})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return _cachedItems ?? const <NewsModel>[];
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
                now,
          ),
        );
      }

      _cachedItems = items;
      _lastFetchTime = now;
      return items;
    } catch (_) {
      return _cachedItems ?? const <NewsModel>[];
    }
  }

  bool _looksLikeEvNews(String title, String description, String sourceName) {
    final haystack = '$title $description $sourceName'.toLowerCase();
    final hasRequiredTerm = _requiredEvTerms.any(haystack.contains);
    final hasBlockedTerm = _blockedGeneralTerms.any(haystack.contains);
    return hasRequiredTerm && !hasBlockedTerm;
  }
}
