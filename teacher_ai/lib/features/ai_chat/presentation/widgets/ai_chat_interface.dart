import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/features/ai_chat/presentation/providers/ai_chat_provider.dart';
import 'package:teacher_ai/features/ai_chat/presentation/providers/providers.dart';

class AIChatInterface extends ConsumerStatefulWidget {
  const AIChatInterface({Key? key}) : super(key: key);

  @override
  ConsumerState<AIChatInterface> createState() => _AIChatInterfaceState();
}

class _AIChatInterfaceState extends ConsumerState<AIChatInterface>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    ref.read(aiChatProvider).sendMessage(_messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;
    final borderRadius = BorderRadius.circular(28);

    if (_controller == null) {
      // Fallback UI if controller is not ready
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          return CustomPaint(
            painter: _AIGlowBorderPainter(_controller!.value, borderRadius),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 540,
                  height: 650,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent.withOpacity(0.7),
                              Colors.purpleAccent.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
                            const SizedBox(width: 10),
                            const Text(
                              'Teacher AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      // Messages
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return Align(
                              alignment: message.isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                                decoration: BoxDecoration(
                                  color: message.isUser
                                      ? Colors.deepPurpleAccent.withOpacity(0.85)
                                      : Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    if (!message.isUser)
                                      BoxShadow(
                                        color: Colors.blueAccent.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: message.isUser ? Colors.white : Colors.black87,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Input
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Type your message...'
                                      ' (e.g. "What is Isabella Hogan\'s attendance like?")',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.7),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : const Icon(Icons.send, color: Colors.deepPurpleAccent, size: 28),
                              onPressed: isLoading ? null : _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for animated glowing border
class _AIGlowBorderPainter extends CustomPainter {
  final double animationValue;
  final BorderRadius borderRadius;
  _AIGlowBorderPainter(this.animationValue, this.borderRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: pi * 2,
      colors: [
        Colors.blueAccent,
        Colors.purpleAccent,
        Colors.blueAccent,
      ],
      stops: [0.0, 0.5 + 0.5 * sin(animationValue * 2 * pi), 1.0],
      transform: GradientRotation(animationValue * 2 * pi),
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final rrect = borderRadius.toRRect(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AIGlowBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
} 