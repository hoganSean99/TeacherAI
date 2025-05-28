import 'package:isar/isar.dart';

part 'custom_event.g.dart';

@Collection()
class CustomEvent {
  Id id = Isar.autoIncrement;

  late String title;
  late DateTime date;
  late String type;
  late int color; // Store as ARGB int
  String? className;
  late String userId;

  CustomEvent();

  CustomEvent.create({
    required this.title,
    required this.date,
    required this.type,
    required this.color,
    this.className,
    required this.userId,
  });
} 