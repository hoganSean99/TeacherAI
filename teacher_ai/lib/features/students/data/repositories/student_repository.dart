import 'package:isar/isar.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';

class StudentRepository {
  final Isar _isar;

  StudentRepository(this._isar);

  Future<Student?> getStudentByEmail(String email) async {
    return await _isar.students.where().filter().emailEqualTo(email).findFirst();
  }

  Future<List<Student>> getAllStudents() async {
    return await _isar.students.where().findAll();
  }

  Future<List<Student>> getStudentsByUserId(String userId) async {
    return await _isar.students.where().filter().userIdEqualTo(userId).findAll();
  }

  Future<Id> saveStudent(Student student) async {
    return await _isar.writeTxn(() async {
      return await _isar.students.put(student);
    });
  }

  Future<bool> deleteStudent(Id id) async {
    return await _isar.writeTxn(() async {
      return await _isar.students.delete(id);
    });
  }

  Future<Id> updateStudent(Student student) async {
    return await _isar.writeTxn(() async {
      return await _isar.students.put(student);
    });
  }

  Future<void> deleteAllStudentsByUserId(String userId) async {
    await _isar.writeTxn(() async {
      await _isar.students.where().filter().userIdEqualTo(userId).deleteAll();
    });
  }

  Future<Student?> getStudentById(int id) async {
    return await _isar.students.filter().idEqualTo(id).findFirst();
  }
} 