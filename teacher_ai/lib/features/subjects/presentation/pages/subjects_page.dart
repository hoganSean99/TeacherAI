import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher_ai/features/core/domain/models/subject.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';
import 'package:teacher_ai/features/subjects/data/subject_repository.dart';
import 'package:teacher_ai/features/students/data/repositories/student_repository.dart';
import 'package:isar/isar.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:teacher_ai/features/subjects/presentation/pages/class_dashboard_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'package:teacher_ai/features/core/domain/models/attendance.dart';
import 'dart:ui';

class SubjectsPage extends ConsumerStatefulWidget {
  const SubjectsPage({super.key});

  @override
  ConsumerState<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends ConsumerState<SubjectsPage> {
  late final SubjectRepository subjectRepository;
  late final StudentRepository studentRepository;
  List<Subject> subjects = [];
  List<Student> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final isar = DatabaseService.instance;
    subjectRepository = SubjectRepository(isar);
    studentRepository = StudentRepository(isar);
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
      final loadedSubjects = await subjectRepository.getSubjectsByUserId(currentUser.uuid);
      final loadedStudents = await studentRepository.getStudentsByUserId(currentUser.uuid);
      final isar = DatabaseService.instance;
      setState(() {
        subjects = loadedSubjects;
        students = loadedStudents;
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

  @override
  Widget build(BuildContext context) {
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
                            'Subjects',
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
                            onPressed: () => _showAddOrEditSubjectDialog(),
                            icon: Icon(Icons.add, color: accentColor),
                            label: const Text('Add Subject', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Subject list (keep as-is for now)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  sliver: isLoading
                      ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                      : subjects.isEmpty
                          ? const SliverToBoxAdapter(child: Center(child: Text('No subjects yet.')))
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final subject = subjects[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 18.0),
                                    child: _buildSubjectCard(subject, accentColor),
                                  );
                                },
                                childCount: subjects.length,
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

  Widget _buildSubjectCard(Subject subject, Color accentColor) {
    final assignedStudents = students.where((student) => subject.studentIds.contains(student.id)).toList();
    String getYearLabel(ClassYear year) {
      switch (year) {
        case ClassYear.firstYear:
          return '1st Year';
        case ClassYear.secondYear:
          return '2nd Year';
        case ClassYear.thirdYear:
          return '3rd Year';
        case ClassYear.transitionYear:
          return 'TY';
        case ClassYear.fifthYear:
          return '5th Year';
        case ClassYear.sixthYear:
          return '6th Year';
      }
    }
    final subjectColor = Color(int.parse(subject.color ?? '0xFF2196F3'));
    return StatefulBuilder(
      builder: (context, setState) {
        bool hovered = false;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hovered = true),
          onExit: (_) => setState(() => hovered = false),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ClassDashboardPage(year: subject.year),
                ),
              );
            },
            child: AnimatedScale(
              scale: hovered ? 1.025 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.82),
                      Colors.white.withOpacity(0.68),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(hovered ? 0.09 : 0.05),
                      blurRadius: hovered ? 32 : 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.13), width: 1.2),
                ),
                child: Stack(
                  children: [
                    // Glassy blurred vertical bar
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          bottomLeft: Radius.circular(28),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: 14,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  subjectColor.withOpacity(0.22),
                                  subjectColor.withOpacity(0.13),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Main content
                    Padding(
                      padding: const EdgeInsets.only(left: 32, right: 18, top: 20, bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Floating glassy icon with shadow
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.38),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: subjectColor.withOpacity(0.18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.65),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: subjectColor.withOpacity(0.10),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 26,
                                    color: subjectColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 26),
                          // Subject info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      subject.name,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        letterSpacing: -0.8,
                                        fontFamily: 'SF Pro',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildAppleChip(getYearLabel(subject.year), subjectColor.withOpacity(0.13), subjectColor.withOpacity(0.85)),
                                  ],
                                ),
                                if (subject.description?.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      subject.description!,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[600],
                                        height: 1.45,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'SF Pro',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),
                          // Student count chip and actions
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildAppleChip(
                                '${assignedStudents.length} ${assignedStudents.length == 1 ? 'Student' : 'Students'}',
                                Colors.grey[100]!,
                                Colors.grey[700]!,
                                icon: Icons.people_alt_rounded,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_rounded,
                                      size: 20,
                                      color: accentColor.withOpacity(0.85),
                                    ),
                                    onPressed: () => _showAddOrEditSubjectDialog(subject: subject),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: Colors.red[400],
                                    ),
                                    onPressed: () => _showDeleteConfirmation(subject),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Slight inner border for depth
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppleChip(String label, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: icon == null
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 7)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: fg.withOpacity(0.85)),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: fg,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddOrEditSubjectDialog({Subject? subject}) async {
    bool saving = false;
    final result = await showDialog<_SubjectDialogResult>(
      context: context,
      builder: (context) => _AddEditSubjectDialog(
        subject: subject,
        allStudents: students,
      ),
    );
    if (result != null) {
      setState(() { saving = true; });
      try {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser == null) {
          throw Exception('No user logged in');
        }
        if (subject != null) {
          final updated = Subject(
            id: subject.id,
            name: result.name,
            description: result.description,
            color: subject.color,
            userId: currentUser.uuid,
            studentIds: result.selectedStudentIds,
            year: result.year,
          );
          await subjectRepository.updateSubject(updated);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subject updated successfully!')),
            );
          }
        } else {
          final newSubject = Subject(
            name: result.name,
            description: result.description,
            color: null,
            userId: currentUser.uuid,
            studentIds: result.selectedStudentIds,
            year: result.year,
          );
          await subjectRepository.addSubject(newSubject);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subject added successfully!')),
            );
          }
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving subject: $e')),
          );
        }
      } finally {
        setState(() { saving = false; });
      }
    }
  }

  void _showDeleteConfirmation(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await subjectRepository.deleteSubject(subject.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting subject: $e')),
          );
        }
      }
    }
  }
}

