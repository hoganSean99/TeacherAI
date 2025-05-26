import 'package:isar/isar.dart';
import 'package:teacher_ai/features/exams/domain/models/exam.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';
import 'package:teacher_ai/features/core/domain/models/attendance.dart';
import 'dart:math';

class AIService {
  final Isar _isar;
  String? lastExtractedStudentName;
  List<Student>? _allStudentsCache;

  AIService(this._isar);

  Future<void> _ensureStudentsLoaded() async {
    _allStudentsCache ??= await _isar.students.where().findAll();
  }

  Future<String> processQueryWithContext(String query, String? lastStudentName) async {
    await _ensureStudentsLoaded();
    final studentName = _extractStudentName(query);
    Student? student;
    String? matchedName;
    if (studentName != null) {
      student = _findBestStudentMatch(studentName);
      matchedName = student?.fullName;
    } else if (lastStudentName != null) {
      student = _findBestStudentMatch(lastStudentName);
      matchedName = student?.fullName;
    }
    lastExtractedStudentName = matchedName;
    if (student != null) {
      return await _processStudentQuery(query, student);
    } else if (studentName != null) {
      // Suggest possible matches
      final suggestions = _suggestStudentNames(studentName);
      if (suggestions.isNotEmpty) {
        return "I couldn't find a student named $studentName. Did you mean: ${suggestions.join(", ")}?";
      }
      return "I couldn't find a student named $studentName.";
    }
    return "I'm not sure how to help with that query. Please try asking about a specific student or their grades or attendance.";
  }

  // Fuzzy match student name
  Student? _findBestStudentMatch(String input) {
    if (_allStudentsCache == null) return null;
    final normalizedInput = input.toLowerCase().replaceAll(RegExp(r"[^a-z0-9 ]"), "").trim();
    Student? bestMatch;
    int bestScore = 0;
    for (final student in _allStudentsCache!) {
      final fullName = (student.firstName + ' ' + student.lastName).toLowerCase();
      final score = _stringSimilarity(normalizedInput, fullName);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = student;
      }
    }
    // Only return if the match is reasonably close
    if (bestScore > 60) return bestMatch;
    return null;
  }

  // Suggest similar student names
  List<String> _suggestStudentNames(String input) {
    if (_allStudentsCache == null) return [];
    final normalizedInput = input.toLowerCase().replaceAll(RegExp(r"[^a-z0-9 ]"), "").trim();
    final scored = _allStudentsCache!
        .map((s) => {
              'name': s.fullName,
              'score': _stringSimilarity(normalizedInput, (s.firstName + ' ' + s.lastName).toLowerCase()),
            })
        .where((m) => (m['score']! as int) > 30)
        .toList();
    scored.sort((a, b) => (b['score']! as int).compareTo(a['score']! as int));
    return scored.take(3).map((m) => m['name'] as String).toList();
  }

  // Simple string similarity (Levenshtein or token overlap)
  int _stringSimilarity(String a, String b) {
    if (a == b) return 100;
    if (a.isEmpty || b.isEmpty) return 0;
    if (b.contains(a) || a.contains(b)) return 80;
    // Token overlap
    final aTokens = a.split(' ');
    final bTokens = b.split(' ');
    final overlap = aTokens.where((t) => bTokens.contains(t)).length;
    return (overlap / max(aTokens.length, bTokens.length) * 100).round();
  }

  // Extract student name using possessive and robust patterns
  String? _extractStudentName(String query) {
    // Try <Name> pattern first
    final bracketPattern = RegExp(r'<([^>]+)>');
    final bracketMatch = bracketPattern.firstMatch(query);
    if (bracketMatch != null) {
      return bracketMatch.group(1)?.trim();
    }
    // Possessive (e.g. Isabella Hogan's grades)
    final possessivePattern = RegExp(r"([A-Z][a-z]+ [A-Z][a-z]+)'s", caseSensitive: false);
    final possessiveMatch = possessivePattern.firstMatch(query);
    if (possessiveMatch != null) {
      return possessiveMatch.group(1)?.trim();
    }
    // After keywords
    final keywordPattern = RegExp(
      r'(?:is|for|about|of|like|show|tell|give|what is|how is|how was|how many|average|attendance|summary|grades|grade|absences|absence)[^A-Za-z0-9]+([A-Z][a-z]+ [A-Z][a-z]+)',
      caseSensitive: false,
    );
    final keywordMatch = keywordPattern.firstMatch(query);
    if (keywordMatch != null) {
      return keywordMatch.group(1)?.trim();
    }
    // Fallback: any two consecutive capitalized words (not at start)
    final namePattern = RegExp(r'([A-Z][a-z]+ [A-Z][a-z]+)');
    final nameMatches = namePattern.allMatches(query).toList();
    if (nameMatches.isNotEmpty) {
      if (nameMatches.length > 1 && nameMatches[0].start < 3) {
        return nameMatches[1].group(1)?.trim();
      }
      return nameMatches[0].group(1)?.trim();
    }
    return null;
  }

  Future<String> _processStudentQuery(String query, Student student) async {
    // Recognize intent
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.contains('attendance') || lowerQuery.contains('absenc')) {
      return await _getAttendanceSummary(student);
    } else if (lowerQuery.contains('summary')) {
      final exams = await _isar.exams.filter().classIdEqualTo(student.id).findAll();
      return _generateStudentSummary(student, exams);
    } else if (lowerQuery.contains('average') || lowerQuery.contains('grade')) {
      final exams = await _isar.exams.filter().classIdEqualTo(student.id).findAll();
      return _calculateStudentAverage(student, exams);
    }
    return "I can provide a summary, average grade, or attendance for ${student.fullName}. Please specify what you'd like to know.";
  }

  Future<String> _getAttendanceSummary(Student student) async {
    final attendanceRecords = await _isar.collection<Attendance>()
        .filter()
        .studentIdEqualTo(student.id)
        .findAll();
    if (attendanceRecords.isEmpty) {
      return "No attendance records found for ${student.fullName}.";
    }
    final total = attendanceRecords.length;
    final present = attendanceRecords.where((a) => a.status == 'present').length;
    final absent = attendanceRecords.where((a) => a.status == 'absent').length;
    final percent = (present / total) * 100;
    return '''
Attendance for ${student.fullName}:
- Present: $present days
- Absent: $absent days
- Attendance rate: ${percent.toStringAsFixed(1)}%
''';
  }

  String _generateStudentSummary(Student student, List<Exam> exams) {
    final examCount = exams.length;
    final averageGrade = _calculateAverageGrade(exams);

    return '''
Summary for ${student.fullName}:
- Email: ${student.email}
- Subjects: ${student.subjects ?? 'Not specified'}
- Number of exams taken: $examCount
- Average grade: ${averageGrade.toStringAsFixed(2)}
''';
  }

  String _calculateStudentAverage(Student student, List<Exam> exams) {
    final average = _calculateAverageGrade(exams);
    return "${student.fullName}'s average grade is ${average.toStringAsFixed(2)}";
  }

  double _calculateAverageGrade(List<Exam> exams) {
    if (exams.isEmpty) return 0.0;
    // TODO: Implement actual grade calculation when grade field is added to Exam model
    return 0.0;
  }
} 