import 'dart:typed_data';

class CustomContact {
  final String id;
  final String name;
  final String phoneNumber;
  final Uint8List? photo;

  CustomContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.photo,
  });
}