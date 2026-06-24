import 'package:flutter/material.dart';

class LinkedListNodeModel {
  const LinkedListNodeModel({
    required this.id,
    required this.label,
    required this.position,
  });

  final int id;
  final String label;
  final Offset position;

  LinkedListNodeModel copyWith({String? label, Offset? position}) {
    return LinkedListNodeModel(
      id: id,
      label: label ?? this.label,
      position: position ?? this.position,
    );
  }
}
