class OwnGroup{
  int id;
  String name;
  bool actual;
  bool isCreator;


  OwnGroup({required this.id, required this.name, required this.actual, required this.isCreator});

  factory OwnGroup.fromJson(Map<String, dynamic> json) {
    return OwnGroup(
      id: json['id'],
      name: json['name'],
      actual: json['actual'],
      isCreator: json['creator'],
    );
  }
}