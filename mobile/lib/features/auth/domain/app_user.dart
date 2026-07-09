enum RoleGroup { citizen, technician, manager }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.identificationNumber,
    required this.position,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final String identificationNumber;
  final String position;
  final String role;

  RoleGroup get roleGroup {
    switch (role) {
      case 'Tecnico':
        return RoleGroup.technician;
      case 'Administrador':
      case 'Supervisor':
        return RoleGroup.manager;
      default:
        return RoleGroup.citizen;
    }
  }

  bool get isManager => roleGroup == RoleGroup.manager;
  bool get isTechnician => roleGroup == RoleGroup.technician;
  bool get isCitizen => roleGroup == RoleGroup.citizen;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    identificationNumber: json['identificationNumber'] as String? ?? '',
    position: json['position'] as String? ?? '',
    role: json['role'] as String? ?? '',
  );
}
