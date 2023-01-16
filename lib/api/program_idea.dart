
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../enums/program_type.dart';

class ProgramIdea{
  int id;
  String name;
  String? place;
  LatLng? coordinates;
  ProgramType programType;
  int usedTimes;
  int userId;
  String userName;
  int? pictureId;

  ProgramIdea({required this.id, required this.name, this.place, this.programType = ProgramType.OTHER, this.usedTimes = 0, required this.userId, required this.userName, this.coordinates, this.pictureId});

  factory ProgramIdea.fromJson(Map<String, dynamic> json) {
    return ProgramIdea(
      id: json['id'],
      name: json['name'],
      userName: json['userName'],
      place: json['place'],
      programType: ProgramType.values.firstWhere((programType) => programType.toString() == 'ProgramType.' + json['programType']),
      usedTimes: json['usedTimes'],
      userId: json['userId'],
      pictureId: json['pictureId'],
      coordinates: json['latitude'] == null ? null : LatLng(double.parse(json['latitude']), double.parse(json['longitude'])),
    );
  }
}