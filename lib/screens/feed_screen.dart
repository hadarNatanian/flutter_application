import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import '../services/weather_service.dart';
import 'detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Map<String, dynamic>? _weather;
  final _filterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final data = await WeatherService.getWeather('Jerusalem');
    if (mounted) setState(() => _weather = data);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('טיולים בטבע 🌿'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_weather != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.thermostat, size: 16),
                  Text(
                    '${_weather!['main']['temp'].toStringAsFixed(0)}°C',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(provider.darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: provider.toggleDarkMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _filterCtrl,
              decoration: InputDecoration(
                hintText: 'סנן לפי מיקום...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _filterCtrl.clear();
                    provider.setFilter('');
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: provider.setFilter,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: provider.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildOfflineFeed(provider);
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var posts = snapshot.data!.docs
                    .map((d) => Post.fromFirestore(d))
                    .toList();
                if (provider.filterLocation.isNotEmpty) {
                  posts = posts
                      .where((p) => p.location
                          .toLowerCase()
                          .contains(provider.filterLocation.toLowerCase()))
                      .toList();
                }
                if (posts.isEmpty) {
                  return const Center(child: Text('אין פוסטים עדיין'));
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (_, i) => PostCard(
                    post: posts[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(post: posts[i])),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineFeed(AppProvider provider) {
    final bookmarks = provider.bookmarks;
    if (bookmarks.isEmpty) {
      return const Center(child: Text('אין חיבור לאינטרנט ואין מועדפים שמורים'));
    }
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('מצב אופליין - מציג מועדפים', style: TextStyle(color: Colors.orange)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (_, i) => PostCard(
              post: bookmarks[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(post: bookmarks[i])),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
