import 'package:flutter/material.dart';
import 'package:rivil/features/onboarding/domain/services/onboarding_service.dart';
import 'package:rivil/features/onboarding/presentation/screens/onboarding_screen.dart';

class OnboardingGate extends StatefulWidget {
  final Widget child;
  final OnboardingService onboardingService;

  const OnboardingGate({
    super.key,
    required this.child,
    required this.onboardingService,
  });

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _hasSeenOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final hasSeenOnboarding =
        await widget.onboardingService.hasSeenOnboarding();

    if (mounted) {
      setState(() {
        _hasSeenOnboarding = hasSeenOnboarding;
        _isLoading = false;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasSeenOnboarding) {
      return OnboardingScreen(
        onComplete: _onOnboardingComplete,
      );
    }

    return widget.child;
  }
}
