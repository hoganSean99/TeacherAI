import 'package:isar/isar.dart';
import 'package:teacher_ai/features/core/domain/models/subject.dart';

class SubjectRepository {
  final Isar _isar;

  SubjectRepository(this._isar);

  Future<List<Subject>> getAllSubjects() async {
    return await _isar.subjects.where().findAll();
  }

  Future<List<Subject>> getSubjectsByUserId(String userId) async {
    return await _isar.subjects.where().filter().userIdEqualTo(userId).findAll();
  }

  Future<Subject?> getSubjectById(Id id) async {
    return await _isar.subjects.get(id);
  }

  Future<Id> addSubject(Subject subject) async {
    return await _isar.writeTxn(() async {
      return await _isar.subjects.put(subject);
    });
  }

  Future<Id> updateSubject(Subject subject) async {
    return await _isar.writeTxn(() async {
      return await _isar.subjects.put(subject);
    });
  }

  Future<bool> deleteSubject(Id id) async {
    return await _isar.writeTxn(() async {
      return await _isar.subjects.delete(id);
    });
  }

  Future<void> assignStudentsToSubject(Id subjectId, List<int> studentIds) async {
    await _isar.writeTxn(() async {
      final subject = await _isar.subjects.get(subjectId);
      if (subject != null) {
        subject.studentIds = studentIds;
        await _isar.subjects.put(subject);
      }
    });
  }

  Future<void> deleteAllSubjectsByUserId(String userId) async {
    await _isar.writeTxn(() async {
      await _isar.subjects.where().filter().userIdEqualTo(userId).deleteAll();
    });
  }
} 