class LoginModel {
  final String uid;
  final String mobileNo;

  LoginModel({
    required this.uid,
    required this.mobileNo,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'mobileNo': mobileNo, // Fixed: key name consistency
    };
  }

  factory LoginModel.fromMap(Map<String, dynamic> map) {
    return LoginModel(
      uid: map['uid'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
    );
  }

  LoginModel copyWith({
    String? uid,
    String? mobileNo,
  }) {
    return LoginModel(
      uid: uid ?? this.uid,
      mobileNo: mobileNo ?? this.mobileNo,
    );
  }
}