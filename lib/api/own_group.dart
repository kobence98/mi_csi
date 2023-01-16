class OwnGroup{
  int id;
  String name;
  bool actual;

  OwnGroup({required this.id, required this.name, required this.actual});

  factory OwnGroup.fromJson(Map<String, dynamic> json) {
    return OwnGroup(
      id: json['id'],
      name: json['name'],
      actual: json['actual'],
    );
  }
}