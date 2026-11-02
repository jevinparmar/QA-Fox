import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/core/enums/app_status.dart';
import 'package:qafox/shared/models/connection_model.dart';

void main() {
  group('ConnectionRequestModel Tests', () {
    test('serialization and status mapping', () {
      final now = DateTime.now();
      final connection = ConnectionRequestModel(
        id: 'conn_1',
        senderId: 'user_a',
        senderName: 'Alice',
        receiverId: 'user_b',
        receiverName: 'Bob',
        status: ConnectionStatus.pendingSent,
        createdAt: now,
        updatedAt: now,
      );

      final map = connection.toMap();
      expect(map['id'], 'conn_1');
      expect(map['senderId'], 'user_a');
      expect(map['receiverId'], 'user_b');
      expect(map['status'], 'pendingSent');

      final deserialized = ConnectionRequestModel.fromMap(map, 'conn_1');
      expect(deserialized.id, 'conn_1');
      expect(deserialized.status, ConnectionStatus.pendingSent);
      expect(deserialized.status.label, 'Pending');
    });

    test('ConnectionStatus transitions and states check', () {
      expect(ConnectionStatus.fromString('none'), ConnectionStatus.none);
      expect(
        ConnectionStatus.fromString('pendingSent'),
        ConnectionStatus.pendingSent,
      );
      expect(
        ConnectionStatus.fromString('pendingReceived'),
        ConnectionStatus.pendingReceived,
      );
      expect(
        ConnectionStatus.fromString('connected'),
        ConnectionStatus.connected,
      );
      expect(ConnectionStatus.fromString('blocked'), ConnectionStatus.blocked);
      expect(
        ConnectionStatus.fromString('invalid_status'),
        ConnectionStatus.none,
      );

      expect(ConnectionStatus.none.label, 'Connect');
      expect(ConnectionStatus.pendingSent.label, 'Pending');
      expect(ConnectionStatus.pendingReceived.label, 'Respond');
      expect(ConnectionStatus.connected.label, 'Message');
      expect(ConnectionStatus.blocked.label, 'Blocked');
    });
  });
}
