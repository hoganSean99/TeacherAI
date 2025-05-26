import 'package:isar/isar.dart';

part 'attendance.g.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
  excused
}

@Collection()
class Attendance {
  Id id = Isar.autoIncrement;

  @Index()
  int studentId;
  
  @Index()
  int subjectId;

  @enumerated
  AttendanceStatus status;
  
  String? note;
  DateTime date;
  DateTime createdAt;
  DateTime updatedAt;

  Attendance({
    required this.studentId,
    required this.subjectId,
    required this.status,
    required this.date,
    this.note,
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();
} 