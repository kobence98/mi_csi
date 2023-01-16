import 'dart:convert';

import 'package:mi_csi/api/program_idea.dart';

class ChosenGroupData{
  String groupName;
  ProgramIdea? actualProgramIdea;

  ChosenGroupData({required this.groupName, this.actualProgramIdea});

  factory ChosenGroupData.fromJson(Map<String, dynamic> jsonInput) {
    return ChosenGroupData(
      groupName: jsonInput['groupName'],
      actualProgramIdea: jsonInput['actualProgramIdea'] == null ? null : ProgramIdea.fromJson(jsonInput['actualProgramIdea']),
    );
  }
}