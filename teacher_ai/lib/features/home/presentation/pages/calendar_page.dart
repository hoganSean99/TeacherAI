import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teacher_ai/features/exams/domain/models/exam.dart';
import 'package:teacher_ai/features/exams/data/exam_repository.dart';
import 'package:teacher_ai/features/core/domain/models/attendance.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../domain/models/custom_event.dart';
import '../../data/custom_event_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

final calendarEventsProvider = StateProvider<List<_CalendarEvent>>((ref) => []);

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  bool isLoading = true;
  final _titleController = TextEditingController();
  DateTime? _newEventDate;
  String _newEventType = 'Class';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final isar = DatabaseService.instance;
    final examRepo = ExamRepository(isar);
    final user = ref.read(currentUserProvider);
    final userId = user?.uuid;
    print('Current userId: $userId');
    
    if (userId == null) return;
    
    // Load exams
    final exams = await examRepo.getExamsByUserId(userId);
    print('Loaded exams: ' + exams.map((e) => '${e.name} on ${e.date} (userId: ${e.userId})').toList().toString());
    
    // DEBUG: Print all exams in the database
    final allExams = await DatabaseService.instance.exams.where().findAll();
    print('ALL exams in DB: ' + allExams.map((e) => '${e.name} on ${e.date} (userId: ${e.userId})').toList().toString());
    
    // Load attendance records
    final attendanceRecords = await DatabaseService.attendance
        .filter()
        .dateGreaterThan(DateTime.now().subtract(const Duration(days: 30)))
        .findAll();

    // Convert to calendar events
    final events = <_CalendarEvent>[];
    
    // Add exams
    for (final exam in exams) {
      events.add(_CalendarEvent(
        exam.name,
        exam.date,
        'Exam',
        const Color(0xFF007AFF), // Apple blue
        exam.className,
      ));
    }

    // Load custom events
    final customEventRepo = CustomEventRepository(isar);
    final customEvents = await customEventRepo.getEventsByUserId(userId);
    for (final custom in customEvents) {
      events.add(_CalendarEvent(
        custom.title,
        custom.date,
        custom.type,
        Color(custom.color),
        custom.className ?? '',
      ));
    }

    // Group attendance records by subject and date
    final Map<String, Attendance> uniqueAttendance = {};
    for (final record in attendanceRecords) {
      final key = '${record.subjectId}_${record.date.year}-${record.date.month}-${record.date.day}';
      if (!uniqueAttendance.containsKey(key)) {
        uniqueAttendance[key] = record;
      }
    }

    // Add attendance events (one per subject per day)
    for (final record in uniqueAttendance.values) {
      final subject = await DatabaseService.subjects.get(record.subjectId as int);
      if (subject != null) {
        events.add(_CalendarEvent(
          '${subject.name} Attendance',
          record.date,
          'Attendance',
          const Color(0xFF34C759), // Apple green
          subject.name,
        ));
      }
    }

    // Remove duplicates based on title, date, type, and className
    final uniqueEvents = <String, _CalendarEvent>{};
    for (final event in events) {
      final key = '${event.title}_${event.date.toIso8601String()}_${event.type}_${event.className}';
      uniqueEvents[key] = event;
    }
    ref.read(calendarEventsProvider.notifier).state = uniqueEvents.values.toList();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(calendarEventsProvider);
    final accentColor = const Color(0xFF007AFF); // Apple blue
    final backgroundGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF6F8FF), Color(0xFFE9ECF5)],
    );
    final today = DateTime.now();
    final isWide = MediaQuery.of(context).size.width > 900;
    
    return Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calendar',
                                  style: GoogleFonts.inter(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1.2,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your schedule at a glance',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        'Today: ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.inter(
                                          color: accentColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GlassButton(
                            icon: Icons.add,
                            label: 'Add Event',
                            color: accentColor,
                            onTap: () => _showAddEventDialog(context, accentColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Main Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Calendar Month View
                                Expanded(
                                  flex: 2,
                                  child: GlassCard(
                                    child: _CalendarMonthView(
                                      selectedDate: _selectedDate,
                                      onDateSelected: (date) => setState(() => _selectedDate = date),
                                      events: events,
                                    ),
                                  ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
                                ),
                                const SizedBox(width: 40),
                                // Events Column
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      GlassCard(
                                        child: _UpcomingEventsCard(
                                          events: events,
                                          selectedDate: _selectedDate,
                                        ),
                                      ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOut),
                                      const SizedBox(height: 32),
                                      GlassCard(
                                        child: _UpcomingEventsNextDaysCard(events: events, selectedDate: _selectedDate),
                                      ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                GlassCard(
                                  child: _CalendarMonthView(
                                    selectedDate: _selectedDate,
                                    onDateSelected: (date) => setState(() => _selectedDate = date),
                                    events: events,
                                  ),
                                ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
                                const SizedBox(height: 32),
                                GlassCard(
                                  child: _UpcomingEventsCard(
                                    events: events,
                                    selectedDate: _selectedDate,
                                  ),
                                ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOut),
                                const SizedBox(height: 32),
                                GlassCard(
                                  child: _UpcomingEventsNextDaysCard(events: events, selectedDate: _selectedDate),
                                ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _showAddEventDialog(BuildContext context, Color accentColor) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user logged in')));
      return;
    }
    final _formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final classController = TextEditingController();
    DateTime selectedDate = _selectedDate;
    String selectedType = 'Custom';
    Color selectedColor = const Color(0xFF007AFF);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Custom Event'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Event Title'),
                        validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: classController,
                        decoration: const InputDecoration(labelText: 'Class Name (optional)'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                          DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                          DropdownMenuItem(value: 'Attendance', child: Text('Attendance')),
                        ],
                        onChanged: (v) => setState(() => selectedType = v ?? 'Custom'),
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                        trailing: Icon(Icons.calendar_today, color: accentColor),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => selectedDate = picked);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Marker Color:'),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              Color tempColor = selectedColor;
                              await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Pick a color'),
                                    content: SingleChildScrollView(
                                      child: ColorPicker(
                                        pickerColor: tempColor,
                                        onColorChanged: (c) => tempColor = c,
                                        showLabel: false,
                                        pickerAreaHeightPercent: 0.7,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      ElevatedButton(
                                        child: const Text('Select'),
                                        onPressed: () {
                                          setState(() => selectedColor = tempColor);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: selectedColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[400]!, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() => saving = true);
                            final repo = CustomEventRepository(DatabaseService.instance);
                            final event = CustomEvent.create(
                              title: titleController.text,
                              date: selectedDate,
                              type: selectedType,
                              color: selectedColor.value,
                              className: classController.text.isNotEmpty ? classController.text : null,
                              userId: user.uuid,
                            );
                            await repo.addEvent(event);
                            Navigator.of(context).pop();
                            await _loadData();
                          }
                        },
                  child: saving ? const CircularProgressIndicator() : const Text('Add Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CalendarMonthView extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final List<_CalendarEvent> events;
  const _CalendarMonthView({
    required this.selectedDate,
    required this.onDateSelected,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final accentColor = const Color(0xFF007AFF); // Apple blue

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => onDateSelected(DateTime(selectedDate.year, selectedDate.month - 1, 1)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => onDateSelected(DateTime(selectedDate.year, selectedDate.month + 1, 1)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) => Text(
                DateFormat.E().format(DateTime(2020, 1, i + 5)),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              )),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            Column(
              children: List.generate(
                ((daysInMonth + firstWeekday - 1) / 7).ceil(),
                (week) {
                  return Row(
                    children: List.generate(7, (weekday) {
                      final day = week * 7 + weekday - (firstWeekday - 1) + 1;
                      if (day < 1 || day > daysInMonth) {
                        return Expanded(child: Container());
                      }
                      final date = DateTime(selectedDate.year, selectedDate.month, day);
                      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                      final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
                      final dayEvents = events.where((e) => 
                        e.date.year == date.year && 
                        e.date.month == date.month && 
                        e.date.day == date.day
                      ).toList();
                      
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onDateSelected(date),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor
                                  : isToday
                                      ? accentColor.withOpacity(0.1)
                                      : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            height: 38,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                                if (dayEvents.isNotEmpty)
                                  Positioned(
                                    bottom: 4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: dayEvents.map((e) => Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: e.color,
                                          shape: BoxShape.circle,
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEventsCard extends StatelessWidget {
  final List<_CalendarEvent> events;
  final DateTime selectedDate;
  
  const _UpcomingEventsCard({
    required this.events,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final selectedEvents = events.where((e) => 
      e.date.year == selectedDate.year && 
      e.date.month == selectedDate.month && 
      e.date.day == selectedDate.day
    ).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events for ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 16),
            if (selectedEvents.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No events',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedEvents.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final event = selectedEvents[index];
                  return Row(
                    children: [
                      Container(
                        width: 3,
                        height: 36,
                        decoration: BoxDecoration(
                          color: event.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${event.type} • ${event.className}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEventsNextDaysCard extends StatelessWidget {
  final List<_CalendarEvent> events;
  final DateTime selectedDate;
  const _UpcomingEventsNextDaysCard({required this.events, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDays = List.generate(5, (i) => today.add(Duration(days: i + 1)));
    final nextEvents = events.where((e) {
      final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
      return nextDays.contains(eventDate);
    }).toList();
    nextEvents.sort((a, b) => a.date.compareTo(b.date));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Events (Next 5 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 16),
            if (nextEvents.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming events',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nextEvents.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final event = nextEvents[index];
                  return Row(
                    children: [
                      Container(
                        width: 3,
                        height: 36,
                        decoration: BoxDecoration(
                          color: event.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${event.type} • ${event.className}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}-${event.date.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarEvent {
  final String title;
  final DateTime date;
  final String type;
  final Color color;
  final String className;

  _CalendarEvent(this.title, this.date, this.type, this.color, this.className);
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: child,
    );
  }
}

class GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const GlassButton({required this.icon, required this.label, required this.color, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.18), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 