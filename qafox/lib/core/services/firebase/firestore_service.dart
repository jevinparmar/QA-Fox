import 'package:cloud_firestore/cloud_firestore.dart';

import '../../errors/app_exception.dart';
import '../../errors/error_handler.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService([FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  FirebaseFirestore get instance => _firestore;

  DocumentReference<Map<String, dynamic>> doc(String path) =>
      _firestore.doc(path);
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _firestore.collection(path);

  Future<void> setDoc(
    String path,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      await _firestore.doc(path).set(data, SetOptions(merge: merge));
    } catch (e) {
      throw FirestoreException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<void> updateDoc(String path, Map<String, dynamic> data) async {
    try {
      await _firestore.doc(path).update(data);
    } catch (e) {
      throw FirestoreException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String path) async {
    try {
      return await _firestore.doc(path).get();
    } catch (e) {
      throw FirestoreException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<void> deleteDoc(String path) async {
    try {
      await _firestore.doc(path).delete();
    } catch (e) {
      throw FirestoreException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    String path, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)?
    queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(path);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return await query.get();
    } catch (e) {
      throw FirestoreException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(String path) {
    return _firestore.doc(path).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String path, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)?
    queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  WriteBatch batch() => _firestore.batch();

  Future<T> runTransaction<T>(TransactionHandler<T> handler) {
    return _firestore.runTransaction(handler);
  }
}
