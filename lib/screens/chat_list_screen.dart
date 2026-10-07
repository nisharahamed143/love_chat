import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';
import 'login_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: const Color(0xFF0083B0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading users: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No other users found'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00B4DB),
                  child: Text(
                    (user['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user['name'] ?? 'User'),
                subtitle: Text(user['phoneNumber'] ?? ''),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () {
                  // ✅ Safe check for id/uid
                  final String receiverId = user['id'] ?? user['uid'] ?? '';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        receiverId: receiverId,
                        receiverName: user['name'] ?? 'User',
                        receiverPhone: user['phoneNumber'] ?? '',
                        isOnline: user['isOnline'] ?? false,
                        lastSeen: user['lastSeen'] as Timestamp?,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}