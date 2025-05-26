import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'package:teacher_ai/features/subjects/data/subject_repository.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:teacher_ai/features/core/domain/models/subject.dart';
import 'package:teacher_ai/features/exams/domain/models/exam.dart';
import 'package:teacher_ai/features/exams/data/exam_repository.dart';
import 'dart:ui';
import 'exam_dashboard_page.dart';

final examsProvider = StateProvider<List<Exam>>((ref) => []);

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load exams from database on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExams(ref);
    });

    final exams = ref.watch(examsProvider);
    final now = DateTime.now();
    final upcoming = exams.where((e) => e.date.isAfter(now)).toList();
    final past = exams.where((e) => e.date.isBefore(now)).toList();
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
            child: CustomScrollView(
              slivers: [
                // Apple-style glassmorphic header card
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
                          Text(
                            'Exams',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              fontSize: 28,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.55),
                              foregroundColor: accentColor,
                              shadowColor: accentColor.withOpacity(0.10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            ),
                            onPressed: () => _showExamDialog(context, ref),
                            icon: Icon(Icons.add, color: accentColor),
                            label: const Text('Add Exam', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Exam list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  sliver: (upcoming.isEmpty && past.isEmpty)
                      ? const SliverToBoxAdapter(child: Center(child: Text('No exams yet.')))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (upcoming.isNotEmpty && index < upcoming.length) {
                                final exam = upcoming[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 18.0),
                                  child: _AppleExamTile(
                                    exam: exam,
                                    isPast: false,
                                    onEdit: () => _showExamDialog(context, ref, exam: exam),
                                    onDelete: () => _deleteExam(context, ref, exam),
                                  ),
                                );
                              } else {
                                final pastIndex = index - upcoming.length;
                                final exam = past[pastIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 18.0),
                                  child: _AppleExamTile(
                                    exam: exam,
                                    isPast: true,
                                    onEdit: () => _showExamDialog(context, ref, exam: exam),
                                    onDelete: () => _deleteExam(context, ref, exam),
                                  ),
                                );
                              }
                            },
                            childCount: upcoming.length + past.length,
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

  Future<void> _showExamDialog(BuildContext context, WidgetRef ref, {Exam? exam}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user logged in')));
      return;
    }
    final subjectRepo = SubjectRepository(DatabaseService.instance);
    final examRepo = ExamRepository(DatabaseService.instance);
    final subjects = await subjectRepo.getSubjectsByUserId(user.uuid);
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: exam?.name ?? '');
    int? selectedClassId = exam?.classId;
    String? selectedClassName = exam?.className;
    DateTime? selectedDate = exam?.date;
    String? filePath = exam?.filePath;
    final accentColor = const Color(0xFF8E24AA);
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.18),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: accentColor.withOpacity(0.12),
                          child: Icon(Icons.description, color: accentColor, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          exam == null ? 'Add Exam' : 'Update Exam',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          exam == null
                            ? 'Fill in the details below to add an exam.'
                            : 'Update the details below and save changes.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Exam Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.isEmpty ? 'Enter exam name' : null,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: selectedClassId,
                    items: subjects.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    )).toList(),
                    onChanged: (v) {
                      selectedClassId = v;
                      selectedClassName = subjects.firstWhere((s) => s.id == v).name;
                    },
                    decoration: InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.class_),
                    ),
                    validator: (v) => v == null ? 'Select a class' : null,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Exam Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDate != null
                            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                            : 'Select Date',
                        style: TextStyle(
                          color: selectedDate != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          filePath == null ? 'No file selected' : filePath.split('/').last,
                          style: TextStyle(color: filePath == null ? Colors.grey : Colors.black),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () {
                          // TODO: Implement file picker
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            final newExam = Exam.create(
                              name: nameController.text,
                              classId: selectedClassId!,
                              className: selectedClassName!,
                              date: selectedDate!,
                              userId: user.uuid,
                              filePath: filePath,
                            );
                            
                            // Save to database
                            if (exam == null) {
                              await examRepo.addExam(newExam);
                            } else {
                              newExam.id = exam.id; // Preserve the ID for updates
                              await examRepo.updateExam(newExam);
                            }
                            
                            // Update state
                            final exams = [...ref.read(examsProvider)];
                            if (exam == null) {
                              exams.add(newExam);
                            } else {
                              final idx = exams.indexWhere((e) => e.id == exam.id);
                              if (idx != -1) exams[idx] = newExam;
                            }
                            ref.read(examsProvider.notifier).state = exams;
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(exam == null ? 'Add Exam' : 'Update Exam', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteExam(BuildContext context, WidgetRef ref, Exam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final exams = [...ref.read(examsProvider)];
      exams.removeWhere((e) => e.id == exam.id);
      ref.read(examsProvider.notifier).state = exams;
    }
  }

  Future<void> _loadExams(WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    try {
      final examRepo = ExamRepository(DatabaseService.instance);
      final exams = await examRepo.getExamsByUserId(user.uuid);
      ref.read(examsProvider.notifier).state = exams;
    } catch (e) {
      debugPrint('Error loading exams: $e');
    }
  }
}

class _AppleExamTile extends StatelessWidget {
  final Exam exam;
  final bool isPast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AppleExamTile({required this.exam, required this.isPast, required this.onEdit, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isPast ? Colors.grey.withOpacity(0.18) : Colors.white.withOpacity(0.60),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
            ),
            child: ListTile(
              leading: Icon(Icons.description_rounded, color: isPast ? Colors.grey : Colors.deepPurple, size: 32),
              title: Text(
                exam.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.5, fontFamily: 'SF Pro Display'),
              ),
              subtitle: Text(
                '${exam.className}  |  ${exam.date.year}-${exam.date.month.toString().padLeft(2, '0')}-${exam.date.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 15, color: Colors.grey[700], fontFamily: 'SF Pro Text'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ExamDashboardPage(exam: exam),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
} 