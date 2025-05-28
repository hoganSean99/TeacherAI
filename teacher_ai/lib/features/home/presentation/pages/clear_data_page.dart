import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:teacher_ai/core/providers/providers.dart';

class ClearDataPage extends ConsumerWidget {
  const ClearDataPage({super.key});

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    // Clear all user data
    await DatabaseService.clearUserData();

    // Clear current user's details
    final user = ref.read(currentUserProvider);
    if (user != null) {
      user.email = '';
      user.password = '';
      user.firstName = '';
      user.lastName = '';
      user.title = '';
      await DatabaseService.instance.writeTxn(() async {
        await DatabaseService.users.put(user);
      });
      ref.read(currentUserProvider.notifier).state = user;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clear Data (TEMP)')),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _clearData(context, ref),
          child: const Text('Clear All User Data & Details'),
        ),
      ),
    );
  }
} 