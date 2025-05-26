import 'package:isar/isar.dart';

part 'exam_result.g.dart';

@Collection()
class ExamResult {
  Id id = Isar.autoIncrement;

  late int examId;
  late int studentId;
  double? grade;
  String? comment;

  ExamResult();

  ExamResult.create({
    required this.examId,
    required this.studentId,
    this.grade,
    this.comment,
  });
} 