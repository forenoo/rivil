import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rivil/core/config/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget destination;

  const SplashScreen({
    super.key,
    this.duration = const Duration(seconds: 2),
    required this.destination,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: SvgPicture.asset(
                  'assets/vectors/logo.svg',
                  width: 120,
                  height: 120,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startTimer() {
    Future.delayed(widget.duration).then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.destination),
        );
      }
    });
  }
}
