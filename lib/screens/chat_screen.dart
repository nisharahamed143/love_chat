import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/chat/chat_body_widget.dart';
import '../widgets/chat/chat_header_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Current Logged-in User ID powa na gele empty string pass hobe
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          ChatHeaderWidget(
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
          Expanded(
            child: ChatBodyWidget(
              currentUserId: currentUserId,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }
}