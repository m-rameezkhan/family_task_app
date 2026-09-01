import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement.dart';
import '../models/family.dart';

class FamilyRepository {
  final FirebaseFirestore _firestore;

  FamilyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _families =>
      _firestore.collection('families');

  /// Create a new family (creator becomes head)
  Future<Family> createFamily({
    required String userId,
    required String userName,
    required String familyName,
  }) async {
    final familyId = _families.doc().id;
    final code = _createCode();
    final now = Timestamp.now();
    final batch = _firestore.batch();

    // Create family document
    batch.set(_families.doc(familyId), {
      'familyId': familyId,
      'familyName': familyName.trim(),
      'familyCode': code,
      'createdBy': userId,
      'headId': userId, // Creator is head
      'canLeaveFrozen': false,
      'createdAt': now,
      'updatedAt': now,
    });

    // Add user as head member
    batch.set(_families.doc(familyId).collection('members').doc(userId), {
      'fullName': userName,
      'nickname': '',
      'email': '',
      'photoUrl': null,
      'dateOfBirth': null,
      'joinedAt': now,
      'isHead': true,
    });

    // Update user doc
    batch.set(_firestore.collection('users').doc(userId), {
      'uid': userId,
      'name': userName,
      'familyId': familyId,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
    final snapshot = await _families.doc(familyId).get();
    return Family.fromDocument(snapshot);
  }

  /// Join an existing family
  Future<Family> joinFamily({
    required String userId,
    required String code,
    required String userName,
  }) async {
    final result = await _families
        .where('familyCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      throw Exception('No family found with that code.');
    }

    final family = Family.fromDocument(result.docs.first);
    final batch = _firestore.batch();
    final now = Timestamp.now();

    // Add user as member
    batch.set(_families.doc(family.id).collection('members').doc(userId), {
      'fullName': userName,
      'nickname': '',
      'email': '',
      'photoUrl': null,
      'dateOfBirth': null,
      'joinedAt': now,
      'isHead': false,
    });

    // Update user doc
    batch.set(_firestore.collection('users').doc(userId), {
      'familyId': family.id,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
    return family;
  }

  /// Watch family document
  Stream<Family?> watchFamily(String? familyId) {
    if (familyId == null || familyId.isEmpty) return Stream.value(null);
    return _families
        .doc(familyId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists ? Family.fromDocument(snapshot) : null,
        );
  }

  /// Watch family members
  Stream<List<FamilyMember>> watchMembers(String familyId) {
    return _families
        .doc(familyId)
        .collection('members')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FamilyMember.fromDocument).toList(),
        );
  }

  /// Get a specific member
  Future<FamilyMember?> getMember(String familyId, String memberId) async {
    final doc = await _families
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .get();
    return doc.exists ? FamilyMember.fromDocument(doc) : null;
  }

  /// Update member profile
  Future<void> updateMember(
    String familyId,
    String memberId,
    FamilyMember member,
  ) async {
    await _families
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .update(member.toDocument());
  }

  /// Remove member from family
  Future<void> removeMember(String familyId, String memberId) async {
    final batch = _firestore.batch();

    // Remove from members collection
    batch.delete(_families.doc(familyId).collection('members').doc(memberId));

    // Update user document
    batch.set(_firestore.collection('users').doc(memberId), {
      'familyId': null,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Leave family
  Future<void> leaveFamilyFamily(String familyId, String userId) async {
    await removeMember(familyId, userId);
  }

  /// Update family settings (head only)
  Future<void> updateFamilySettings(
    String familyId, {
    String? name,
    bool? canLeaveFrozen,
  }) async {
    final updates = <String, dynamic>{'updatedAt': Timestamp.now()};
    if (name != null) updates['familyName'] = name;
    if (canLeaveFrozen != null) updates['canLeaveFrozen'] = canLeaveFrozen;

    await _families.doc(familyId).update(updates);
  }

  /// Create announcement (head only)
  Future<String> createAnnouncement(
    String familyId,
    String createdBy,
    String createdByName,
    String title,
    String message,
    String type, {
    DateTime? expiresAt,
  }) async {
    final docRef = _families.doc(familyId).collection('announcements').doc();

    await docRef.set({
      'familyId': familyId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'title': title.trim(),
      'message': message.trim(),
      'type': type,
      'createdAt': Timestamp.now(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'seenBy': [],
    });

    return docRef.id;
  }

  /// Watch announcements
  Stream<List<Announcement>> watchAnnouncements(String familyId) {
    return _families
        .doc(familyId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Announcement.fromDocument)
              .where((a) => !a.isExpired)
              .toList(),
        );
  }

  /// Mark announcement as seen
  Future<void> markAnnouncementSeen(
    String familyId,
    String announcementId,
    String userId,
  ) async {
    final doc = await _families
        .doc(familyId)
        .collection('announcements')
        .doc(announcementId)
        .get();

    if (doc.exists) {
      final seenBy = List<String>.from(doc.data()?['seenBy'] as List? ?? []);
      if (!seenBy.contains(userId)) {
        seenBy.add(userId);
        await _families
            .doc(familyId)
            .collection('announcements')
            .doc(announcementId)
            .update({'seenBy': seenBy});
      }
    }
  }

  /// Generate unique family code
  String _createCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
