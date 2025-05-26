import 'package:flutter/material.dart';
import 'package:teacher_ai/features/ai_chat/domain/services/ai_service.dart';

class AIChatProvider extends ChangeNotifier {
  final AIService _aiService;
  bool _isLoading = false;
  final List<ChatMessage> _messages = [];
  String? _lastStudentName;
  bool _disposed = false;

  AIChatProvider(this._aiService);

  bool get isLoading => _isLoading;
  List<ChatMessage> get messages => _messages;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
    if (!_disposed) notifyListeners();

    try {
      final response = await _aiService.processQueryWithContext(text, _lastStudentName);
      // If a student was referenced, update lastStudentName
      final referencedStudent = _aiService.lastExtractedStudentName;
      if (referencedStudent != null) {
        _lastStudentName = referencedStudent;
      }
      _messages.add(ChatMessage(text: response, isUser: false));
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Sorry, I encountered an error while processing your request.",
        isUser: false,
      ));
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
} 