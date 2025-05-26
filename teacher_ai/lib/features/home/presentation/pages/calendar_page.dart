import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  final List<_Event> _events = [
    _Event('Mathematics Class', DateTime.now(), 'Class', Colors.blue),
    _Event('Science Exam', DateTime.now().add(const Duration(days: 1, hours: 1)), 'Exam', Colors.red),
    _Event('Parent-Teacher Meeting', DateTime.now().add(const Duration(days: 2)), 'Meeting', Colors.amber),
  ];
  final _titleController = TextEditingController();
  DateTime? _newEventDate;
  String _newEventType = 'Class';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF7B1FA2);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Month View
              Expanded(
                flex: 2,
                child: _CalendarMonthView(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) => setState(() => _selectedDate = date),
                  events: _events,
                ),
              ),
              const SizedBox(width: 32),
              // Upcoming Events and Add Event
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _CalendarCard(
                      title: 'Upcoming Events',
                      child: Column(
                        children: _events
                            .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                            .map((e) => ListTile(
                                  leading: Container(
                                    width: 10,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: e.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  title: Text(e.title),
                                  subtitle: Text(DateFormat('EEEE, h:mm a').format(e.date)),
                                  trailing: Text(e.type),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _CalendarCard(
                      title: 'Add New Event',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Event Title',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Date & Time',
                                    hintText: 'dd/mm/yyyy --:--',
                                    suffixIcon: Icon(Icons.calendar_today, color: accentColor),
                                  ),
                                  controller: TextEditingController(
                                    text: _newEventDate == null
                                        ? ''
                                        : DateFormat('dd/MM/yyyy h:mm a').format(_newEventDate!),
                                  ),
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (date != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _newEventDate = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _newEventType,
                                  items: const [
                                    DropdownMenuItem(value: 'Class', child: Text('Class')),
                                    DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                                    DropdownMenuItem(value: 'Meeting', child: Text('Meeting')),
                                  ],
                                  onChanged: (v) => setState(() => _newEventType = v ?? 'Class'),
                                  decoration: const InputDecoration(labelText: 'Event Type'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                if (_titleController.text.isNotEmpty && _newEventDate != null) {
                                  setState(() {
                                    _events.add(_Event(
                                      _titleController.text,
                                      _newEventDate!,
                                      _newEventType,
                                      _newEventType == 'Class'
                                          ? Colors.blue
                                          : _newEventType == 'Exam'
                                              ? Colors.red
                                              : Colors.amber,
                                    ));
                                    _titleController.clear();
                                    _newEventDate = null;
                                    _newEventType = 'Class';
                                  });
                                }
                              },
                              child: const Text('Add Event'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarMonthView extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final List<_Event> events;
  const _CalendarMonthView({required this.selectedDate, required this.onDateSelected, required this.events});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final accentColor = const Color(0xFF7B1FA2);
    final accentColor2 = const Color(0xFFE040FB);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(DateFormat('MMMM yyyy').format(selectedDate), style: Theme.of(context).textTheme.titleLarge),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) =>
                Text(DateFormat.E().format(DateTime(2020, 1, i + 5)), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                      final hasEvent = events.any((e) => e.date.year == date.year && e.date.month == date.month && e.date.day == date.day);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onDateSelected(date),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor
                                  : isToday
                                      ? accentColor2.withOpacity(0.15)
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
                                  ),
                                ),
                                if (hasEvent)
                                  Positioned(
                                    bottom: 6,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: accentColor2,
                                        shape: BoxShape.circle,
                                      ),
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

class _CalendarCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _CalendarCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Event {
  final String title;
  final DateTime date;
  final String type;
  final Color color;
  _Event(this.title, this.date, this.type, this.color);
} 