import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../screens/chat_room_screen.dart';

class ChatBodyWidget extends StatefulWidget {
  final String currentUserId;
  final String searchQuery;

  const ChatBodyWidget({
    Key? key,
    required this.currentUserId,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  State<ChatBodyWidget> createState() => _ChatBodyWidgetState();
}

class _ChatBodyWidgetState extends State<ChatBodyWidget> {
  // Local phone contacts cache
  Map<String, String> _localPhoneToNameMap = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceContacts();
  }

  // ---------------------------------------------------------------------------
  // HELPER: Number থেকে শেষ ১০ ডিজিট বের করা
  // ---------------------------------------------------------------------------
  String _getLast10Digits(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 10) {
      return clean.substring(clean.length - 10);
    }
    return clean;
  }

  // ---------------------------------------------------------------------------
  // HELPER: Phone contacts fetch & load
  // ---------------------------------------------------------------------------
  Future<void> _loadDeviceContacts() async {
    final PermissionStatus permission =
    await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (permission == PermissionStatus.granted) {
      final List<Contact> contacts = await FlutterContacts.getAll(
        properties: {
          ContactProperty.name,
          ContactProperty.phone,
        },
      );

      final Map<String, String> tempMap = {};
      for (final contact in contacts) {
        final name = contact.displayName?.trim() ?? '';
        if (name.isEmpty) continue;

        for (final phone in contact.phones) {
          final last10 = _getLast10Digits(phone.number);
          if (last10.length == 10) {
            tempMap[last10] = name;
          }
        }
      }

      if (mounted) {
        setState(() {
          _localPhoneToNameMap = tempMap;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION & SEEN MARKER
  // ---------------------------------------------------------------------------
  void _navigateToChatScreen({
    required String receiverId,
    required String receiverName,
    required String receiverPhone,
    required bool isOnline,
    Timestamp? lastSeen,
  }) async {
    // ১. Unread messages 'isSeen: true' করার লজিক
    final chatRoomId = _getChatRoomId(widget.currentUserId, receiverId);

    final unreadQuery = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: widget.currentUserId)
        .where('isSeen', isEqualTo: false)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isSeen': true});
    }
    await batch.commit();

    if (!mounted) return;

    // ২. ChatRoomScreen-এ নেভিগেট করা
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          receiverId: receiverId,
          receiverName: receiverName,
          receiverPhone: receiverPhone,
          isOnline: isOnline,
          lastSeen: lastSeen,
        ),
      ),
    );
  }

  String _getChatRoomId(String id1, String id2) {
    List<String> ids = [id1, id2];
    ids.sort();
    return ids.join('_');
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SHEET: Search এবং Contact Select করা
  // ---------------------------------------------------------------------------
  void _showSelectContactBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String sheetSearchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Contact',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or phone number...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          sheetSearchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text('No users found on app.'));
                          }

                          final allDocs = snapshot.data!.docs.where((doc) {
                            return doc.id != widget.currentUserId;
                          }).toList();

                          final List<Map<String, dynamic>> displayUsers = [];

                          for (var doc in allDocs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final String rawPhone =
                                data['phoneNumber']?.toString() ?? '';
                            final String dbName =
                                data['name']?.toString() ?? 'Unknown User';
                            final String last10 = _getLast10Digits(rawPhone);

                            final String displayName =
                                _localPhoneToNameMap[last10] ?? dbName;

                            final Map<String, dynamic> userMap = {
                              'id': doc.id,
                              'displayName': displayName,
                              'phoneNumber': rawPhone,
                              'isOnline': data['isOnline'] ?? false,
                              'lastSeen': data['lastSeen'],
                              'isSavedInPhone':
                              _localPhoneToNameMap.containsKey(last10),
                            };

                            if (sheetSearchQuery.isEmpty) {
                              displayUsers.add(userMap);
                            } else {
                              final nameMatches = displayName
                                  .toLowerCase()
                                  .contains(sheetSearchQuery);
                              final phoneMatches = rawPhone
                                  .replaceAll(RegExp(r'\D'), '')
                                  .contains(sheetSearchQuery);

                              if (nameMatches || phoneMatches) {
                                displayUsers.add(userMap);
                              }
                            }
                          }

                          if (displayUsers.isEmpty) {
                            return const Center(
                                child: Text('No matching users found.'));
                          }

                          return ListView.builder(
                            itemCount: displayUsers.length,
                            itemBuilder: (context, index) {
                              final user = displayUsers[index];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    user['displayName'].isNotEmpty
                                        ? user['displayName'][0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  user['displayName'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  user['isSavedInPhone']
                                      ? user['phoneNumber']
                                      : '${user['phoneNumber']} (Not in contacts)',
                                ),
                                trailing: const Icon(Icons.chat_bubble_outline),
                                onTap: () {
                                  Navigator.pop(context);
                                  _navigateToChatScreen(
                                    receiverId: user['id'],
                                    receiverName: user['displayName'],
                                    receiverPhone: user['phoneNumber'],
                                    isOnline: user['isOnline'],
                                    lastSeen: user['lastSeen'],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILDER (BODY: RECENT CHAT LIST)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: widget.currentUserId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading chat list'));
          }

          final chatRoomDocs = snapshot.data?.docs ?? [];

          if (chatRoomDocs.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet.\nTap the chat button to start messaging!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRoomDocs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final roomData = chatRoomDocs[index].data() as Map<String, dynamic>;
              final List participants = roomData['participants'] ?? [];
              final String otherUserId = participants.firstWhere(
                    (id) => id != widget.currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              // User Info Stream
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final String rawPhone = userData['phoneNumber']?.toString() ?? '';
                  final String dbName = userData['name']?.toString() ?? 'Unknown User';
                  final String last10 = _getLast10Digits(rawPhone);
                  final String displayName = _localPhoneToNameMap[last10] ?? dbName;
                  final bool isOnline = userData['isOnline'] ?? false;
                  final Timestamp? lastSeen = userData['lastSeen'];

                  // Global Search query filter
                  if (widget.searchQuery.isNotEmpty) {
                    final query = widget.searchQuery.toLowerCase();
                    final matchesName = displayName.toLowerCase().contains(query);
                    final matchesPhone = rawPhone.replaceAll(RegExp(r'\D'), '').contains(query);
                    if (!matchesName && !matchesPhone) {
                      return const SizedBox.shrink();
                    }
                  }

                  // Unread messages counter stream
                  final String chatRoomId = chatRoomDocs[index].id;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chat_rooms')
                        .doc(chatRoomId)
                        .collection('messages')
                        .where('receiverId', isEqualTo: widget.currentUserId)
                        .where('isSeen', isEqualTo: false)
                        .snapshots(),
                    builder: (context, unreadSnapshot) {
                      final int unreadCount = unreadSnapshot.data?.docs.length ?? 0;

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          roomData['lastMessage'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(roomData['lastMessageTime']),
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 18),
                          ],
                        ),
                        onTap: () {
                          _navigateToChatScreen(
                            receiverId: otherUserId,
                            receiverName: displayName,
                            receiverPhone: rawPhone,
                            isOnline: isOnline,
                            lastSeen: lastSeen,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 150.0),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () => _showSelectContactBottomSheet(context),
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }
}