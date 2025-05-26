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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'exam_csv_download_helper.dart';

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
  final accentColor = const Color(0xFF2979FF); // Apple blue accent
  String searchQuery = '';
  String sortBy = 'Name';
  Map<int, String?> gradeErrors = {};

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
      final allStudents = await studentRepository.getAllStudents();
      final subject = await subjectRepository.getSubjectById(widget.exam.classId);
      final classStudentIds = subject?.studentIds ?? [];
      final classStudents = allStudents.where((s) => classStudentIds.contains(s.id)).toList();
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
      // Inline validation
      if (grade != null && (grade < 0 || grade > 100)) {
        gradeErrors[studentId] = 'Grade must be 0–100';
      } else {
        gradeErrors.remove(studentId);
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
      final result = results.firstWhere(
        (r) => r.studentId == student.id,
        orElse: () => ExamResult.create(examId: widget.exam.id, studentId: student.id)
      );
      rows.add([
        student.fullName,
        student.email,
        result.grade?.toString() ?? '',
        result.comment ?? '',
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      downloadCSVWeb(csv, 'exam_results_${widget.exam.id}.csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV downloaded!')),
        );
      }
    } else {
      // Mobile/Desktop: save to Downloads
      final directory = await getDownloadsDirectory();
      final file = File('${directory.path}/exam_results_${widget.exam.id}.csv');
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV saved to: ${file.path}')),
        );
      }
    }
  }

  Future<Directory> getDownloadsDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      final downloads = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      if (await downloads.exists()) return downloads;
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS) {
      final downloads = Directory('${Platform.environment['HOME']}/Downloads');
      if (await downloads.exists()) return downloads;
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isLinux) {
      final downloads = Directory('${Platform.environment['HOME']}/Downloads');
      if (await downloads.exists()) return downloads;
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = results.map((r) => r.grade ?? 0).where((g) => g > 0).toList();
    final avg = grades.isNotEmpty ? (grades.reduce((a, b) => a + b) / grades.length) : 0.0;
    final highest = grades.isNotEmpty ? grades.reduce((a, b) => a > b ? a : b) : 0.0;
    final lowest = grades.isNotEmpty ? grades.reduce((a, b) => a < b ? a : b) : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // Clean, soft off-white
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  _buildSummaryCard(avg),
                  _buildStatsRow(avg, highest, lowest, students.length),
                  _buildDonutChart(grades),
                  _buildStudentResults(),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard(double avg) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          margin: const EdgeInsets.only(top: 28, bottom: 18),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
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
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.exam.className,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text('Average', style: TextStyle(fontSize: 15, color: accentColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${avg.toStringAsFixed(1)}%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(double avg, double highest, double lowest, int count) {
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          margin: const EdgeInsets.only(bottom: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(label: 'Average', value: '${avg.toStringAsFixed(1)}%', color: accentColor),
              _StatCard(label: 'Highest', value: '${highest.toStringAsFixed(1)}%', color: accentColor),
              _StatCard(label: 'Lowest', value: '${lowest.toStringAsFixed(1)}%', color: accentColor),
              _StatCard(label: 'Students', value: '$count', color: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChart(List<double> grades) {
    if (grades.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Text('No results yet.')));
    }
    // Irish grading bands
    final Map<String, int> gradeBands = {
      'H1': 0,
      'H2': 0,
      'H3': 0,
      'H4': 0,
      'H5': 0,
      'H6': 0,
      'H7': 0,
      'H8': 0,
    };
    for (final g in grades) {
      if (g >= 90) {
        gradeBands['H1'] = gradeBands['H1']! + 1;
      } else if (g >= 80) {
        gradeBands['H2'] = gradeBands['H2']! + 1;
      } else if (g >= 70) {
        gradeBands['H3'] = gradeBands['H3']! + 1;
      } else if (g >= 60) {
        gradeBands['H4'] = gradeBands['H4']! + 1;
      } else if (g >= 50) {
        gradeBands['H5'] = gradeBands['H5']! + 1;
      } else if (g >= 40) {
        gradeBands['H6'] = gradeBands['H6']! + 1;
      } else if (g >= 30) {
        gradeBands['H7'] = gradeBands['H7']! + 1;
      } else {
        gradeBands['H8'] = gradeBands['H8']! + 1;
      }
    }
    final List<Color> chartColors = [
      Color(0xFF6EC6FF), // H1 blue
      Color(0xFF81C784), // H2 green
      Color(0xFFFFF176), // H3 yellow
      Color(0xFFFFB74D), // H4 orange
      Color(0xFFE57373), // H5 red
      Color(0xFFBA68C8), // H6 purple
      Color(0xFF90A4AE), // H7 blue-grey
      Color(0xFFDCE775), // H8 lime
    ];
    final pieSections = <PieChartSectionData>[];
    final total = grades.length;
    int i = 0;
    gradeBands.forEach((band, count) {
      if (count > 0) {
        final percent = (count / total) * 100;
        pieSections.add(
          PieChartSectionData(
            color: chartColors[i % chartColors.length].withOpacity(0.85),
            value: count.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            radius: 48,
            titleStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
        );
      }
      i++;
    });
    return SliverToBoxAdapter(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: pieSections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: gradeBands.entries.where((e) => e.value > 0).map((e) {
                  final idx = gradeBands.keys.toList().indexOf(e.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: chartColors[idx % chartColors.length].withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                        const SizedBox(width: 8),
                        Text('(${e.value})', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentResults() {
    // Filter and sort students
    List<Student> filtered = students.where((s) {
      final q = searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) || s.email.toLowerCase().contains(q);
    }).toList();
    if (sortBy == 'Name') {
      filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else if (sortBy == 'Grade') {
      filtered.sort((a, b) {
        final aGrade = results.firstWhere((r) => r.studentId == a.id, orElse: () => ExamResult.create(examId: widget.exam.id, studentId: a.id)).grade ?? 0;
        final bGrade = results.firstWhere((r) => r.studentId == b.id, orElse: () => ExamResult.create(examId: widget.exam.id, studentId: b.id)).grade ?? 0;
        return bGrade.compareTo(aGrade);
      });
    }
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium Apple-style search field
                Expanded(
                  child: _PremiumSearchField(
                    value: searchQuery,
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
                const SizedBox(width: 20),
                // Premium Apple-style sort dropdown
                _PremiumSortDropdown(
                  value: sortBy,
                  onChanged: (val) => setState(() => sortBy = val ?? 'Name'),
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final student = filtered[index];
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
                  errorText: gradeErrors[student.id],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Apple premium Save All button
                SizedBox(
                  width: 160,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving || gradeErrors.isNotEmpty ? null : _saveAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      elevation: 0,
                      shadowColor: accentColor.withOpacity(0.18),
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return accentColor.withOpacity(0.4);
                        }
                        return accentColor;
                      }),
                    ),
                    child: isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save All'),
                  ),
                ),
                const SizedBox(width: 20),
                // Apple premium Export button
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : _exportCSV,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor.withOpacity(0.25), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      backgroundColor: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.04),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
                    ).copyWith(
                      side: MaterialStateProperty.resolveWith<BorderSide>((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return BorderSide(color: accentColor.withOpacity(0.10), width: 2);
                        }
                        return BorderSide(color: accentColor.withOpacity(0.25), width: 2);
                      }),
                    ),
                    icon: Icon(Icons.download_rounded, color: accentColor, size: 24),
                    label: const Text('Export'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.13), width: 1),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 15)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 22)),
        ],
      ),
    );
  }
}

