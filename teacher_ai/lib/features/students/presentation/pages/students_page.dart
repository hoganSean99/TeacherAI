import 'package:flutter/material.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';
import 'package:teacher_ai/features/students/data/repositories/student_repository.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'student_summary_page.dart';
import 'package:teacher_ai/core/services/database_service.dart';

class StudentsPage extends ConsumerStatefulWidget {
  final StudentRepository studentRepository;

  const StudentsPage({
    super.key,
    required this.studentRepository,
  });

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  List<Student> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      isLoading = true;
    });
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('No user logged in');
      }
      final loadedStudents = await widget.studentRepository.getStudentsByUserId(currentUser.uuid);
      setState(() {
        students = loadedStudents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  void _showAddOrEditStudentDialog({Student? student}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }
    final resultStudent = await showDialog<Student>(
      context: context,
      builder: (context) => _AddStudentDialog(student: student, currentUser: currentUser),
    );
    if (resultStudent != null) {
      try {
        if (student != null) {
          // Editing
          await widget.studentRepository.updateStudent(resultStudent);
        } else {
          // Adding
          await widget.studentRepository.saveStudent(resultStudent);
        }
        await _loadStudents();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving student: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF8E24AA);
    return Container(
      color: const Color(0xFFF7F8FA), // Apple-style subtle background
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Apple-style glassmorphic header card
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                margin: const EdgeInsets.only(bottom: 32),
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
                'Student Management',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        fontSize: 28,
                ),
              ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.55),
                  foregroundColor: accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shadowColor: accentColor.withOpacity(0.10),
                        elevation: 0,
                ),
                onPressed: () => _showAddOrEditStudentDialog(),
                icon: Icon(Icons.add, color: accentColor),
                      label: const Text('Add Student', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
              ),
            ),
            const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 800;
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.60),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                          child: LayoutBuilder(
                            builder: (context, tableConstraints) {
                              final minTableWidth = 900.0;
                              final tableWidth = tableConstraints.maxWidth < minTableWidth ? minTableWidth : tableConstraints.maxWidth;
                              return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: tableWidth,
                          child: Column(
                            children: [
                              // Table Header
                              Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                                child: Row(
                                  children: [
                                            SizedBox(width: 200, child: _HeaderCell('NAME', apple: true)),
                                            SizedBox(width: 240, child: _HeaderCell('EMAIL', apple: true)),
                                            SizedBox(width: 320, child: _HeaderCell('SUBJECTS', apple: true)),
                                            SizedBox(width: 120, child: _HeaderCell('ATTENDANCE', apple: true)),
                                            SizedBox(width: 110, child: _HeaderCell('GRADE', apple: true)),
                                            SizedBox(width: 100, child: _HeaderCell('ACTIONS', apple: true)),
                                  ],
                                ),
                              ),
                                      Divider(height: 1, color: Colors.grey[200]),
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: CircularProgressIndicator(),
                                )
                              else if (students.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  child: Text('No students yet.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                )
                              else
                                ...students.map((student) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: _StudentRow(
                                    key: ValueKey(student.id),
                                    student: student,
                                    onDelete: () async {
                                      try {
                                        await widget.studentRepository.deleteStudent(student.id);
                                        await _loadStudents();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error deleting student: $e')),
                                          );
                                        }
                                      }
                                    },
                                    onEdit: () => _showAddOrEditStudentDialog(student: student),
                                            showAttendance: true,
                                            showGrade: true,
                                            apple: true,
                                  ),
                                )),
                            ],
                          ),
                                ),
                              );
                            },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        ),
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  final Student? student;
  final dynamic currentUser;
  const _AddStudentDialog({this.student, required this.currentUser});

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectsController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _subjectsError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    if (s != null) {
      _firstNameController.text = s.firstName;
      _lastNameController.text = s.lastName;
      _emailController.text = s.email;
      _subjectsController.text = s.subjects ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _subjectsController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    return parts.take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
  }

  void _submit() {
    setState(() {
      _submitted = true;
      _firstNameError = _firstNameController.text.trim().isEmpty ? 'Enter first name' : null;
      _lastNameError = _lastNameController.text.trim().isEmpty ? 'Enter last name' : null;
      _emailError = _emailController.text.trim().isEmpty ? 'Enter an email' : null;
      _subjectsError = _subjectsController.text.trim().isEmpty ? 'Enter at least one subject' : null;
    });
    if (_formKey.currentState?.validate() ?? false && _firstNameError == null && _lastNameError == null && _emailError == null && _subjectsError == null) {
      if (widget.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        return;
      }
      Navigator.of(context).pop(Student(
        id: widget.student?.id ?? Isar.autoIncrement,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        userId: widget.currentUser.uuid,
        subjects: _subjectsController.text.trim(),
        dateOfBirth: widget.student?.dateOfBirth,
        phoneNumber: widget.student?.phoneNumber,
        address: widget.student?.address,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF8E24AA);
    return Dialog(
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
                        child: Text(
                          _getInitials(_firstNameController.text + ' ' + _lastNameController.text),
                          style: TextStyle(fontSize: 28, color: accentColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.student == null ? 'Add New Student' : 'Update Student',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        widget.student == null
                          ? 'Fill in the details below to add a student.'
                          : 'Update the details below and save changes.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Divider(height: 1, color: Colors.grey[300]),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorText: _submitted ? _firstNameError : null,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorText: _submitted ? _lastNameError : null,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: _submitted ? _emailError : null,
                    prefixIcon: const Icon(Icons.email_outlined),
                    helperText: "Student's school email address",
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjectsController,
                  decoration: InputDecoration(
                    labelText: 'Subjects',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: _submitted ? _subjectsError : null,
                    prefixIcon: const Icon(Icons.book_outlined),
                    helperText: 'Separate multiple subjects with commas',
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
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
                      onPressed: _submit,
                      child: Text(
                        widget.student == null ? 'Add Student' : 'Update Student',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final bool apple;
  const _HeaderCell(this.label, {this.apple = false});
  @override
  Widget build(BuildContext context) {
    final isCenter = label == 'ATTENDANCE' || label == 'GRADE' || label == 'ACTIONS';
    return Text(
        label,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: apple
          ? Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.75),
              letterSpacing: label == 'ATTENDANCE' ? 0.2 : 1.1,
              fontSize: label == 'ATTENDANCE' ? 15 : 16,
            )
          : Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 1.05,
      ),
    );
  }
}

class _StudentRow extends StatefulWidget {
  final Student student;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool showAttendance;
  final bool showGrade;
  final bool apple;
  const _StudentRow({Key? key, required this.student, required this.onDelete, required this.onEdit, this.showAttendance = true, this.showGrade = true, this.apple = false}) : super(key: key);
  @override
  State<_StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<_StudentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final accentColor = const Color(0xFF8E24AA);
    return InkWell(
      borderRadius: BorderRadius.circular(widget.apple ? 22 : 12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StudentSummaryPage(studentId: student.id),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.apple
              ? (_hovered ? Colors.white.withOpacity(0.82) : Colors.white.withOpacity(0.68))
              : (_hovered ? Theme.of(context).colorScheme.primary.withOpacity(0.07) : Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(widget.apple ? 22 : 12),
          boxShadow: widget.apple
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(_hovered ? 0.09 : 0.04),
                    blurRadius: _hovered ? 18 : 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : (_hovered
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                  : []),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.apple ? 28 : 18, vertical: widget.apple ? 20 : 14),
          child: Row(
            children: [
              // Name + Avatar
              SizedBox(
                width: 200,
                  child: Row(
                    children: [
                      CircleAvatar(
                      radius: widget.apple ? 22 : 16,
                      backgroundColor: widget.apple ? accentColor.withOpacity(0.10) : accentColor.withOpacity(0.08),
                        child: Text(
                          student.fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join(),
                          style: TextStyle(
                          color: Colors.black87,
                          fontSize: widget.apple ? 16 : 12,
                            fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                      Flexible(
                        child: Text(
                          student.fullName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: widget.apple ? 16 : null,
                          letterSpacing: widget.apple ? -0.2 : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                ),
              ),
              // Email
              SizedBox(
                width: 240,
                child: Text(
                  student.email,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              // Subjects
              SizedBox(
                width: 320,
                height: 44,
                child: FutureBuilder<List<String>>(
                  future: _fetchAssignedSubjects(student.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    final subjects = snapshot.data ?? [];
                    if (subjects.isEmpty) {
                      return Text('—', style: TextStyle(color: Colors.grey[500]));
                    }
                    final maxChips = 2;
                    final showMore = subjects.length > maxChips;
                    final chipsToShow = showMore ? subjects.take(maxChips).toList() : subjects;
                    final subjectList = subjects.join(', ');
                    return Tooltip(
                      message: subjectList,
                      child: ClipRect(
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white,
                                Colors.white,
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: [0.0, 0.85, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ...chipsToShow.map((subject) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.grey.withOpacity(0.13)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                child: Text(
                                  subject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black87,
                                    letterSpacing: -0.2,
                                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                              )),
                              if (showMore)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.grey.withOpacity(0.13)),
                                  ),
                                  child: Text(
                                    '+${subjects.length - maxChips} more',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.black54,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Attendance
                SizedBox(
                width: 120,
                  child: Text(
                    '—',
                  textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                ),
              ),
              // Grade
                SizedBox(
                width: 110,
                  child: Text(
                    '—',
                  textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: 'Edit',
                      child: IconButton(
                        icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                        onPressed: widget.onEdit,
                        splashRadius: 20,
                      ),
                    ),
                    Tooltip(
                      message: 'Delete',
                      child: IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                        onPressed: widget.onDelete,
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _fetchAssignedSubjects(int studentId) async {
    final allSubjects = await DatabaseService.subjects.where().findAll();
    final assigned = allSubjects.where((s) => s.studentIds.contains(studentId)).toList();
    return assigned.map((s) => s.name).toList();
  }
} 