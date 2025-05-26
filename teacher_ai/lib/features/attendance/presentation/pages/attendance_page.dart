import 'package:flutter/material.dart';
import 'package:teacher_ai/features/subjects/data/subject_repository.dart';
import 'package:teacher_ai/features/students/data/repositories/student_repository.dart';
import 'package:teacher_ai/features/core/domain/models/subject.dart';
import 'package:teacher_ai/features/core/domain/models/student.dart';
import 'package:teacher_ai/features/core/domain/models/attendance.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  List<Subject> subjects = [];
  List<Student> students = [];
  Subject? selectedSubject;
  Map<int, AttendanceStatus> attendance = {};
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjects();
    });
  }

  Future<void> _loadSubjects() async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    try {
      final isar = DatabaseService.instance;
      final subjectRepo = SubjectRepository(isar);
      final currentUser = ref.read(currentUserProvider);
      
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in')),
          );
        }
        return;
      }

      final userSubjects = await subjectRepo.getSubjectsByUserId(currentUser.uuid);
      if (mounted) {
        setState(() {
          subjects = userSubjects;
          isLoading = false;
        });
      }
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _loadStudentsForSubject(Subject subject, {DateTime? forDate}) async {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      if (mounted) {
        setState(() {
          selectedSubject = subject;
          isLoading = true;
          students = [];
          attendance = {};
        });
      }

      final isar = DatabaseService.instance;
      final studentRepo = StudentRepository(isar);
      final allStudents = await studentRepo.getAllStudents();
      final subjectStudents = allStudents.where((s) => subject.studentIds.contains(s.id)).toList();
      
      final date = forDate ?? selectedDate;
      final records = await isar.attendances
        .filter()
        .subjectIdEqualTo(subject.id)
        .and()
        .dateEqualTo(DateTime(date.year, date.month, date.day))
        .findAll();

      final Map<int, AttendanceStatus> loadedAttendance = {};
      for (final s in subjectStudents) {
        final record = records.firstWhere(
          (a) => a.studentId == s.id,
          orElse: () => Attendance(
            studentId: s.id,
            subjectId: subject.id,
            status: AttendanceStatus.present,
            date: DateTime(date.year, date.month, date.day),
          ),
        );
        loadedAttendance[s.id] = record.status;
      }

      if (mounted) {
        setState(() {
          students = subjectStudents;
          attendance = loadedAttendance;
          isLoading = false;
        });
      }
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _pickDate() async {
    if (_isUpdating) return;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate && mounted) {
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      
      if (selectedSubject != null) {
        await _loadStudentsForSubject(selectedSubject!, forDate: picked);
      } else {
        setState(() { isLoading = false; });
      }
    }
  }

  Future<void> _saveAttendance() async {
    if (_isUpdating || selectedSubject == null) return;
    _isUpdating = true;

    try {
      final isar = DatabaseService.instance;
      final date = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      
      await isar.writeTxn(() async {
        for (final entry in attendance.entries) {
          final existing = await isar.attendances
            .filter()
            .studentIdEqualTo(entry.key)
            .and()
            .subjectIdEqualTo(selectedSubject!.id)
            .and()
            .dateEqualTo(date)
            .findFirst();
            
          if (existing != null) {
            await isar.attendances.delete(existing.id);
          }
          
          await isar.attendances.put(Attendance(
            studentId: entry.key,
            subjectId: selectedSubject!.id,
            status: entry.value,
            date: date,
          ));
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved!')),
        );
      }
    } finally {
      _isUpdating = false;
    }
  }

  void _updateAttendance(int studentId, AttendanceStatus status) {
    if (_isUpdating) return;
    setState(() {
      attendance[studentId] = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glassColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    Map<AttendanceStatus, int> summary = {
      for (var status in AttendanceStatus.values) status: 0
    };
    attendance.forEach((_, status) => summary[status] = (summary[status] ?? 0) + 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Take Attendance')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            elevation: 8,
                            color: glassColor.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: borderColor.withOpacity(0.18), width: 1.2),
                            ),
                            shadowColor: Colors.black.withOpacity(0.08),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.13),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: const Icon(Icons.class_, size: 28, color: Colors.teal),
                                  ),
                                  const SizedBox(width: 22),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Subject>(
                                        value: selectedSubject,
                                        hint: const Text('Select a class'),
                                        isExpanded: true,
                                        borderRadius: BorderRadius.circular(16),
                                        items: subjects.map((subject) {
                                          return DropdownMenuItem(
                                            value: subject,
                                            child: Text(
                                              subject.name,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (subject) {
                                          if (subject != null) {
                                            _loadStudentsForSubject(subject, forDate: selectedDate);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  OutlinedButton.icon(
                                    onPressed: _isUpdating ? null : _pickDate,
                                    icon: const Icon(Icons.calendar_today, size: 22, color: Colors.teal),
                                    label: Text(
                                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)
                                      ),
                                      side: BorderSide(color: Colors.teal.withOpacity(0.18)),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16
                                      ),
                                      backgroundColor: Colors.white.withOpacity(0.18),
                                      foregroundColor: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (selectedSubject != null && students.isNotEmpty) ...[
                            Card(
                              elevation: 6,
                              color: glassColor.withOpacity(0.97),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: borderColor.withOpacity(0.13), width: 1),
                              ),
                              shadowColor: Colors.black.withOpacity(0.06),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: AttendanceStatus.values.map((status) {
                                    final color = _statusColor(status, theme);
                                    final icon = _statusIcon(status);
                                    return Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.18),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(icon, color: color, size: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${summary[status] ?? 0}',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                            fontSize: 18
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _statusLabel(status),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface.withOpacity(0.7)
                                          ),
                                        ),
                                        const SizedBox(width: 22),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final student = students[index];
                                final status = attendance[student.id] ?? AttendanceStatus.present;
                                final statusColor = _statusColor(status, theme);
                                final statusIcon = _statusIcon(status);
                                
                                return Card(
                                  elevation: 6,
                                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                  color: glassColor.withOpacity(0.95),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: borderColor.withOpacity(0.18), width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundColor: Colors.teal.withOpacity(0.10),
                                              child: Text(
                                                student.fullName.isNotEmpty ? student.fullName[0] : '?',
                                                style: theme.textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.95),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: statusColor.withOpacity(0.4),
                                                      blurRadius: 6,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(3),
                                                child: Icon(statusIcon, color: Colors.white, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 22),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.fullName,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                student.email,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurface.withOpacity(0.6)
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 10),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: SizedBox(
                                                  height: 36,
                                                  child: _StatusSelector(
                                                    value: status,
                                                    onChanged: (newStatus) => _updateAttendance(
                                                      student.id,
                                                      newStatus
                                                    ),
                                                    small: false,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 32.0, bottom: 16),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.teal.withOpacity(0.18),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: _isUpdating ? null : _saveAttendance,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 44,
                                          vertical: 18
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.save_rounded,
                                              color: Colors.white,
                                              size: 26
                                            ),
                                            const SizedBox(width: 14),
                                            Text(
                                              'Save Attendance',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (selectedSubject != null && students.isEmpty)
                            Center(
                              child: Card(
                                elevation: 6,
                                color: glassColor.withOpacity(0.97),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(color: borderColor.withOpacity(0.13), width: 1),
                                ),
                                shadowColor: Colors.black.withOpacity(0.06),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.group_off_rounded,
                                        size: 64,
                                        color: Colors.teal.withOpacity(0.22)
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'No students assigned',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface.withOpacity(0.8)
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'This class currently has no students. Add students to start taking attendance!',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.6)
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (selectedSubject == null)
                            Center(
                              child: Card(
                                elevation: 6,
                                color: glassColor.withOpacity(0.97),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(color: borderColor.withOpacity(0.13), width: 1),
                                ),
                                shadowColor: Colors.black.withOpacity(0.06),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.class_,
                                        size: 64,
                                        color: Colors.teal.withOpacity(0.22)
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'Select a class',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface.withOpacity(0.8)
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Choose a class from the dropdown above to view or take attendance.',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.6)
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Color _statusColor(AttendanceStatus status, ThemeData theme) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFFB9F6CA);
      case AttendanceStatus.absent:
        return const Color(0xFFFFCDD2);
      case AttendanceStatus.late:
        return const Color(0xFFFFE0B2);
      case AttendanceStatus.excused:
        return const Color(0xFFB3E5FC);
    }
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  IconData _statusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.excused:
        return Icons.info;
    }
  }
}

class _StatusSelector extends StatelessWidget {
  final AttendanceStatus value;
  final ValueChanged<AttendanceStatus> onChanged;
  final bool small;

  const _StatusSelector({
    required this.value,
    required this.onChanged,
    this.small = false,
  });

  static const double _chipWidth = 90;
  static const double _chipWidthSmall = 68;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AttendanceStatus.values.map((status) {
        final selected = value == status;
        final color = _statusColor(status, theme);
        final borderColor = color.withOpacity(0.7);
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: small ? 2.0 : 4.0),
          child: SizedBox(
            width: small ? _chipWidthSmall : _chipWidth,
            height: small ? 28 : null,
            child: ChoiceChip(
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                child: Text(
                  _statusLabel(status),
                  key: ValueKey(selected),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.black87,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              selected: selected,
              selectedColor: color.withOpacity(0.85),
              backgroundColor: color.withOpacity(0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(small ? 8 : 12),
                side: BorderSide(
                  color: borderColor,
                  width: selected ? 1.5 : 1
                ),
              ),
              onSelected: (_) => onChanged(status),
              labelPadding: EdgeInsets.symmetric(
                horizontal: small ? 0 : 4,
                vertical: small ? 0 : 4
              ),
              elevation: selected ? 1 : 0,
              shadowColor: color.withOpacity(0.12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(AttendanceStatus status, ThemeData theme) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFFB9F6CA);
      case AttendanceStatus.absent:
        return const Color(0xFFFFCDD2);
      case AttendanceStatus.late:
        return const Color(0xFFFFE0B2);
      case AttendanceStatus.excused:
        return const Color(0xFFB3E5FC);
    }
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }
} 