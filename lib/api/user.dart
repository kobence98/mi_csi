class User{
  int userId;
  String email;
  String name;
  List<dynamic> roles;
  bool active;
  int? actualGroupId;
  String? actualGroupName;
  bool hasNoGroups;

  User({required this.userId, required this.email, required this.name, required this.roles, required this.active, required this.hasNoGroups, this.actualGroupId, this.actualGroupName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      roles: json['roles'],
      email: json['email'],
      name: json['name'],
      active: json['active'],
      actualGroupId: json['actualGroupId'],
      hasNoGroups: json['hasNoGroups'],
      actualGroupName: json['actualGroupName'],
    );
  }
}
