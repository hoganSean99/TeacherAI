import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher_ai/features/home/presentation/widgets/dashboard_calendar.dart';
import 'package:teacher_ai/features/home/presentation/widgets/quick_actions.dart';
import 'package:teacher_ai/features/home/presentation/widgets/subjects_overview.dart';
import 'package:teacher_ai/features/home/presentation/widgets/sidebar_navigation.dart';
import 'package:teacher_ai/features/ai_chat/presentation/widgets/ai_chat_wrapper.dart';

class HomePage extends StatelessWidget {
  final Widget child;

  const HomePage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AIChatWrapper(
      child: Scaffold(
        body: Row(
          children: [
            SidebarNavigation(
              selectedIndex: _getSelectedIndex(context),
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/dashboard');
                    break;
                  case 1:
                    context.go('/students');
                    break;
                  case 2:
                    context.go('/subjects');
                    break;
                  case 3:
                    context.go('/attendance');
                    break;
                  case 4:
                    context.go('/exams');
                    break;
                  case 5:
                    context.go('/calendar');
                    break;
                  case 6:
                    context.go('/settings');
                    break;
                  case 7:
                    context.go('/test-clear-data');
                    break;
                }
              },
            ),
            // Main Content
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    // App Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            _getPageTitle(context),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 260,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                prefixIcon: Icon(Icons.search),
                                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                    // Page Content
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/students')) return 1;
    if (location.startsWith('/subjects')) return 2;
    if (location.startsWith('/attendance')) return 3;
    if (location.startsWith('/exams')) return 4;
    if (location.startsWith('/calendar')) return 5;
    if (location.startsWith('/settings')) return 6;
    if (location.startsWith('/test-clear-data')) return 7;
    return 0;
  }

  String _getPageTitle(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/students')) return 'Students';
    if (location.startsWith('/subjects')) return 'Subjects';
    if (location.startsWith('/attendance')) return 'Attendance';
    if (location.startsWith('/exams')) return 'Exams';
    if (location.startsWith('/calendar')) return 'Calendar';
    if (location.startsWith('/settings')) return 'Settings';
    return 'Dashboard';
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final accentColor = const Color(0xFF7B1FA2);
    final accentColor2 = const Color(0xFFE040FB);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DashboardStatCard(
                title: 'Total Students',
                value: '128',
                subtitle: '↑ 4.3% from last month',
                icon: Icons.people,
                iconBg: accentColor,
                valueColor: accentColor,
              ),
              const SizedBox(width: 24),
              _DashboardStatCard(
                title: 'Average Attendance',
                value: '92%',
                subtitle: '↑ 1.2% from last week',
                icon: Icons.check_circle,
                iconBg: Colors.green,
                valueColor: Colors.green,
              ),
              const SizedBox(width: 24),
              _DashboardStatCard(
                title: 'Upcoming Exams',
                value: '5',
                subtitle: 'Next: Science (Tomorrow)',
                icon: Icons.description,
                iconBg: accentColor2,
                valueColor: accentColor2,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Students
              Expanded(
                child: _DashboardCard(
                  title: 'Recent Students',
                  action: TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                  child: Column(
                    children: const [
                      _StudentListTile(
                        name: 'Emma Thompson',
                        subjects: 'Mathematics, Science',
                        grade: 'A',
                        attendance: '95%',
                      ),
                      _StudentListTile(
                        name: 'James Wilson',
                        subjects: 'English, History',
                        grade: 'B+',
                        attendance: '88%',
                      ),
                      _StudentListTile(
                        name: 'Sophia Chen',
                        subjects: 'Science, Art',
                        grade: 'A-',
                        attendance: '92%',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Upcoming Schedule
              Expanded(
                child: _DashboardCard(
                  title: 'Upcoming Schedule',
                  action: TextButton(
                    onPressed: () {},
                    child: const Text('View Calendar'),
                  ),
                  child: Column(
                    children: const [
                      _ScheduleListTile(
                        color: Colors.blue,
                        title: 'Mathematics Class',
                        subtitle: 'Today, 10:00 AM',
                      ),
                      _ScheduleListTile(
                        color: Colors.red,
                        title: 'Science Exam',
                        subtitle: 'Tomorrow, 11:30 AM',
                      ),
                      _ScheduleListTile(
                        color: Colors.amber,
                        title: 'Parent-Teacher Meeting',
                        subtitle: 'Friday, 3:00 PM',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Subject Overview and Add Subject
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DashboardCard(
                  title: 'Subject Overview',
                  child: const SubjectsOverview(),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color valueColor;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: iconBg, size: 32),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _DashboardCard({
    required this.title,
    required this.child,
    this.action,
  });

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
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final String name;
  final String subjects;
  final String grade;
  final String attendance;

  const _StudentListTile({
    required this.name,
    required this.subjects,
    required this.grade,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(name, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subjects),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(grade, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('$attendance attendance', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ScheduleListTile extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;

  const _ScheduleListTile({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 10,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle),
    );
  }
} 