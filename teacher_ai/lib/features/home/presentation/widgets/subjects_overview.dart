import 'package:flutter/material.dart';

class SubjectsOverview extends StatelessWidget {
  const SubjectsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subjects Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                  onPressed: () {
                    // TODO: Implement add subject
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sample subjects - will be replaced with actual data
            _SubjectCard(
              name: 'Mathematics',
              grade: 'Grade 10',
              studentCount: 25,
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                // TODO: Navigate to subject details
              },
            ),
            const SizedBox(height: 8),
            _SubjectCard(
              name: 'Physics',
              grade: 'Grade 11',
              studentCount: 20,
              color: Theme.of(context).colorScheme.secondary,
              onTap: () {
                // TODO: Navigate to subject details
              },
            ),
            const SizedBox(height: 8),
            _SubjectCard(
              name: 'Chemistry',
              grade: 'Grade 10',
              studentCount: 22,
              color: Theme.of(context).colorScheme.tertiary,
              onTap: () {
                // TODO: Navigate to subject details
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String name;
  final String grade;
  final int studentCount;
  final Color color;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.name,
    required this.grade,
    required this.studentCount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        grade,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      studentCount.toString(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              const SizedBox(height: 8),
              Text(
                'Next class: Today, 10:30 AM',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 