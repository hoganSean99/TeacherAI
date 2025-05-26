import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'dart:math' as math;
import 'dart:ui';

// Navigation items for easier management
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const List<_NavItem> _navItems = [
  _NavItem(Icons.dashboard_customize_outlined, 'Dashboard'),
  _NavItem(Icons.people_alt_outlined, 'Students'),
  _NavItem(Icons.auto_graph_outlined, 'Subjects'),
  _NavItem(Icons.fact_check_outlined, 'Attendance'),
  _NavItem(Icons.description_outlined, 'Exams'),
  _NavItem(Icons.calendar_month_outlined, 'Calendar'),
  _NavItem(Icons.settings_suggest_outlined, 'Settings'),
];

class SidebarNavigation extends ConsumerWidget {
  final int selectedIndex;
  final void Function(int) onDestinationSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final String displayName = currentUser != null
        ? '${currentUser.firstName} ${currentUser.lastName}'
        : 'Not logged in';
    final String initials = currentUser != null
        ? (currentUser.firstName.isNotEmpty ? currentUser.firstName[0] : '') +
          (currentUser.lastName.isNotEmpty ? currentUser.lastName[0] : '')
        : '?';
    final String subtitle = currentUser != null
        ? currentUser.email
        : '';

    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 18.0),
            child: Row(
              children: [
                Icon(Icons.memory, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Teacher AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Montserrat',
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            return _SimpleSidebarButton(
              icon: item.icon,
              label: item.label,
              selected: selectedIndex == i,
              onTap: () => onDestinationSelected(i),
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.13),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.background,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement logout logic
                    // context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                  label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    textStyle: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleSidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SimpleSidebarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white.withOpacity(0.13) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated shimmer overlay for AI effect
class AnimatedShimmerOverlay extends StatefulWidget {
  @override
  State<AnimatedShimmerOverlay> createState() => _AnimatedShimmerOverlayState();
}

class _AnimatedShimmerOverlayState extends State<AnimatedShimmerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ShimmerPainter(_controller.value),
          child: Container(),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerWidth = size.width * 0.7;
    final shimmerHeight = size.height * 0.18;
    final dx = (size.width + shimmerWidth) * progress - shimmerWidth;
    final rect = Rect.fromLTWH(dx, 0, shimmerWidth, shimmerHeight);
    final gradient = LinearGradient(
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.13),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.lighten;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) => oldDelegate.progress != progress;
}

// Animated avatar with online indicator ring and blurred background
class _AnimatedAvatar extends StatefulWidget {
  final String initials;
  const _AnimatedAvatar({required this.initials});

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_hovered ? 1.10 : 1.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Blurred background
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 62,
                  height: 62,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            // Gradient border
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9F5DE2), Color(0xFFE040FB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.initials,
                    style: const TextStyle(
                      color: Color(0xFF7B1FA2),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
            ),
            // Online indicator ring
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6EC6CA), Color(0xFF7B61FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6EC6CA).withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 