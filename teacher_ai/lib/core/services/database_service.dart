import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:teacher_ai/features/auth/domain/models/user.dart';
import 'package:teacher_ai/features/core/domain/models/subject.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';
import 'package:teacher_ai/features/core/domain/models/attendance.dart';
import 'package:teacher_ai/features/exams/domain/models/exam.dart';
import 'package:teacher_ai/features/exams/domain/models/exam_result.dart';
import 'package:teacher_ai/features/home/domain/models/custom_event.dart';

class DatabaseService {
  static late Isar _isar;
  static bool _initialized = false;

  static Isar get instance => _isar;
  
  // Collection accessors
  static IsarCollection<User> get users => _isar.collection<User>();
  static IsarCollection<Subject> get subjects => _isar.collection<Subject>();
  static IsarCollection<Student> get students => _isar.collection<Student>();
  static IsarCollection<Attendance> get attendance => _isar.collection<Attendance>();
  static IsarCollection<Exam> get exams => _isar.collection<Exam>();
  static IsarCollection<ExamResult> get examResults => _isar.collection<ExamResult>();

  static Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        UserSchema,
        SubjectSchema,
        StudentSchema,
        AttendanceSchema,
        ExamSchema,
        ExamResultSchema,
        CustomEventSchema,
      ],
      directory: dir.path,
    );
    _initialized = true;
  }

  static Future<void> clearUserData() async {
    await _isar.writeTxn(() async {
      await _isar.subjects.clear();
      await _isar.students.clear();
      await DatabaseService.attendance.clear();
      await _isar.exams.clear();
      await _isar.examResults.clear();
      await _isar.customEvents.clear();
      // Do NOT clear users or other metadata collections
    });
  }
} 