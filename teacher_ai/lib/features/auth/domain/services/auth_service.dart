import 'package:isar/isar.dart';
import 'package:teacher_ai/features/auth/domain/models/user.dart';
import 'package:teacher_ai/features/students/data/repositories/student_repository.dart';
import 'package:teacher_ai/features/subjects/data/subject_repository.dart';

class AuthService {
  final Isar _isar;
  final StudentRepository _studentRepository;
  final SubjectRepository _subjectRepository;

  AuthService(this._isar)
      : _studentRepository = StudentRepository(_isar),
        _subjectRepository = SubjectRepository(_isar);

  Future<User?> login(String email, String password) async {
    try {
      final user = await _isar.users
          .filter()
          .emailEqualTo(email)
          .findFirst();

      if (user != null && user.password == password) {
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> register(User user) async {
    try {
      // Check if user already exists
      final existingUser = await _isar.users
          .filter()
          .emailEqualTo(user.email)
          .findFirst();

      if (existingUser != null) {
        return false;
      }

      // Save new user
      await _isar.writeTxn(() async {
        await _isar.users.put(user);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout(String userId) async {
    // Clear all data associated with the user
    await _studentRepository.deleteAllStudentsByUserId(userId);
    await _subjectRepository.deleteAllSubjectsByUserId(userId);
  }
} 