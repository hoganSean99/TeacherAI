import 'package:isar/isar.dart';

part 'exam.g.dart';

@Collection()
class Exam {
  Id id = Isar.autoIncrement;

  late String name;
  late int classId;
  late String className;
  late DateTime date;
  String? filePath;
  late String userId;

  Exam();

  Exam.create({
    required this.name,
    required this.classId,
    required this.className,
    required this.date,
    required this.userId,
    this.filePath,
  });
} 