class _SubjectDialogResult {
  final String name;
  final String? description;
  final List<int> selectedStudentIds;
  final ClassYear year;
  _SubjectDialogResult({
    required this.name, 
    this.description, 
    required this.selectedStudentIds,
    required this.year,
  });
}

class _AddEditSubjectDialog extends StatefulWidget {
  final Subject? subject;
  final List<Student> allStudents;
  const _AddEditSubjectDialog({this.subject, required this.allStudents});

  @override
  State<_AddEditSubjectDialog> createState() => _AddEditSubjectDialogState();
}

class _AddEditSubjectDialogState extends State<_AddEditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late Set<int> _selectedStudentIds;
  late ClassYear _selectedYear;
  bool _saving = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _descriptionController = TextEditingController(text: widget.subject?.description ?? '');
    _selectedStudentIds = Set<int>.from(widget.subject?.studentIds ?? []);
    _selectedYear = widget.subject?.year ?? ClassYear.firstYear;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    return AlertDialog(
      title: Text(widget.subject == null ? 'Add New Subject' : 'Edit Subject'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g., Mathematics',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a subject name';
                  }
                  return null;
                },
                enabled: !_saving,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ClassYear>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Class Year',
                  hintText: 'Select the class year',
                ),
                items: ClassYear.values.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(_getYearLabel(year)),
                  );
                }).toList(),
                onChanged: _saving ? null : (value) {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter subject description',
                ),
                maxLines: 2,
                enabled: !_saving,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Assign Students', style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: widget.allStudents.length,
                    itemBuilder: (context, index) {
                      final student = widget.allStudents[index];
                      final selected = _selectedStudentIds.contains(student.id);
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(student.fullName.isNotEmpty ? student.fullName[0] : '?'),
                        ),
                        title: Text(student.fullName),
                        subtitle: Text(student.email),
                        trailing: Checkbox(
                          value: selected,
                          onChanged: _saving
                              ? null
                              : (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedStudentIds.add(student.id);
                                    } else {
                                      _selectedStudentIds.remove(student.id);
                                    }
                                  });
                                },
                        ),
                        onTap: _saving
                            ? null
                            : () {
                                setState(() {
                                  if (selected) {
                                    _selectedStudentIds.remove(student.id);
                                  } else {
                                    _selectedStudentIds.add(student.id);
                                  }
                                });
                              },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _saving = true);
                    await Future.delayed(const Duration(milliseconds: 300));
                    Navigator.of(context).pop(_SubjectDialogResult(
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      selectedStudentIds: _selectedStudentIds.toList(),
                      year: _selectedYear,
                    ));
                  }
                },
          child: _saving
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.subject == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
} 