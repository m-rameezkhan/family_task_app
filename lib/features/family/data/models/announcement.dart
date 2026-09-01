import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String familyId;
  final String createdBy;
  final String createdByName;
  final String title;
  final String message;
  final String type; // announcement, update, warning, important
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<String> seenBy; // UIDs of members who have seen this

  const Announcement({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.createdByName,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.seenBy = const [],
  });

  factory Announcement.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
    return Announcement(
      id: document.id,
      familyId: data['familyId'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Admin',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'announcement',
      createdAt: date('createdAt') ?? DateTime.now(),
      expiresAt: date('expiresAt'),
      seenBy: List<String>.from(data['seenBy'] as List? ?? []),
    );
  }

  // Check if announcement is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'familyId': familyId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'seenBy': seenBy,
    };
  }

  // Mark as seen by a user
  Announcement markSeenBy(String userId) {
    if (seenBy.contains(userId)) return this;
    return Announcement(
      id: id,
      familyId: familyId,
      createdBy: createdBy,
      createdByName: createdByName,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      expiresAt: expiresAt,
      seenBy: [...seenBy, userId],
    );
  }
}
