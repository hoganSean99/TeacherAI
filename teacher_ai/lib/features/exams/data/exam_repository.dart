import 'package:isar/isar.dart';
import '../domain/models/exam.dart';
import '../domain/models/exam_result.dart';

class ExamRepository {
  final Isar isar;
  ExamRepository(this.isar);

  Future<void> addExam(Exam exam) async {
    await isar.writeTxn(() async {
      await isar.exams.put(exam);
    });
  }

  Future<void> updateExam(Exam exam) async {
    await isar.writeTxn(() async {
      await isar.exams.put(exam);
    });
  }

  Future<void> deleteExam(int id) async {
    await isar.writeTxn(() async {
      await isar.exams.delete(id);
    });
  }

  Future<List<Exam>> getExamsByUserId(String userId) async {
    return await isar.exams.filter().userIdEqualTo(userId).findAll();
  }

  // ExamResult CRUD
  Future<void> addExamResult(ExamResult result) async {
    await isar.writeTxn(() async {
      await isar.examResults.put(result);
    });
  }

  Future<void> updateExamResult(ExamResult result) async {
    await isar.writeTxn(() async {
      await isar.examResults.put(result);
    });
  }

  Future<List<ExamResult>> getResultsForExam(int examId) async {
    return await isar.examResults.filter().examIdEqualTo(examId).findAll();
  }

  Future<ExamResult?> getResultForStudent(int examId, int studentId) async {
    return await isar.examResults.filter().examIdEqualTo(examId).studentIdEqualTo(studentId).findFirst();
  }

  Future<void> saveAllResults(List<ExamResult> results) async {
    await isar.writeTxn(() async {
      await isar.examResults.putAll(results);
    });
  }

  Future<List<ExamResult>> getResultsForStudent(int studentId) async {
    return await isar.examResults.filter().studentIdEqualTo(studentId).findAll();
  }

  Future<Exam?> getExamById(int id) async {
    return await isar.exams.filter().idEqualTo(id).findFirst();
  }
} 