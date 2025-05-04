import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/core/config/app_theme.dart';
import 'package:rivil/core/services/supabase_service.dart';
import 'package:rivil/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rivil/features/auth/domain/repositories/auth_repository.dart';
import 'package:rivil/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rivil/features/auth/presentation/screens/login_screen.dart';
import 'package:rivil/features/auth/presentation/widgets/auth_gate.dart';
import 'package:rivil/features/home/presentation/screens/home_screen.dart';
import 'package:rivil/features/onboarding/domain/services/onboarding_service.dart';
import 'package:rivil/features/onboarding/presentation/widgets/onboarding_gate.dart';
import 'package:rivil/features/home/presentation/bloc/category_bloc.dart';
import 'package:rivil/features/exploration/presentation/screens/exploration_screen.dart';

class RivilApp extends StatelessWidget {
  final SupabaseService supabaseService;

  const RivilApp({super.key, required this.supabaseService});

  @override
  Widget build(BuildContext context) {
    final onboardingService = OnboardingService();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(supabaseService),
        ),
        RepositoryProvider<OnboardingService>(
          create: (context) => onboardingService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(context.read<AuthRepository>()),
          ),
          BlocProvider<CategoryBloc>(
            create: (context) => CategoryBloc()..add(CategoriesLoaded()),
          ),
        ],
        child: Builder(builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Rivil',
            theme: AppTheme.appTheme.copyWith(
              appBarTheme: AppTheme.appTheme.appBarTheme.copyWith(
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                ),
              ),
            ),
            home: OnboardingGate(
              onboardingService: context.read<OnboardingService>(),
              child: AuthGate(
                supabaseService: supabaseService,
                authenticatedRoute: const MainNavigationWrapper(),
                unauthenticatedRoute: const LoginScreen(),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExplorationScreen(),
    Scaffold(body: Center(child: Text('Disimpan'))),
    Scaffold(body: Center(child: Text('Profil'))),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Eksplorasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Disimpan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
