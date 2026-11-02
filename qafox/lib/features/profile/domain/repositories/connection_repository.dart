import '../../../../shared/models/connection_model.dart';
import '../../../../shared/models/user_model.dart';

abstract class ConnectionRepository {
  Future<List<UserModel>> searchUsers(String query, String currentUserId);
  Stream<List<ConnectionRequestModel>> streamReceivedRequests(String userId);
  Stream<List<ConnectionRequestModel>> streamSentRequests(String userId);
  Stream<List<UserModel>> streamConnectedUsers(String userId);
  Future<List<UserModel>> getAllUsers(String currentUserId);
  Future<List<UserModel>> getUsersByIds(List<String> userIds);
  Future<void> sendConnectionRequest({
    required UserModel sender,
    required UserModel receiver,
  });
  Future<void> acceptConnectionRequest(ConnectionRequestModel request);
  Future<void> declineConnectionRequest(String requestId);
  Future<void> cancelSentRequest(String requestId);
  Future<void> removeConnection(String currentUserId, String targetUserId);
  Future<String> getOrCreateIndividualChat(
    String userAId,
    String userBId,
    String userAName,
    String userBName,
  );
}
