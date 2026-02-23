import 'package:flutter/material.dart';

/// GlobalKeys estáticos para el tour de la pantalla de ejercicios.
class ExercisesTourKeys {
  static final searchBar = GlobalKey();
  static final muscleFilter = GlobalKey();
  static final exerciseCard = GlobalKey();
  static final fab = GlobalKey();
  static final routinesTab = GlobalKey();
  static final historyTab = GlobalKey();

  static List<GlobalKey> get all => [
        searchBar,
        muscleFilter,
        exerciseCard,
        fab,
        routinesTab,
        historyTab,
      ];
}

/// GlobalKeys estáticos para el tour de la pantalla de detalle de ejercicio.
class DetailTourKeys {
  static final timer = GlobalKey();
  static final addToRoutine = GlobalKey();
  static final details = GlobalKey();
  static final modeSwitch = GlobalKey();
  static final saveButton = GlobalKey();

  static List<GlobalKey> get all => [
        timer,
        addToRoutine,
        details,
        modeSwitch,
        saveButton,
      ];
}
