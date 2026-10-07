import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/contact_model.dart';

enum ViewState { loading, success, empty, error }

class ChatViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CustomContact> _appUsers = [];
  List<CustomContact> filteredContacts = [];

  ViewState state = ViewState.loading;
  String errorMessage = '';

  ChatViewModel() {
    // অ্যাপের লাইফসাইকেল অবজার্ভার স্টার্ট
    WidgetsBinding.instance.addObserver(this);
    setUserOnlineStatus(true);
  }

  // ইউজারের লাইফসাইকেল স্টেট চেঞ্জ চেক করা (Online / Offline / Last Seen)
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      setUserOnlineStatus(true);
    } else if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.detached ||
        lifecycleState == AppLifecycleState.inactive) {
      setUserOnlineStatus(false);
    }
  }

  // Firestore এ Online/Offline স্টেটাস আপডেট করা
  Future<void> setUserOnlineStatus(bool isOnline) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating online status: $e");
    }
  }

  // অ্যাপ ইউজারদের রিয়েল-টাইম স্ট্রিম (Stream)
  Stream<QuerySnapshot> getAppUsersStream() {
    final currentUserId = _auth.currentUser?.uid;
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .snapshots();
  }

  void filterContacts(String query) {
    if (query.isEmpty) {
      filteredContacts = List.from(_appUsers);
    } else {
      filteredContacts = _appUsers
          .where((c) =>
      c.name.toLowerCase().contains(query.toLowerCase()) ||
          c.phoneNumber.contains(query))
          .toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    setUserOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}