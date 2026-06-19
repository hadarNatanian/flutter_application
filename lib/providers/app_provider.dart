import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  List<Post> _bookmarks = [];
  List<Post> get bookmarks => _bookmarks;

  bool _darkMode = false;
  bool get darkMode => _darkMode;

  double _fontSize = 14.0;
  double get fontSize => _fontSize;

  String _filterLocation = '';
  String get filterLocation => _filterLocation;

  AppProvider() {
    _loadPrefs();
    _loadBookmarks();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 14.0;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    notifyListeners();
  }

  void setFilter(String location) {
    _filterLocation = location;
    notifyListeners();
  }

  Future<void> _loadBookmarks() async {
    _bookmarks = await DatabaseService.getBookmarks();
    notifyListeners();
  }

  bool isBookmarked(String id) => _bookmarks.any((p) => p.id == id);

  Future<void> toggleBookmark(Post post) async {
    if (isBookmarked(post.id)) {
      await DatabaseService.deleteBookmark(post.id);
      _bookmarks.removeWhere((p) => p.id == post.id);
    } else {
      await DatabaseService.insertBookmark(post);
      _bookmarks.add(post);
    }
    notifyListeners();
  }

  Stream<QuerySnapshot> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMyPostsStream() {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: currentUser?.uid)
        .snapshots();
  }

  Future<void> addPost(Map<String, dynamic> data) async {
    await _firestore.collection('posts').add(data);
  }

  Future<void> addComment(String postId, String text) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': currentUser?.uid,
      'userName': currentUser?.displayName ?? currentUser?.email,
      'text': text,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots();
  }
}
