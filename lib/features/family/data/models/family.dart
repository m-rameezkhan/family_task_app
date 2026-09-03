import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final String code;
  final String createdBy;
  final String headId; // Family head (usually creator)
  final bool canLeaveFrozen; // Head can prevent members from leaving
  final DateTime? createdAt;

  const Family({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.headId,
    this.canLeaveFrozen = false,
    required this.createdAt,
  });

  factory Family.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return Family(
      id: data['familyId'] as String? ?? document.id,
      name: data['familyName'] as String? ?? 'Family',
      code: data['familyCode'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      headId: data['headId'] as String? ?? (data['createdBy'] as String? ?? ''),
      canLeaveFrozen: data['canLeaveFrozen'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create a copy with modified fields
  Family copyWith({
    String? id,
    String? name,
    String? code,
    String? createdBy,
    String? headId,
    bool? canLeaveFrozen,
    DateTime? createdAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      headId: headId ?? this.headId,
      canLeaveFrozen: canLeaveFrozen ?? this.canLeaveFrozen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'familyId': id,
      'familyName': name,
      'familyCode': code,
      'createdBy': createdBy,
      'headId': headId,
      'canLeaveFrozen': canLeaveFrozen,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

class FamilyMember {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? nickname;
  final DateTime? dateOfBirth;
  final DateTime? joinedAt;
  final bool isHead;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.nickname,
    this.dateOfBirth,
    this.joinedAt,
    this.isHead = false,
  });

  factory FamilyMember.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
    return FamilyMember(
      id: data['id'] as String? ?? data['uid'] as String? ?? document.id,
      name: (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? (data['fullName'] as String).trim()
          : (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : _nameFromEmail(data['email'] as String?),
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      nickname: data['nickname'] as String?,
      dateOfBirth: date('dateOfBirth'),
      joinedAt: date('joinedAt'),
      isHead: data['isHead'] as bool? ?? false,
    );
  }

  factory FamilyMember.fromUserDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
    return FamilyMember(
      id: data['uid'] as String? ?? document.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : _nameFromEmail(data['email'] as String?),
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      joinedAt: date('createdAt'),
    );
  }

  static String _nameFromEmail(String? email) {
    final localPart = email?.split('@').first.trim() ?? '';
    return localPart.isEmpty ? 'Family member' : localPart;
  }

  // Create a copy with modified fields
  FamilyMember copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? nickname,
    DateTime? dateOfBirth,
    DateTime? joinedAt,
    bool? isHead,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      nickname: nickname ?? this.nickname,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      joinedAt: joinedAt ?? this.joinedAt,
      isHead: isHead ?? this.isHead,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'id': id,
      'fullName': name,
      'nickname': nickname,
      'email': email,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'isHead': isHead,
    };
  }
}
