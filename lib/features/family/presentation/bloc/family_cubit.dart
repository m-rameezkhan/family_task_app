import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/family.dart';
import '../../data/repositories/family_repository.dart';

class FamilyState {
  final Family? family;
  final List<FamilyMember> members;
  final bool loading;
  final String? error;

  const FamilyState({
    this.family,
    this.members = const [],
    this.loading = false,
    this.error,
  });

  FamilyState copyWith({
    Family? family,
    List<FamilyMember>? members,
    bool? loading,
    String? error,
  }) {
    return FamilyState(
      family: family ?? this.family,
      members: members ?? this.members,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class FamilyCubit extends Cubit<FamilyState> {
  final FamilyRepository _repository;
  final String userId;
  final FirebaseFirestore _firestore;
  StreamSubscription<Family?>? _familySubscription;
  StreamSubscription<List<FamilyMember>>? _membersSubscription;

  FamilyCubit({
    required this._repository,
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       super(const FamilyState(loading: true)) {
    load();
  }

  Future<void> load() async {
    try {
      final user = await _firestore.collection('users').doc(userId).get();
      final familyId = user.data()?['familyId'] as String?;
      if (familyId == null || familyId.isEmpty) {
        emit(const FamilyState());
        return;
      }
      await _familySubscription?.cancel();
      await _membersSubscription?.cancel();
      _familySubscription = _repository
          .watchFamily(familyId)
          .listen(
            (family) => emit(state.copyWith(family: family, loading: false)),
          );
      _membersSubscription = _repository
          .watchMembers(familyId)
          .listen((members) => emit(state.copyWith(members: members)));
    } catch (error) {
      emit(FamilyState(error: error.toString(), loading: false));
    }
  }

  Future<void> create(String name, String userName) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.createFamily(
        userId: userId,
        userName: userName,
        familyName: name,
      );
      await load();
    } catch (error) {
      emit(FamilyState(error: error.toString(), loading: false));
    }
  }

  Future<void> join(String code, String userName) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.joinFamily(
        userId: userId,
        code: code,
        userName: userName,
      );
      await load();
    } catch (error) {
      emit(FamilyState(error: error.toString(), loading: false));
    }
  }

  @override
  Future<void> close() async {
    await _familySubscription?.cancel();
    await _membersSubscription?.cancel();
    return super.close();
  }
}
