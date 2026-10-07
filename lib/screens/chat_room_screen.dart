import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverPhone;
  final bool isOnline;
  final Timestamp? lastSeen;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhone,
    required this.isOnline,
    this.lastSeen,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // চ্যাট রুমে প্রবেশ করার সাথে সাথে মেসেজগুলো 'Seen' হিসেবে মার্ক হবে
    _markAsSeen();
  }

  void _markAsSeen() {
    _chatService.markMessagesAsSeen(widget.receiverId);
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _messageController.clear();
      await _chatService.sendMessage(widget.receiverId, text);
    }
  }

  String _formatLastSeen(Timestamp? timestamp) {
    if (timestamp == null) return "Offline";
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "Last seen just now";
    } else if (difference.inHours < 1) {
      return "Last seen ${difference.inMinutes}m ago";
    } else if (difference.inDays < 1) {
      return "Last seen ${difference.inHours}h ago";
    } else {
      return "Last seen ${date.day}/${date.month}/${date.year}";
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0083B0),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          // রিয়েল-টাইমে অনলাইন স্ট্যাটাস এবং Last Seen দেখার জন্য
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverId)
              .snapshots(),
          builder: (context, snapshot) {
            bool isOnline = widget.isOnline;
            Timestamp? lastSeen = widget.lastSeen;

            if (snapshot.hasData && snapshot.data!.data() != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              isOnline = data['isOnline'] ?? false;
              lastSeen = data['lastSeen'];
            }

            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Text(
                        widget.receiverName.isNotEmpty
                            ? widget.receiverName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? Colors.greenAccent.shade700
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receiverName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isOnline ? "Online" : _formatLastSeen(lastSeen),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Message List Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(_currentUserId, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF0083B0)),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // মেসেজ স্ট্রিম চলাকালীন সময়েও কোনো নতুন মেসেজ এলে অটোমেটিক 'Seen' মার্ক করে দেওয়া
                _markAsSeen();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          "Say hi to ${widget.receiverName}!",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // 👈 মেসেজ ফ্লো নিচ থেকে ওপরের দিকে ওল্টানোর জন্য
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == _currentUserId;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? const LinearGradient(
                            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                          )
                              : null,
                          color: isMe ? null : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          data['message'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF18ECB0), Color(0xFF0083B0)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}