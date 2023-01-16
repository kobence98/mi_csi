import 'package:flutter/material.dart';

enum ProgramType{
  FUN,
  OUTDOORS,
  ART,
  OTHER,
}

extension ParseToString on ProgramType {
  String get hunName {
    switch (this) {
      case ProgramType.FUN:
        return 'szórakozás';
      case ProgramType.OUTDOORS:
        return 'szabadban';
      case ProgramType.ART:
        return 'művészet';
      case ProgramType.OTHER:
      default:
        return 'egyéb';
    }
  }
}

extension ParseToName on ProgramType {
  String get name {
    switch (this) {
      case ProgramType.FUN:
        return 'FUN';
      case ProgramType.OUTDOORS:
        return 'OUTDOORS';
      case ProgramType.ART:
        return 'ART';
      case ProgramType.OTHER:
      default:
        return 'OTHER';
    }
  }
}

extension ParseToIcon on ProgramType {
  IconData get icon {
    switch (this) {
      case ProgramType.FUN:
        return Icons.add_reaction;
      case ProgramType.OUTDOORS:
        return Icons.logout;
      case ProgramType.ART:
        return Icons.brush;
      case ProgramType.OTHER:
      default:
      return Icons.question_mark;
    }
  }
}