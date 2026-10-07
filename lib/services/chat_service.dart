import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getChatRoomId(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    return ids.join('_');
  }

  // ---------------------------------------------------------------------------
  // Message Send Kora & Push Notification Triggering
  // ---------------------------------------------------------------------------
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final DateTime timestamp = DateTime.now();

    ChatMessageModel newMessage = ChatMessageModel(
      senderId: currentUserId,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isSeen: false,
    );

    String chatRoomId = _getChatRoomId(currentUserId, receiverId);

    // ১. Firestore Sub-collection-e Message Save
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // ২. Chat Room Metadata Update
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'participants': [currentUserId, receiverId],
    }, SetOptions(merge: true));

    // ৩. Send Push Notification to Receiver
    await _sendPushNotification(
      receiverId: receiverId,
      messageText: message,
    );
  }

  // ---------------------------------------------------------------------------
  // Push Notification Delivery Helper
  // ---------------------------------------------------------------------------
  Future<void> _sendPushNotification({
    required String receiverId,
    required String messageText,
  }) async {
    try {
      // Sender-এর Info নেওয়া
      final String currentUserId = _auth.currentUser?.uid ?? '';
      final senderDoc = await _firestore.collection('users').doc(currentUserId).get();
      final String senderName = senderDoc.data()?['name'] ?? 'New Message';

      // Receiver-এর FCM Token নেওয়া
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      final String? fcmToken = receiverDoc.data()?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) return;

      // Note: Production App-এ সিকিউরিটির জন্য Push Notification ট্রিগার Cloud Function দিয়ে চালানো সেরা।
    } catch (e) {
      // Handle Notification Exception gracefully
    }
  }

  // ---------------------------------------------------------------------------
  // Messages Stream
  // ---------------------------------------------------------------------------
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    String chatRoomId = _getChatRoomId(userId, otherUserId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Mark Messages as Seen
  // ---------------------------------------------------------------------------
  Future<void> markMessagesAsSeen(String receiverId) async {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    String chatRoomId = _getChatRoomId(currentUserId, receiverId);

    final unreadQuery = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isSeen', isEqualTo: false)
        .get();

    if (unreadQuery.docs.isNotEmpty) {
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadQuery.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ getUsers() Method (যুক্ত করা হয়েছে)
  // ---------------------------------------------------------------------------
  Stream<List<Map<String, dynamic>>> getUsers() {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Find User By Phone
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> findUserByPhone(String rawPhone) async {
    String cleanPhone = rawPhone.replaceAll(RegExp(r'\s+|-|\(\)'), '');
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+91$cleanPhone';
    }

    final query = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: cleanPhone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    }
    return null;
  }
}