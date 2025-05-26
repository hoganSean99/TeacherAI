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
import 'package:teacher_ai/features/exams/domain/models/exam_result.dart';
import 'package:teacher_ai/features/exams/data/exam_repository.dart';

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
    setState(() {
      student = s;
      attendanceRecords = attendance;
      examResults = results;
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
    final percent = total == 0 ? 0.0 : (present / total) * 100;
    final sections = [
      if (present > 0)
        PieChartSectionData(
          color: const Color(0xFF6EE7B7),
          value: present.toDouble(),
          title: total > 0 ? '${((present / total) * 100).toStringAsFixed(0)}%' : '',
          radius: touchedIndex == 0 ? 70 : 54,
          showTitle: true,
          titleStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700]?.withOpacity(0.7),
          ),
          titlePositionPercentageOffset: 0.6,
          badgeWidget: touchedIndex == 0 ? Container(
            width: 0,
            height: 0,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ) : null,
          badgePositionPercentageOffset: touchedIndex == 0 ? 1.25 : 1.15,
        ),
      if (absent > 0)
        PieChartSectionData(
          color: const Color(0xFFFCA5A5),
          value: absent.toDouble(),
          title: total > 0 ? '${((absent / total) * 100).toStringAsFixed(0)}%' : '',
          radius: touchedIndex == 1 ? 70 : 54,
          showTitle: true,
          titleStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700]?.withOpacity(0.7),
          ),
          titlePositionPercentageOffset: 0.6,
          badgeWidget: touchedIndex == 1 ? Container(
            width: 0,
            height: 0,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ) : null,
          badgePositionPercentageOffset: touchedIndex == 1 ? 1.25 : 1.15,
        ),
      if (late > 0)
        PieChartSectionData(
          color: const Color(0xFFFDE68A),
          value: late.toDouble(),
          title: total > 0 ? '${((late / total) * 100).toStringAsFixed(0)}%' : '',
          radius: touchedIndex == 2 ? 70 : 54,
          showTitle: true,
          titleStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700]?.withOpacity(0.7),
          ),
          titlePositionPercentageOffset: 0.6,
          badgeWidget: touchedIndex == 2 ? Container(
            width: 0,
            height: 0,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ) : null,
          badgePositionPercentageOffset: touchedIndex == 2 ? 1.25 : 1.15,
        ),
      if (excused > 0)
        PieChartSectionData(
          color: const Color(0xFF93C5FD),
          value: excused.toDouble(),
          title: total > 0 ? '${((excused / total) * 100).toStringAsFixed(0)}%' : '',
          radius: touchedIndex == 3 ? 70 : 54,
          showTitle: true,
          titleStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700]?.withOpacity(0.7),
          ),
          titlePositionPercentageOffset: 0.6,
          badgeWidget: touchedIndex == 3 ? Container(
            width: 0,
            height: 0,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ) : null,
          badgePositionPercentageOffset: touchedIndex == 3 ? 1.25 : 1.15,
        ),
    ];
    final legendItems = [
      if (present > 0) _LegendItem(color: const Color(0xFF6EE7B7), label: 'Present'),
      if (absent > 0) _LegendItem(color: const Color(0xFFFCA5A5), label: 'Absent'),
      if (late > 0) _LegendItem(color: const Color(0xFFFDE68A), label: 'Late'),
      if (excused > 0) _LegendItem(color: const Color(0xFF93C5FD), label: 'Excused'),
    ];
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MouseRegion(
                        onHover: (event) {
                          final box = context.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          final local = box.globalToLocal(event.position);
                          final center = Offset(box.size.width / 2, box.size.height / 2);
                          final dx = local.dx - center.dx;
                          final dy = local.dy - center.dy;
                          final distance = sqrt(dx * dx + dy * dy);
                          // Only react if pointer is within the pie radius (adjust as needed)
                          if (distance < 100 && distance > 60) {
                            double angle = atan2(dy, dx);
                            if (angle < 0) angle += 2 * pi;
                            double total = (present + absent + late + excused).toDouble();
                            List<double> values = [present.toDouble(), absent.toDouble(), late.toDouble(), excused.toDouble()];
                            int section = -1;
                            double start = 0.0;
                            for (int i = 0; i < values.length; i++) {
                              double sweep = (values[i] / total) * 2 * pi;
                              if (angle >= start && angle < start + sweep) {
                                section = i;
                                break;
                              }
                              start += sweep;
                            }
                            if (section != touchedIndex) setState(() => touchedIndex = section);
                          } else {
                            if (touchedIndex != -1) setState(() => touchedIndex = -1);
                          }
                        },
                        onExit: (_) {
                          if (touchedIndex != -1) setState(() => touchedIndex = -1);
                        },
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: sections,
                            borderData: FlBorderData(show: false),
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                                });
                              },
                            ),
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 900),
                          swapAnimationCurve: Curves.easeInOut,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Attendance',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ), 
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: legendItems,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
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
            final cardMaxWidth = 360.0;
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
              // Always horizontally scrollable for non-mobile
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardMaxWidth, minWidth: 260),
                      child: _GlassCard(child: _buildAssignedClassesCard(assignedClasses)),
                    ),
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardMaxWidth, minWidth: 260),
                      child: _GlassCard(child: _buildExamResultsCard()),
                    ),
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardMaxWidth, minWidth: 260),
                      child: _GlassCard(child: _buildAttendanceCard()),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildAssignedClassesCard(List<String> classes) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assigned Classes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 14),
          if (classes.isEmpty)
            const Text('No assigned classes', style: TextStyle(color: Colors.grey, fontSize: 15)),
          if (classes.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: classes.map((c) => Chip(
                label: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: Colors.white.withOpacity(0.7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: Colors.grey.withOpacity(0.15)),
              )).toList(),
            ),
        ],
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

    examResults.sort((a, b) => a.examId.compareTo(b.examId));
    final grades = examResults.map((r) => r.grade ?? 0).toList();
    final avg = grades.isNotEmpty ? (grades.reduce((a, b) => a + b) / grades.length) : 0.0;
    final highest = grades.isNotEmpty ? grades.reduce((a, b) => a > b ? a : b) : 0.0;
    final lowest = grades.isNotEmpty ? grades.reduce((a, b) => a < b ? a : b) : 0.0;

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
                  count: avg.round(),
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
            height: 180,
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
                        if (value.toInt() >= examResults.length) return const Text('');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Exam ${value.toInt() + 1}',
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
                    spots: grades.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
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
                  ),
                ],
                minY: 0,
                maxY: 100,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 14),
          _buildAttendanceChartAndSummary(),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
      children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _StatChip({required this.label, required this.count, required this.color, required this.icon});
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
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
} 