import 'package:flutter/material.dart';
import 'package:teacher_ai/features/core/domain/models/subject.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';
import 'package:teacher_ai/features/subjects/data/subject_repository.dart';
import 'package:teacher_ai/features/students/data/repositories/student_repository.dart';
import 'package:teacher_ai/features/exams/data/exam_repository.dart';
import 'package:teacher_ai/features/exams/domain/models/exam.dart';
import 'package:teacher_ai/features/exams/domain/models/exam_result.dart';
import 'package:isar/isar.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'package:teacher_ai/features/core/domain/models/attendance.dart';
import 'package:teacher_ai/features/students/presentation/pages/student_summary_page.dart';

class ClassDashboardPage extends ConsumerStatefulWidget {
  final ClassYear year;
  const ClassDashboardPage({super.key, required this.year});
  @override
  ConsumerState<ClassDashboardPage> createState() => _ClassDashboardPageState();
}

class AttendanceSummary {
  final int present;
  final int absent;
  final int late;
  final int excused;
  AttendanceSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });
}

class _ClassDashboardPageState extends ConsumerState<ClassDashboardPage> {
  late final SubjectRepository subjectRepository;
  late final StudentRepository studentRepository;
  late final ExamRepository examRepository;
  List<Subject> subjects = [];
  List<Student> students = [];
  bool isLoading = true;
  AttendanceSummary? attendanceSummary;
  double gradeAvg = 0.0;
  List<Exam> yearExams = [];
  String bestStudent = '-';
  String worstStudent = '-';

