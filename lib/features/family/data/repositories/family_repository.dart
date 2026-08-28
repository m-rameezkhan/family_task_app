import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/family.dart';

class FamilyRepository {
  final FirebaseFirestore _firestore;

  FamilyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _families =>
      _firestore.collection('families');

  Future<Family> createFamily({
    required String userId,
    required String userName,
    required String familyName,
  }) async {
    final familyId = _families.doc().id;
    final code = _createCode();
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(_families.doc(familyId), {
      'familyId': familyId,
      'familyName': familyName.trim(),
      'familyCode': code,
      'createdBy': userId,
      'createdAt': now,
      'updatedAt': now,
    });
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

  Future<Family> joinFamily({
    required String userId,
    required String code,
  }) async {
    final result = await _families
        .where('familyCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (result.docs.isEmpty) {
      throw Exception('No family found with that code.');
    }
    final family = Family.fromDocument(result.docs.first);
    await _firestore.collection('users').doc(userId).set({
      'familyId': family.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return family;
  }

  Stream<Family?> watchFamily(String? familyId) {
    if (familyId == null || familyId.isEmpty) return Stream.value(null);
    return _families
        .doc(familyId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists ? Family.fromDocument(snapshot) : null,
        );
  }

  Stream<List<FamilyMember>> watchMembers(String familyId) {
    return _firestore
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FamilyMember.fromDocument).toList(),
        );
  }

  String _createCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
