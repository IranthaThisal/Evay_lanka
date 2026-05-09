import 'package:flutter/material.dart';
import 'package:evay_app/models/news_model.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.news});

  final NewsModel news;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(news.title),
        subtitle: Text(
          news.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${news.publishedAt.year}-${news.publishedAt.month.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
