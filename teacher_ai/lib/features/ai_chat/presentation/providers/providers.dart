import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:teacher_ai/features/ai_chat/domain/services/ai_service.dart';
import 'package:teacher_ai/features/ai_chat/presentation/providers/ai_chat_provider.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(DatabaseService.instance);
});

final aiChatProvider = ChangeNotifierProvider<AIChatProvider>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return AIChatProvider(aiService);
}); 