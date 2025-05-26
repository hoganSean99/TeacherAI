import 'package:flutter/material.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';
import 'package:teacher_ai/features/core/domain/models/attendance.dart';
import 'package:teacher_ai/features/core/domain/models/subject.dart';
import 'package:teacher_ai/features/students/data/repositories/student_repository.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:teacher_ai/features/exams/domain/models/exam_result.dart';
import 'package:teacher_ai/features/exams/data/exam_repository.dart';
import 'package:teacher_ai/features/exams/domain/models/exam.dart';

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  const _GlassCard({required this.child, this.width});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 260),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
      ),
      child: child,
    );
  }
}

class StudentSummaryPage extends StatefulWidget {
  final int studentId;
  const StudentSummaryPage({super.key, required this.studentId});

  @override
  State<StudentSummaryPage> createState() => _StudentSummaryPageState();
}

class _StudentSummaryPageState extends State<StudentSummaryPage> {
  Student? student;
  List<Attendance> attendanceRecords = [];
  List<ExamResult> examResults = [];
  List<Exam> exams = [];
  bool isLoading = true;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isar = DatabaseService.instance;
    final studentRepo = StudentRepository(isar);
    final examRepo = ExamRepository(isar);
    final s = await studentRepo.getStudentById(widget.studentId);
    final attendance = await isar.attendances.filter().studentIdEqualTo(widget.studentId).findAll();
    final results = await examRepo.getResultsForStudent(widget.studentId);
    // Fetch all related exams in one go
    final examIds = results.map((r) => r.examId).toSet().toList();
    final fetchedExams = <Exam>[];
    for (final id in examIds) {
      final exam = await examRepo.getExamById(id);
      if (exam != null) fetchedExams.add(exam);
    }
    setState(() {
      student = s;
      attendanceRecords = attendance;
      examResults = results;
      exams = fetchedExams;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Student',
            onPressed: student == null ? null : () {
              // TODO: Implement edit dialog navigation
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Student',
            onPressed: student == null ? null : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Student'),
                  content: Text('Are you sure you want to delete ${student!.fullName}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                final isar = DatabaseService.instance;
                await isar.writeTxn(() async {
                  await isar.students.delete(student!.id);
                });
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : student == null
              ? const Center(child: Text('Student not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Info Card (centered, glassmorphic)
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          margin: const EdgeInsets.only(bottom: 40, top: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                                radius: 48,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.13),
                            child: Text(
                              student!.fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                    fontSize: 38,
                                    letterSpacing: -1.5,
                              ),
                            ),
                          ),
                              const SizedBox(width: 40),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Text(student!.fullName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -1, fontSize: 30)),
                                    const SizedBox(height: 10),
                                    Text(student!.email, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700], fontSize: 17)),
                                if (student!.phoneNumber != null && student!.phoneNumber!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text('Phone: ${student!.phoneNumber}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                      ),
                                if (student!.address != null && student!.address!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text('Address: ${student!.address}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                      ),
                                if (student!.dateOfBirth != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text('Date of Birth: ${dateFormat.format(student!.dateOfBirth!)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                      ),
                                if (student!.dateOfBirth != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text('Age: ${_calculateAge(student!.dateOfBirth!)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                      ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text('Registered: ${dateFormat.format(student!.createdAt)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
                                        const SizedBox(width: 16),
                                        Text('Last Updated: ${dateFormat.format(student!.updatedAt)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
                                      ],
                                    ),
                              ],
                            ),
                          ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Dashboard Cards (centered, constrained, equal height)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: _buildStudentDashboardCards(),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
    );
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String _attendancePercentage() {
    if (attendanceRecords.isEmpty) return '0';
    final present = attendanceRecords.where((a) => a.status == AttendanceStatus.present).length;
    return ((present / attendanceRecords.length) * 100).toStringAsFixed(1);
  }

  List<Widget> _buildRecentAttendance() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final recent = attendanceRecords.reversed.take(5).toList();
    return recent.map((a) => Row(
      children: [
        Icon(_attendanceIcon(a.status), color: _attendanceColor(a.status), size: 18),
        const SizedBox(width: 8),
        Text(dateFormat.format(a.date)),
        const SizedBox(width: 8),
        Text(_attendanceLabel(a.status)),
      ],
    )).toList();
  }

  IconData _attendanceIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Icons.check_circle;
      case AttendanceStatus.absent: return Icons.cancel;
      case AttendanceStatus.late: return Icons.access_time;
      case AttendanceStatus.excused: return Icons.info;
    }
  }

  Color _attendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.late: return Colors.orange;
      case AttendanceStatus.excused: return Colors.blue;
    }
  }

  String _attendanceLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent: return 'Absent';
      case AttendanceStatus.late: return 'Late';
      case AttendanceStatus.excused: return 'Excused';
    }
  }

  Widget _buildAttendanceChartAndSummary() {
    if (attendanceRecords.isEmpty) {
      return const SizedBox.shrink();
    }
    final present = attendanceRecords.where((a) => a.status == AttendanceStatus.present).length;
    final absent = attendanceRecords.where((a) => a.status == AttendanceStatus.absent).length;
    final late = attendanceRecords.where((a) => a.status == AttendanceStatus.late).length;
    final excused = attendanceRecords.where((a) => a.status == AttendanceStatus.excused).length;
    final total = attendanceRecords.length;
    final values = [present, absent, late, excused];
    final colors = [const Color(0xFF6EE7B7), const Color(0xFFFCA5A5), const Color(0xFFFDE68A), const Color(0xFF93C5FD)];
    final labels = ['Present', 'Absent', 'Late', 'Excused'];
    final sections = [
      if (present > 0)
        PieChartSectionData(color: colors[0], value: present.toDouble(), title: '', radius: 32),
      if (absent > 0)
        PieChartSectionData(color: colors[1], value: absent.toDouble(), title: '', radius: 32),
      if (late > 0)
        PieChartSectionData(color: colors[2], value: late.toDouble(), title: '', radius: 32),
      if (excused > 0)
        PieChartSectionData(color: colors[3], value: excused.toDouble(), title: '', radius: 32),
    ];
    final legendItems = [
      if (present > 0) _AppleLegendDot(color: colors[0], label: 'Present'),
      if (absent > 0) _AppleLegendDot(color: colors[1], label: 'Absent'),
      if (late > 0) _AppleLegendDot(color: colors[2], label: 'Late'),
      if (excused > 0) _AppleLegendDot(color: colors[3], label: 'Excused'),
    ];
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          constraints: const BoxConstraints(minHeight: 220),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: sections.map((section) {
                          final isTouched = sections.indexOf(section) == touchedIndex;
                          final double radius = isTouched ? 35 : 32;
                          return PieChartSectionData(
                            color: section.color,
                            value: section.value,
                            title: isTouched ? '${((section.value / total) * 100).toStringAsFixed(1)}%' : '',
                            radius: radius,
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            titlePositionPercentageOffset: 0.5,
                          );
                        }).toList(),
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                            });
                          },
                          enabled: true,
                        ),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 800),
                      swapAnimationCurve: Curves.easeInOutCubic,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...legendItems,
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<String>> _fetchAssignedClasses(int studentId) async {
    final subjects = await DatabaseService.subjects.filter().studentIdsElementEqualTo(studentId).findAll();
    return subjects.map((s) => s.name).toList();
  }

  Widget _buildStudentDashboardCards() {
    return FutureBuilder<List<String>>(
      future: _fetchAssignedClasses(student!.id),
      builder: (context, snapshot) {
        final assignedClasses = snapshot.data ?? [];
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth <= 600;
            if (isMobile) {
              // Stack vertically for small screens
              return Column(
                children: [
                  _GlassCard(child: _buildAssignedClassesCard(assignedClasses)),
                  const SizedBox(height: 16),
                  _GlassCard(child: _buildExamResultsCard()),
                  const SizedBox(height: 16),
                  _GlassCard(child: _buildAttendanceCard()),
                ],
              );
            } else {
              // Side by side for Assigned Classes and Attendance, Exam Results below
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _GlassCard(child: _buildAssignedClassesCard(assignedClasses)),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _GlassCard(child: _buildAttendanceCard()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _GlassCard(child: _buildExamResultsCard()),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildAssignedClassesCard(List<String> classes) {
    final grades = examResults.map((r) => r.grade ?? 0).toList();
    final avgExam = grades.isNotEmpty ? (grades.reduce((a, b) => a + b) / grades.length) : 0.0;
    final present = attendanceRecords.where((a) => a.status == AttendanceStatus.present).length;
    final avgAttendance = attendanceRecords.isNotEmpty ? (present / attendanceRecords.length) * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Averages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded, color: Colors.grey[400], size: 32),
                        const SizedBox(height: 6),
                        Text(
                          avgExam.isNaN ? '-' : '${avgExam.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.85),
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Avg Exam', style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.2,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.grey[400], size: 32),
                        const SizedBox(height: 6),
                        Text(
                          avgAttendance.isNaN ? '-' : '${avgAttendance.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.85),
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Avg Attendance', style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamResultsCard() {
    if (examResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exam Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 14),
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey.withOpacity(0.25)),
                  const SizedBox(height: 8),
                  Text('No exam results yet', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Pair results with their exams and sort by date
    final resultExamPairs = examResults.map((r) {
      final exam = exams.firstWhere((e) => e.id == r.examId, orElse: () => Exam.create(name: 'Unknown', classId: 0, className: '', date: DateTime(2000), userId: ''));
      return {'result': r, 'exam': exam};
    }).toList();
    resultExamPairs.sort((a, b) => (a['exam'] as Exam).date.compareTo((b['exam'] as Exam).date));

    final grades = resultExamPairs.map((pair) => (pair['result'] as ExamResult).grade ?? 0).toList();
    final avg = grades.isNotEmpty ? (grades.reduce((a, b) => a + b) / grades.length) : 0.0;
    final highest = grades.isNotEmpty ? grades.reduce((a, b) => a > b ? a : b) : 0.0;
    final lowest = grades.isNotEmpty ? grades.reduce((a, b) => a < b ? a : b) : 0.0;

    final dateFormat = DateFormat('yyyy-MM-dd');

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exam Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatChip(
                  label: 'Average',
                  countStr: avg.toStringAsFixed(1),
                  color: const Color(0xFF2979FF),
                  icon: Icons.analytics,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Highest',
                  count: highest.round(),
                  color: const Color(0xFF4CAF50),
                  icon: Icons.trending_up,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Lowest',
                  count: lowest.round(),
                  color: const Color(0xFFF44336),
                  icon: Icons.trending_down,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Only show a label if this value is an integer and matches an exam index
                        if (value % 1 != 0 || value.toInt() < 0 || value.toInt() >= resultExamPairs.length) {
                          return const SizedBox.shrink();
                        }
                        final exam = resultExamPairs[value.toInt()]['exam'] as Exam;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dateFormat.format(exam.date),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: resultExamPairs.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['result'] as ExamResult).grade ?? 0);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF2979FF),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2979FF).withOpacity(0.12),
                    ),
                    showingIndicators: List.generate(resultExamPairs.length, (i) => i),
                  ),
                ],
                minY: 0,
                maxY: 100,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final exam = resultExamPairs[idx]['exam'] as Exam;
                        final result = resultExamPairs[idx]['result'] as ExamResult;
                        return LineTooltipItem(
                          '${exam.name}\n${dateFormat.format(exam.date)}\nGrade: ${result.grade?.toStringAsFixed(1) ?? '-'}',
                          const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Expanded(
              child: _buildAttendanceChartAndSummary(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _AppleLegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int? count;
  final String? countStr;
  final Color color;
  final IconData icon;
  const _StatChip({required this.label, this.count, this.countStr, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Text(
            countStr ?? (count?.toString() ?? '-'),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
} 