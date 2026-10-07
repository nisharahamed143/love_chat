class ChatMessageModel {
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isSeen; // 👈 ১. নতুন ফিল্ড যুক্ত করুন

  ChatMessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isSeen = false, // 👈 ২. Default value false হিসেবে যোগ করুন
  });

  // Map এ রূপান্তর করার জন্য
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isSeen': isSeen, // 👈 ৩. Map-এ যুক্ত করুন
    };
  }

  // Map থেকে Model অবজেক্ট তৈরি করার জন্য
  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      isSeen: map['isSeen'] ?? false, // 👈 ৪. Read করার সময় Parse করুন
    );
  }
}