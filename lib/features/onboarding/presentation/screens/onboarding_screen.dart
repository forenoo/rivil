import 'package:flutter/material.dart';
import 'package:rivil/core/config/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _onboardingSteps = [
    {
      'image': 'assets/images/onboarding-travel.png',
      'title': 'Temukan Keajaiban Malang Raya',
      'description':
          'Jelajahi tempat wisata ikonik, alam tersembunyi, dan pengalaman budaya autentik yang hanya ada di Malang Raya.',
    },
    {
      'image': 'assets/images/onboarding-easy.png',
      'title': 'Rencanakan Dengan Mudah',
      'description':
          'Dapatkan informasi lengkap tentang harga tiket, jam buka, fasilitas, dan ulasan dari pengunjung lain untuk merencanakan kunjunganmu.',
    },
    {
      'image': 'assets/images/onboarding-photo.png',
      'title': 'Bagikan Pengalamanmu',
      'description':
          'Simpan tempat favoritmu, bagikan pengalaman unikmu, dan dapatkan rekomendasi khusus berdasarkan preferensimu.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _onboardingSteps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingSteps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // Upper section with image
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingSteps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Center(
                      child: Image.asset(
                        _onboardingSteps[index]['image']!,
                        fit: BoxFit.contain,
                        key: ValueKey(_onboardingSteps[index]['image']!),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Lower section with text and controls
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text content
                    Column(
                      children: [
                        Text(
                          _onboardingSteps[_currentPage]['title']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                            letterSpacing: -0.5,
                            height: 1.2,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onboardingSteps[_currentPage]['description']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            height: 1.5,
                            letterSpacing: -0.2,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _handleNextOrComplete(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isLastPage ? 'Mulai Perjalanan' : 'Selanjutnya',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
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

  void _handleNextOrComplete() {
    if (_currentPage < _onboardingSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    widget.onComplete();
  }
}
