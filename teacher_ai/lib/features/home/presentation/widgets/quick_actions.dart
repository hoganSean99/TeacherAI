import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _QuickActionCard(
              icon: Icons.person_add,
              label: 'Add Student',
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                // TODO: Implement add student
              },
            ),
            const SizedBox(width: 16),
            _QuickActionCard(
              icon: Icons.class_,
              label: 'New Subject',
              color: Theme.of(context).colorScheme.secondary,
              onTap: () {
                // TODO: Implement add subject
              },
            ),
            const SizedBox(width: 16),
            _QuickActionCard(
              icon: Icons.event_note,
              label: 'Take Attendance',
              color: Theme.of(context).colorScheme.tertiary,
              onTap: () {
                // TODO: Implement attendance
              },
            ),
            const SizedBox(width: 16),
            _QuickActionCard(
              icon: Icons.assignment,
              label: 'Assign Homework',
              color: Theme.of(context).colorScheme.error,
              onTap: () {
                // TODO: Implement homework assignment
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 