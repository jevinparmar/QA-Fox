enum AppStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error;

  bool get isLoading => this == AppStatus.loading;
  bool get isAuthenticated => this == AppStatus.authenticated;
}

enum ConnectionStatus {
  none('Connect'),
  pendingSent('Pending'),
  pendingReceived('Respond'),
  connected('Message'),
  blocked('Blocked');

  final String label;
  const ConnectionStatus(this.label);

  static ConnectionStatus fromString(String? value) {
    return ConnectionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => ConnectionStatus.none,
    );
  }
}

enum MessageType {
  text,
  image,
  video,
  file,
  bugReport,
  system;

  static MessageType fromString(String? value) {
    return MessageType.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => MessageType.text,
    );
  }
}

enum ChatType {
  individual,
  projectGroup;

  static ChatType fromString(String? value) {
    return ChatType.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => ChatType.individual,
    );
  }
}
