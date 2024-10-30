import 'package:flutter/material.dart';

class Reminder {
  final TimeOfDay time;
  final List<int> days;

  Reminder({required this.time, required this.days});

  Map<String, dynamic> toMap() {
    return {
      'time': '${time.hour}:${time.minute}',
      'days': days,
    };
  }

  //Reminder a partire da una mappa
  factory Reminder.fromMap(Map<String, dynamic> map) {
    final timeParts = (map['time'] as String).split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return Reminder(
      time: TimeOfDay(hour: hour, minute: minute),
      days: List<int>.from(map['days']),
    );
  }
}
