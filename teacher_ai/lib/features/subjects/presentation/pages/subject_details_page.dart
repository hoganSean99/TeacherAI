import 'package:flutter/material.dart';

class SubjectDetailsPage extends StatelessWidget {
  final String subjectId;

  const SubjectDetailsPage({
    super.key,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Subject Details Page - ID: $subjectId'),
      ),
    );
  }
} 