import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatBodyWidget extends StatefulWidget {
  final String searchQuery;

  const ChatBodyWidget({
    super.key,
    this.searchQuery = '',
  });

  @override
  State<ChatBodyWidget> createState() => _ChatBodyWidgetState();
}

class _ChatBodyWidgetState extends State<ChatBodyWidget> {
  List<Contact> _contacts = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  // ডিভাইস থেকে কনট্যাক্টস নিয়ে আসার ফাংশন
  Future<void> _fetchContacts() async {
    PermissionStatus permissionStatus = await Permission.contacts.request();

    if (permissionStatus.isGranted) {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        List<Contact> contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
        );
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // সার্চ ফিল্টারিং logic
    final filteredContacts = _contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0083B0)),
        ),
      );
    }

    if (_permissionDenied) {
      return _buildPermissionDeniedView();
    }

    if (filteredContacts.isEmpty) {
      return _buildEmptyStateView();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 90, left: 16, right: 16),
      itemCount: filteredContacts.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        final String phoneNumber = contact.phones.isNotEmpty
            ? contact.phones.first.number
            : "No phone number";

        return _buildContactTile(
          context: context,
          contact: contact,
          phoneNumber: phoneNumber,
          index: index,
        );
      },
    );
  }

  // প্রিমিয়াম কাস্টম চ্যাট টাইল উইজেট
  Widget _buildContactTile({
    required BuildContext context,
    required Contact contact,
    required String phoneNumber,
    required int index,
  }) {
    // ডামি লাস্ট চ্যাট ও টাইম তৈরি করা
    final List<String> dummyTimes = ["10:45 AM", "Yesterday", "9:30 AM", "2 days ago"];
    final String time = dummyTimes[index % dummyTimes.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          onTap: () {
            // TODO: চ্যাট ডিটেইলস পেজে নেভিগেট করার কোড যুক্ত করুন
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              // প্রোফাইল ইমেজ বা ফার্স্ট লেটার অ্যাভাটার
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF00B4DB).withOpacity(0.15),
                backgroundImage: contact.photo != null
                    ? MemoryImage(contact.photo!)
                    : null,
                child: contact.photo == null
                    ? Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                          color: Color(0xFF0083B0),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              // অনলাইন একটিভ ডট индикаটর
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.greenAccent.shade700 : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  contact.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    phoneNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                // আনরিড মেসেজ ব্যাজ
                if (index % 3 == 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "2",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // পারমিশন না দিলে দেখানোর ভিউ
  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "Contact Permission Needed",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchContacts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0083B0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Allow Access", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // সার্চ বা লিস্ট খালি থাকলে দেখানোর ভিউ
  Widget _buildEmptyStateView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 55, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            "No contacts found",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}