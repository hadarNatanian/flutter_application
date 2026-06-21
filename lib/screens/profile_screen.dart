import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  bool _uploading = false;

  Future<void> _submit(AppProvider provider, BuildContext sheetContext) async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final user = provider.currentUser!;
      await provider.addPost({
        'userId': user.uid,
        'userName': user.displayName ?? user.email,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'imageUrl': _imageUrlCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'createdAt': Timestamp.now(),
      });
      _titleCtrl.clear();
      _contentCtrl.clear();
      _locationCtrl.clear();
      _imageUrlCtrl.clear();
      if (context.mounted) Navigator.pop(sheetContext);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showAddPost(AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('פוסט חדש',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'כותרת', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'מיקום', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'תיאור המסלול', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'לינק לתמונה (אופציונלי)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploading ? null : () => _submit(provider, sheetCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: _uploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('פרסמי'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final user = provider.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('הפרופיל שלי'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPost(provider),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('פוסט חדש', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // חלק הפרופיל עם סליידר - לא ישתנה
          Container(
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF2E7D32),
                  child: Text(
                    (user.displayName ?? user.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(user.displayName ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                // סליידר עם Consumer נפרד
                Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('גודל טקסט: ${provider.fontSize.toInt()}', 
                                 style: TextStyle(fontSize: provider.fontSize)),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                                  activeTrackColor: const Color(0xFF2E7D32),
                                  inactiveTrackColor: Colors.grey[300],
                                  thumbColor: const Color(0xFF2E7D32),
                                  valueIndicatorColor: const Color(0xFF2E7D32),
                                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                ),
                                child: Slider(
                                  value: provider.fontSize,
                                  min: 12,
                                  max: 20,
                                  divisions: 8,
                                  onChanged: (value) {
                                    provider.setFontSize(value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'דוגמה לטקסט בגודל שנבחר',
                          style: TextStyle(
                            fontSize: provider.fontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('הפוסטים שלי',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          // רשימת הפוסטים - נפרדת מהסליידר
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: provider.getMyPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('שגיאה'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data!.docs
                    .map((d) => Post.fromFirestore(d))
                    .toList();
                if (posts.isEmpty) {
                  return const Center(child: Text('עוד לא פרסמת פוסטים'));
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
}
