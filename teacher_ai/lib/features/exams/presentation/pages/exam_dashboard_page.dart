import 'package:flutter/material.dart';
import 'package:teacher_ai/features/exams/domain/models/exam.dart';
import 'package:teacher_ai/features/exams/domain/models/exam_result.dart';
import 'package:teacher_ai/features/exams/data/exam_repository.dart';
import 'package:teacher_ai/features/core/domain/models/subject.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';
import 'package:teacher_ai/features/subjects/data/subject_repository.dart';
import 'package:teacher_ai/features/students/data/repositories/student_repository.dart';
import 'package:isar/isar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

class ExamDashboardPage extends ConsumerStatefulWidget {
  final Exam exam;
  const ExamDashboardPage({super.key, required this.exam});
  @override
  ConsumerState<ExamDashboardPage> createState() => _ExamDashboardPageState();
}

class _ExamDashboardPageState extends ConsumerState<ExamDashboardPage> {
  late final ExamRepository examRepository;
  late final StudentRepository studentRepository;
  late final SubjectRepository subjectRepository;
  List<Student> students = [];
  List<ExamResult> results = [];
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final isar = DatabaseService.instance;
    examRepository = ExamRepository(isar);
    studentRepository = StudentRepository(isar);
    subjectRepository = SubjectRepository(isar);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { isLoading = true; });
    try {
      // Get all students in the class
      final allStudents = await studentRepository.getAllStudents();
      final subject = await subjectRepository.getSubjectById(widget.exam.classId);
      final classStudentIds = subject?.studentIds ?? [];
      final classStudents = allStudents.where((s) => classStudentIds.contains(s.id)).toList();
      // Get all results for this exam
      final examResults = await examRepository.getResultsForExam(widget.exam.id);
      setState(() {
        students = classStudents;
        results = examResults;
        isLoading = false;
      });
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exam data: $e')),
        );
      }
    }
  }

  void _updateResult(int studentId, {double? grade, String? comment}) {
    setState(() {
      final idx = results.indexWhere((r) => r.studentId == studentId);
      if (idx != -1) {
        if (grade != null) results[idx].grade = grade;
        if (comment != null) results[idx].comment = comment;
      } else {
        results.add(ExamResult.create(examId: widget.exam.id, studentId: studentId, grade: grade, comment: comment));
      }
    });
  }

  Future<void> _saveAll() async {
    setState(() { isSaving = true; });
    try {
      await examRepository.saveAllResults(results);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Results saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving results: $e')),
        );
      }
    } finally {
      setState(() { isSaving = false; });
    }
  }

  Future<void> _exportCSV() async {
    final headers = ['Student Name', 'Email', 'Grade', 'Comment'];
    final rows = [headers];
    for (final student in students) {
      final result = results.firstWhere((r) => r.studentId == student.id, orElse: () => ExamResult.create(examId: widget.exam.id, studentId: student.id));
      rows.add([
        student.fullName,
        student.email,
        result.grade?.toString() ?? '',
        result.comment ?? '',
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/exam_results_${widget.exam.id}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exam Results: ${widget.exam.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF8E24AA);
    final grades = results.map((r) => r.grade ?? 0).where((g) => g > 0).toList();
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
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // Glassmorphic header
                      SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 900),
                            margin: const EdgeInsets.only(top: 24, bottom: 32),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 32,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.exam.name,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -1,
                                        fontSize: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.exam.className,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: accentColor.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Date: ${widget.exam.date.year}-${widget.exam.date.month.toString().padLeft(2, '0')}-${widget.exam.date.day.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.55),
                                        foregroundColor: accentColor,
                                        shadowColor: accentColor.withOpacity(0.10),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                      ),
                                      onPressed: isSaving ? null : _saveAll,
                                      icon: isSaving
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                          : Icon(Icons.save, color: accentColor),
                                      label: const Text('Save All', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: accentColor,
                                        side: BorderSide(color: accentColor.withOpacity(0.25)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                      ),
                                      onPressed: _exportCSV,
                                      icon: Icon(Icons.download_rounded, color: accentColor),
                                      label: const Text('Export', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Graphs
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: _buildGraphs(grades, accentColor),
                        ),
                      ),
                      // Student results list
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final student = students[index];
                              final result = results.firstWhere(
                                (r) => r.studentId == student.id,
                                orElse: () => ExamResult.create(examId: widget.exam.id, studentId: student.id),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18.0),
                                child: _StudentResultCard(
                                  student: student,
                                  result: result,
                                  onGradeChanged: (grade) => _updateResult(student.id, grade: grade),
                                  onCommentChanged: (comment) => _updateResult(student.id, comment: comment),
                                  accentColor: accentColor,
                                ),
                              );
                            },
                            childCount: students.length,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudentResultCard extends StatelessWidget {
  final Student student;
  final ExamResult result;
  final ValueChanged<double?> onGradeChanged;
  final ValueChanged<String?> onCommentChanged;
  final Color accentColor;
  const _StudentResultCard({required this.student, required this.result, required this.onGradeChanged, required this.onCommentChanged, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    final gradeController = TextEditingController(text: result.grade?.toString() ?? '');
    final commentController = TextEditingController(text: result.comment ?? '');
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: Column(
              children: [
                ListTile(
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
                  trailing: SizedBox(
                    width: 90,
                    child: TextField(
                      controller: gradeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Grade',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final grade = double.tryParse(val);
                        onGradeChanged(grade);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Comment (optional)',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.85),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: onCommentChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildGraphs(List<double> grades, Color accentColor) {
  if (grades.isEmpty) {
    return const Center(child: Text('No results yet.'));
  }
  final avg = grades.isNotEmpty ? (grades.reduce((a, b) => a + b) / grades.length) : 0.0;
  final gradeDist = <String, int>{};
  for (final g in grades) {
    final bucket = (g / 10).floor() * 10;
    final label = '${bucket}-${bucket + 9}';
    gradeDist[label] = (gradeDist[label] ?? 0) + 1;
  }
  // Pie chart data
  final pieSections = <PieChartSectionData>[];
  final total = grades.length;
  int i = 0;
  for (final entry in gradeDist.entries) {
    final percent = (entry.value / total) * 100;
    pieSections.add(
      PieChartSectionData(
        color: accentColor.withOpacity(0.5 + 0.2 * (i % 2)),
        value: entry.value.toDouble(),
        title: '${percent.toStringAsFixed(0)}%',
        radius: 48,
        titleStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white.withOpacity(0.9)),
      ),
    );
    i++;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: accentColor)),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= gradeDist.keys.length) return const SizedBox();
                          return Text(gradeDist.keys.elementAt(idx), style: const TextStyle(fontSize: 12));
                        },
                        reservedSize: 32,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barGroups: [
                    for (int i = 0; i < gradeDist.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: gradeDist.values.elementAt(i).toDouble(),
                            color: accentColor,
                            width: 22,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: pieSections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Text('Average: ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
          Text('${avg.toStringAsFixed(1)}', style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
        ],
      ),
    ],
  );
} 