class _StudentResultCard extends StatefulWidget {
  final Student student;
  final ExamResult result;
  final ValueChanged<double?> onGradeChanged;
  final ValueChanged<String?> onCommentChanged;
  final Color accentColor;
  final String? errorText;

  const _StudentResultCard({
    required this.student,
    required this.result,
    required this.onGradeChanged,
    required this.onCommentChanged,
    required this.accentColor,
    this.errorText,
    Key? key,
  }) : super(key: key);

  @override
  State<_StudentResultCard> createState() => _StudentResultCardState();
}

class _StudentResultCardState extends State<_StudentResultCard> {
  late final TextEditingController gradeController;
  late final TextEditingController commentController;

  String formatGrade(double? grade) {
    if (grade == null) return '';
    if (grade == grade.roundToDouble()) {
      return grade.toInt().toString();
    }
    return grade.toString();
  }

  @override
  void initState() {
    super.initState();
    gradeController = TextEditingController(text: formatGrade(widget.result.grade));
    commentController = TextEditingController(text: widget.result.comment ?? '');
  }

  @override
  void didUpdateWidget(covariant _StudentResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final formatted = formatGrade(widget.result.grade);
    if (oldWidget.result.grade != widget.result.grade && gradeController.text != formatted) {
      gradeController.text = formatted;
    }
    if (oldWidget.result.comment != widget.result.comment && commentController.text != (widget.result.comment ?? '')) {
      commentController.text = widget.result.comment ?? '';
    }
  }

  @override
  void dispose() {
    gradeController.dispose();
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.10), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: widget.accentColor.withOpacity(0.10),
                child: Text(
                  widget.student.fullName.isNotEmpty ? widget.student.fullName[0] : '?',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.student.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(widget.student.email, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Grade input
              SizedBox(
                width: 100,
                child: Focus(
                  child: TextField(
                    controller: gradeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Grade',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.18), width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.18), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: widget.accentColor, width: 1.7),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.7),
                      ),
                      errorText: null,
                    ),
                    onChanged: (val) {
                      final grade = double.tryParse(val);
                      widget.onGradeChanged(grade);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: widget.accentColor, fontSize: 20)),
            ],
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 70, top: 4),
              child: Text(
                widget.errorText!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: 14),
          // Comment field
          TextField(
            controller: commentController,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Comment (optional)',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.18), width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.18), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.accentColor, width: 1.7),
              ),
            ),
            style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w400),
            onChanged: widget.onCommentChanged,
          ),
        ],
      ),
    );
  }
}

// Place these at the very end of the file, outside of any other class:

class _PremiumSearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PremiumSearchField({required this.value, required this.onChanged});
  @override
  State<_PremiumSearchField> createState() => _PremiumSearchFieldState();
}

class _PremiumSearchFieldState extends State<_PremiumSearchField> {
  bool _focused = false;
  late final FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.ease,
      height: 48,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF2979FF).withOpacity(0.13),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
        border: Border.all(
          color: _focused ? const Color(0xFF2979FF) : Colors.transparent,
          width: 1.7,
        ),
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: TextEditingController(text: widget.value),
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w400, fontFamily: null),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.grey[300], size: 26),
          hintText: 'Search students...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 17),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}

class _PremiumSortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final Color accentColor;
  const _PremiumSortDropdown({required this.value, required this.onChanged, required this.accentColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.transparent, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          borderRadius: BorderRadius.circular(18),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 17),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[300], size: 28),
          items: ['Name', 'Grade']
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text('Sort by $s', style: const TextStyle(color: Colors.black)),
                  ))
              .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
} 