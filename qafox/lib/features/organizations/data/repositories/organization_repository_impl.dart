import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../shared/models/organization_model.dart';
import '../../domain/repositories/organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final FirestoreService _firestore;
  final Uuid _uuid;

  OrganizationRepositoryImpl(this._firestore, [Uuid? uuid])
    : _uuid = uuid ?? const Uuid();

  @override
  Stream<List<OrganizationModel>> streamUserOrganizations(String userId) {
    // Queries organizations where members subcollection contains user or query collection group
    return _firestore.streamCollection(FirestoreConstants.organizations).map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => OrganizationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<OrganizationModel> createOrganization({
    required String name,
    String? description,
    String? logoUrl,
    required String ownerId,
    required String ownerEmail,
    required String ownerName,
  }) async {
    final orgId = _uuid.v4();
    final org = OrganizationModel(
      id: orgId,
      name: name.trim(),
      description: description?.trim(),
      logoUrl: logoUrl,
      ownerId: ownerId,
      memberCount: 1,
      createdAt: DateTime.now(),
    );

    final ownerMember = OrgMemberModel(
      userId: ownerId,
      organizationId: orgId,
      role: UserRole.owner,
      email: ownerEmail,
      fullName: ownerName,
      joinedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    final orgRef = _firestore.doc('${FirestoreConstants.organizations}/$orgId');
    final memberRef = _firestore.doc(
      '${FirestoreConstants.organizations}/$orgId/${FirestoreConstants.members}/$ownerId',
    );

    batch.set(orgRef, org.toMap());
    batch.set(memberRef, ownerMember.toMap());
    await batch.commit();

    return org;
  }

  @override
  Future<OrganizationModel?> getOrganization(String orgId) async {
    final snapshot = await _firestore.getDoc(
      '${FirestoreConstants.organizations}/$orgId',
    );
    if (!snapshot.exists || snapshot.data() == null) return null;
    return OrganizationModel.fromMap(snapshot.data()!, snapshot.id);
  }

  @override
  Stream<List<OrgMemberModel>> streamOrganizationMembers(String orgId) {
    return _firestore
        .streamCollection(
          '${FirestoreConstants.organizations}/$orgId/${FirestoreConstants.members}',
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrgMemberModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<void> inviteMember({
    required String orgId,
    required String email,
    required UserRole role,
  }) async {
    // Find user by email in users collection
    final userQuery = await _firestore
        .collection(FirestoreConstants.users)
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    String userId;
    String fullName = email.split('@').first;
    String? photoUrl;

    if (userQuery.docs.isNotEmpty) {
      final doc = userQuery.docs.first;
      userId = doc.id;
      fullName = doc.data()['fullName'] ?? fullName;
      photoUrl = doc.data()['photoUrl'];
    } else {
      userId = _uuid.v4();
    }

    final newMember = OrgMemberModel(
      userId: userId,
      organizationId: orgId,
      role: role,
      email: email.trim().toLowerCase(),
      fullName: fullName,
      photoUrl: photoUrl,
      joinedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    final memberRef = _firestore.doc(
      '${FirestoreConstants.organizations}/$orgId/${FirestoreConstants.members}/$userId',
    );
    final orgRef = _firestore.doc('${FirestoreConstants.organizations}/$orgId');

    batch.set(memberRef, newMember.toMap());
    batch.update(orgRef, {'memberCount': FieldValue.increment(1)});
    await batch.commit();
  }

  @override
  Future<void> removeMember(String orgId, String userId) async {
    final batch = _firestore.batch();
    final memberRef = _firestore.doc(
      '${FirestoreConstants.organizations}/$orgId/${FirestoreConstants.members}/$userId',
    );
    final orgRef = _firestore.doc('${FirestoreConstants.organizations}/$orgId');

    batch.delete(memberRef);
    batch.update(orgRef, {'memberCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  @override
  Future<void> updateMemberRole(
    String orgId,
    String userId,
    UserRole role,
  ) async {
    await _firestore.updateDoc(
      '${FirestoreConstants.organizations}/$orgId/${FirestoreConstants.members}/$userId',
      {'role': role.name},
    );
  }
}
