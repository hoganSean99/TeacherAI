import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'package:teacher_ai/features/auth/presentation/pages/login_page.dart';
import 'package:teacher_ai/features/auth/presentation/pages/register_page.dart';
import 'package:teacher_ai/features/home/presentation/pages/home_page.dart';
import 'package:teacher_ai/features/subjects/presentation/pages/subject_details_page.dart';
import 'package:teacher_ai/features/subjects/presentation/pages/subjects_page.dart';
import 'package:teacher_ai/features/students/presentation/pages/students_page.dart';
import 'package:teacher_ai/features/home/presentation/pages/calendar_page.dart';
import 'package:teacher_ai/features/home/presentation/pages/settings_page.dart';
import 'package:teacher_ai/features/students/data/repositories/student_repository.dart';
import 'package:isar/isar.dart';
import 'package:teacher_ai/features/attendance/presentation/pages/attendance_page.dart';
import 'package:teacher_ai/features/exams/presentation/pages/exams_page.dart';
import 'package:teacher_ai/features/home/presentation/pages/clear_data_page.dart';

final goRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final authService = ProviderScope.containerOf(context).read(authServiceProvider);
        return LoginPage(authService: authService);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final authService = ProviderScope.containerOf(context).read(authServiceProvider);
        return RegisterPage(authService: authService);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => HomePage(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardContent(),
        ),
        GoRoute(
          path: '/subjects',
          builder: (context, state) => const SubjectsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => SubjectDetailsPage(
                subjectId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/students',
          builder: (context, state) => StudentsPage(
            studentRepository: StudentRepository(Isar.getInstance()!),
          ),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/attendance',
          builder: (context, state) => const AttendancePage(),
        ),
        GoRoute(
          path: '/exams',
          builder: (context, state) => const ExamsPage(),
        ),
        GoRoute(
          path: '/test-clear-data',
          builder: (context, state) => const ClearDataPage(),
        ),
      ],
    ),
  ],
); 