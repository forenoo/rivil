import 'package:flutter/material.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;
  final Curve curve;

  SlidePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutQuint,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: curve,
              ),
            );

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Interval(0.0, 0.7, curve: curve),
              ),
            );

            final scaleAnimation = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Interval(0.0, 0.8, curve: curve),
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: duration,
        );
}
