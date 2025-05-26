import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:teacher_ai/features/auth/domain/services/auth_service.dart';
import 'package:teacher_ai/features/auth/domain/models/user.dart';

export 'package:teacher_ai/features/auth/domain/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(DatabaseService.instance);
});

final currentUserProvider = StateProvider<User?>((ref) => null); 