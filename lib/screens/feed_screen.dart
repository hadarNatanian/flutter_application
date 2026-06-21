import 'dart:async';
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
  final _focusNode = FocusNode();
  String _currentFilter = '';
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  bool _isFiltering = false;
  Timer? _debounceTimer;
  Stream<QuerySnapshot>? _postsStream;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _postsStream = context.read<AppProvider>().getPostsStream();
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    final data = await WeatherService.getWeather('Jerusalem');
    if (mounted) setState(() => _weather = data);
  }

  void _filterPosts(String query) {
    // בטל את הטיימר הקודם אם קיים
    _debounceTimer?.cancel();

    // עדכן מיידי את מצב הסינון בלי setState
    _currentFilter = query.trim();
    _isFiltering = _currentFilter.isNotEmpty;

    // דחיית עדכון המסך ל-300 מילישניות
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_currentFilter.isEmpty) {
        _filteredPosts = List.from(_allPosts);
      } else {
        _filteredPosts = _allPosts
            .where(
              (post) => post.location.toLowerCase().contains(
                _currentFilter.toLowerCase(),
              ),
            )
            .toList();
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _clearFilter() {
    _debounceTimer?.cancel();
    _filterCtrl.clear();
    _currentFilter = '';
    _filteredPosts = List.from(_allPosts);
    _isFiltering = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.darkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: provider.toggleDarkMode,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 2,
              child: TextField(
                controller: _filterCtrl,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'סינון לפי מיקום - הקלידי שם עיר...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Color(0xFF2E7D32),
                  ),
                  suffixIcon: _isFiltering
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearFilter,
                        )
                      : const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _filterPosts,
                textInputAction: TextInputAction.search,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
          ),
          if (_isFiltering && _filterCtrl.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'מסנן לפי מיקום: "${_filterCtrl.text}"',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredPosts.length} תוצאות',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildOfflineFeed();
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                _allPosts = snapshot.data!.docs
                    .map((d) => Post.fromFirestore(d))
                    .toList();

                // אם אין סינון פעיל, הצג הכל
                // אם אין סינון פעיל, הצג הכל
                if (_currentFilter.isEmpty) {
                  _filteredPosts = _allPosts;
                } else {
                  // סינון ישיר, בלי setState ובלי טיימר - רק חישוב
                  _filteredPosts = _allPosts
                      .where(
                        (post) => post.location.toLowerCase().contains(
                          _currentFilter.toLowerCase(),
                        ),
                      )
                      .toList();
                }

                if (_filteredPosts.isEmpty && _isFiltering) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'אין דברים התואמים לחיפוש שלך!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'חיפשת: "${_filterCtrl.text}"',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'נסי להקליד שם עיר אחר או למחוק את החיפוש',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _clearFilter,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('נקה חיפוש'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_allPosts.isEmpty) {
                  return const Center(child: Text('אין פוסטים עדיין'));
                }

                return ListView.builder(
                  itemCount: _filteredPosts.length,
                  itemBuilder: (_, i) => PostCard(
                    post: _filteredPosts[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(post: _filteredPosts[i]),
                      ),
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

  Widget _buildOfflineFeed() {
    final provider = context.read<AppProvider>();
    final bookmarks = provider.bookmarks;
    if (bookmarks.isEmpty) {
      return const Center(
        child: Text('אין חיבור לאינטרנט ואין מועדפים שמורים'),
      );
    }
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'מצב אופליין - מציג מועדפים',
            style: TextStyle(color: Colors.orange),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (_, i) => PostCard(
              post: bookmarks[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(post: bookmarks[i]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
