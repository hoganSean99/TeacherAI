import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/features/ai_chat/presentation/providers/ai_chat_provider.dart';
import 'package:teacher_ai/features/ai_chat/presentation/widgets/ai_chat_button.dart';
import 'package:teacher_ai/features/ai_chat/presentation/widgets/ai_chat_interface.dart';

class AIChatWrapper extends ConsumerWidget {
  final Widget child;

  const AIChatWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child,
        Builder(
          builder: (context) => AIChatButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AIChatInterface(),
              );
            },
          ),
        ),
      ],
    );
  }
} 