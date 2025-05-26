import 'dart:ui';
import 'package:flutter/material.dart';

class AIChatButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AIChatButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 32,
      bottom: 32,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.withOpacity(0.7),
                Colors.purpleAccent.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              width: 2.5,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_awesome,
                  size: 34,
                  color: Colors.white.withOpacity(0.95),
                  // You can use CupertinoIcons.sparkles or a custom SVG for more Apple-like look
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 