  @override
  void initState() {
    super.initState();
    final isar = DatabaseService.instance;
    subjectRepository = SubjectRepository(isar);
    studentRepository = StudentRepository(isar);
    examRepository = ExamRepository(isar);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final allSubjects = await subjectRepository.getAllSubjects();
      final allStudents = await studentRepository.getAllStudents();
      final yearSubjects = allSubjects.where((s) => s.year == widget.year).toList();
      final yearStudentIds = yearSubjects.expand((subject) => subject.studentIds).toSet();
      final yearStudents = allStudents.where((student) => yearStudentIds.contains(student.id)).toList();
      
      // Load exam data
      final allExams = await examRepository.getExamsByUserId(currentUser.uuid);
      yearExams = allExams.where((e) => yearSubjects.any((s) => s.id == e.classId)).toList();
      
      // Calculate average grade
      double totalGrade = 0;
      int gradeCount = 0;
      for (final exam in yearExams) {
        final results = await examRepository.getResultsForExam(exam.id);
        for (final result in results) {
          if (result.grade != null) {
            totalGrade += result.grade!;
            gradeCount++;
          }
        }
      }
      final calculatedGradeAvg = gradeCount > 0 ? totalGrade / gradeCount : 0.0;

      // Calculate best/worst student by average grade
      Map<int, List<double>> studentGrades = {};
      for (final exam in yearExams) {
        final results = await examRepository.getResultsForExam(exam.id);
        for (final result in results) {
          if (result.grade != null) {
            studentGrades.putIfAbsent(result.studentId, () => []).add(result.grade!);
          }
        }
      }
      Map<int, double> studentAverages = {
        for (var entry in studentGrades.entries)
          entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length
      };
      if (studentAverages.isNotEmpty) {
        final bestId = studentAverages.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        final worstId = studentAverages.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
        bestStudent = students.firstWhere(
          (s) => s.id == bestId,
          orElse: () => Student(firstName: '-', lastName: '', email: '', userId: ''),
        ).fullName;
        worstStudent = students.firstWhere(
          (s) => s.id == worstId,
          orElse: () => Student(firstName: '-', lastName: '', email: '', userId: ''),
        ).fullName;
      } else {
        bestStudent = '-';
        worstStudent = '-';
      }

      // Attendance summary logic
      final isar = DatabaseService.instance;
      final subjectIds = yearSubjects.map((s) => s.id).toList();
      final records = await isar.attendances.filter().anyOf(subjectIds, (q, id) => q.subjectIdEqualTo(id)).findAll();
      final summary = AttendanceSummary(
        present: records.where((a) => a.status == AttendanceStatus.present).length,
        absent: records.where((a) => a.status == AttendanceStatus.absent).length,
        late: records.where((a) => a.status == AttendanceStatus.late).length,
        excused: records.where((a) => a.status == AttendanceStatus.excused).length,
      );
      setState(() {
        subjects = yearSubjects;
        students = yearStudents;
        attendanceSummary = summary;
        gradeAvg = calculatedGradeAvg;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  String _getYearLabel(ClassYear year) {
    switch (year) {
      case ClassYear.firstYear:
        return '1st Year';
      case ClassYear.secondYear:
        return '2nd Year';
      case ClassYear.thirdYear:
        return '3rd Year';
      case ClassYear.transitionYear:
        return 'Transition Year';
      case ClassYear.fifthYear:
        return '5th Year';
      case ClassYear.sixthYear:
        return '6th Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final teacherName = currentUser?.displayName ?? 'Teacher';
    final className = subjects.isNotEmpty ? subjects.first.name : 'Class';
    final yearLabel = _getYearLabel(widget.year);
    final assignmentCount = 3;
    final examCount = yearExams.length;
    final now = DateTime.now();
    final nextExam = (yearExams.isNotEmpty)
        ? (yearExams.where((e) => e.date.isAfter(now)).toList()..sort((a, b) => a.date.compareTo(b.date))).firstOrNull
        : null;
    final upcomingDate = nextExam != null ? nextExam.date.toIso8601String().split('T').first : 'None';
    final totalAttendance = (attendanceSummary?.present ?? 0) + (attendanceSummary?.absent ?? 0) + (attendanceSummary?.late ?? 0) + (attendanceSummary?.excused ?? 0);
    final attendanceAvg = totalAttendance > 0 ? ((attendanceSummary?.present ?? 0) / totalAttendance * 100) : 0.0;

    final accentColor = const Color(0xFF8E24AA);
    return Scaffold(
      backgroundColor: null,
      body: Stack(
        children: [
          // Apple-style gradient and bokeh background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F8FA), Color(0xFFE3E6F0), Color(0xFFF3EFFF)],
              ),
            ),
            child: Stack(
              children: [
                // Bokeh circles
                Positioned(
                  top: 60,
                  left: 30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 60, color: Colors.white.withOpacity(0.18))],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  right: 40,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 50, color: Colors.white.withOpacity(0.13))],
                    ),
                  ),
                ),
                Positioned(
                  top: 200,
                  right: 100,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 30, color: Colors.white.withOpacity(0.10))],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          ListView(
            padding: EdgeInsets.zero,
            children: [
              // Apple-style glassmorphic header card
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.60),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 36,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.13), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: accentColor.withOpacity(0.13),
                              child: Icon(Icons.class_, color: accentColor, size: 38),
                            ),
                            const SizedBox(width: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$className - $yearLabel',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                        letterSpacing: -1.2,
                                        color: Colors.black.withOpacity(0.85),
                                        fontFamily: 'SF Pro Display',
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Class Overview',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: accentColor.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'SF Pro Text',
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    _AppleStatTile(
                      icon: Icons.bar_chart_rounded,
                      value: '${gradeAvg.toStringAsFixed(1)}%',
                      label: 'Grade Avg',
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 16),
                    _AppleStatTile(
                      icon: Icons.show_chart_rounded,
                      value: '${attendanceAvg.toStringAsFixed(1)}%',
                      label: 'Attendance Avg',
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
              // Key Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.60),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _InfoTile(label: 'Teacher', value: teacherName, icon: Icons.person),
                            _InfoTile(label: 'Students', value: students.length.toString(), icon: Icons.people),
                            _InfoTile(label: 'Exams', value: examCount.toString(), icon: Icons.description),
                            _InfoTile(label: 'Upcoming', value: upcomingDate, icon: Icons.event),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Best/Worst Students
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: const Color(0xFF6A82FB).withOpacity(0.10),
                            child: ListTile(
                              leading: const Icon(Icons.emoji_events, color: Color(0xFF6A82FB)),
                              title: const Text('Best Student'),
                              subtitle: Text(bestStudent),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: const Color(0xFFFC5C7D).withOpacity(0.10),
                            child: ListTile(
                              leading: const Icon(Icons.sentiment_dissatisfied, color: Color(0xFFFC5C7D)),
                              title: const Text('Needs Improvement'),
                              subtitle: Text(worstStudent),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Students List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text('Students', style: Theme.of(context).textTheme.titleLarge),
              ),
              ...students.map((student) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.70),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: accentColor.withOpacity(0.10),
                              child: Text(
                                student.fullName.isNotEmpty ? student.fullName[0] : '?',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(student.email),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StudentSummaryPage(studentId: student.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.school,
                    label: 'Subjects',
                    value: subjects.length.toString(),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    label: 'Students',
                    value: students.length.toString(),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.description,
                    label: 'Exams',
                    value: '0',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
        ),
      ],
    );
  }

  Widget _buildSubjectsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subjects',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...subjects.map((subject) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to subject details
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(int.parse(subject.color ?? '0xFF2196F3')).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school,
                            color: Color(int.parse(subject.color ?? '0xFF2196F3')),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (subject.description?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subject.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildStudentsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Students',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...students.map((student) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to student details
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            student.fullName.isNotEmpty ? student.fullName[0] : '?',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildAttendanceChip(IconData icon, int count, Color color) {
    return Chip(
      label: Text(
        '$count',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.2)),
      avatar: Icon(icon, color: color),
    );
  }
}

class _AppleStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _AppleStatTile({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: color.withOpacity(0.13), width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: color)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 13, color: color.withOpacity(0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _appleChip(IconData icon, int count, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.13),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.18)),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text('$count', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoTile({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
      ],
    );
  }
} 