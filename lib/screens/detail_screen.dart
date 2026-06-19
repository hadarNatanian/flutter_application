import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../providers/app_provider.dart';
import '../services/weather_service.dart';

class DetailScreen extends StatefulWidget {
  final Post post;
  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _commentCtrl = TextEditingController();
  Map<String, dynamic>? _weather;

  @override
  void initState() {
    super.initState();
    if (widget.post.location.isNotEmpty) {
      WeatherService.getWeather(widget.post.location)
          .then((data) => mounted ? setState(() => _weather = data) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bookmarked = provider.isBookmarked(widget.post.id);
    final fontSize = provider.fontSize;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => provider.toggleBookmark(widget.post),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post.imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.post.imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.post.location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                              Text(widget.post.location,
                                  style: const TextStyle(color: Color(0xFF2E7D32))),
                              if (_weather != null) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.thermostat, size: 16),
                                Text(
                                    '${_weather!['main']['temp'].toStringAsFixed(0)}°C - ${_weather!['weather'][0]['description']}'),
                              ],
                            ],
                          ),
                        const SizedBox(height: 12),
                        Text(
                          widget.post.content,
                          style: TextStyle(fontSize: fontSize),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'פורסם על ידי: ${widget.post.userName}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const Divider(height: 32),
                        const Text('תגובות',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: provider.getCommentsStream(widget.post.id),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final comments = snapshot.data!.docs;
                            if (comments.isEmpty) {
                              return const Text('אין תגובות עדיין');
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              itemBuilder: (_, i) {
                                final data =
                                    comments[i].data() as Map<String, dynamic>;
                                return ListTile(
                                  leading: const CircleAvatar(
                                      child: Icon(Icons.person)),
                                  title: Text(data['userName'] ?? ''),
                                  subtitle: Text(data['text'] ?? ''),
                                  dense: true,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'הוסיפי תגובה...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                  onPressed: () async {
                    if (_commentCtrl.text.trim().isEmpty) return;
                    await provider.addComment(
                        widget.post.id, _commentCtrl.text.trim());
                    _commentCtrl.clear();
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
