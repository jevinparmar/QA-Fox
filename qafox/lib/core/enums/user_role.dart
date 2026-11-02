enum UserRole {
  owner('Owner'),
  admin('Admin'),
  tester('Tester'),
  developer('Developer');

  final String label;
  const UserRole(this.label);

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => UserRole.tester,
    );
  }

  bool get isOwner => this == UserRole.owner;
  bool get isAdmin => this == UserRole.admin || isOwner;
  bool get canManageTeam => isAdmin;
  bool get canCreateProject => isAdmin;
  bool get canAssignBugs => isAdmin || this == UserRole.developer;
}
