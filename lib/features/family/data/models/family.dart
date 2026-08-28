import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final String code;
  final String createdBy;
  final DateTime? createdAt;

  const Family({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.createdAt,
  });

  factory Family.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return Family(
      id: data['familyId'] as String? ?? document.id,
      name: data['familyName'] as String? ?? 'Family',
      code: data['familyCode'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class FamilyMember {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  factory FamilyMember.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return FamilyMember(
      id: document.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : _nameFromEmail(data['email'] as String?),
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  static String _nameFromEmail(String? email) {
    final localPart = email?.split('@').first.trim() ?? '';
    return localPart.isEmpty ? 'Family member' : localPart;
  }
}
