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
import 'package:rivil/features/favorite/data/repositories/favorite_repository_impl.dart';
import 'package:rivil/features/favorite/domain/repository/favorite_repository.dart';
import 'package:rivil/features/favorite/presentation/bloc/favorites_bloc.dart';
import 'package:rivil/features/favorite/presentation/screens/favorites_screen.dart';
import 'package:rivil/features/home/presentation/screens/home_screen.dart';
import 'package:rivil/features/onboarding/domain/services/onboarding_service.dart';
import 'package:rivil/features/onboarding/presentation/widgets/onboarding_gate.dart';
import 'package:rivil/features/home/presentation/bloc/category_bloc.dart';
import 'package:rivil/features/exploration/presentation/screens/exploration_screen.dart';
import 'package:rivil/features/profile/presentation/screens/profile_screen.dart';

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
        RepositoryProvider<FavoriteRepository>(
          create: (context) => FavoriteRepositoryImpl(),
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
          BlocProvider<FavoritesBloc>(
            create: (context) =>
                FavoritesBloc(context.read<FavoriteRepository>()),
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
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _screens[_currentIndex],
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomAppBar(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            elevation: 0,
            color: Colors.white,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                _buildNavItem(1, Icons.explore_rounded, 'Eksplorasi'),
                Container(
                  height: 50,
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withBlue(200)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {},
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    splashColor: Colors.white.withOpacity(0.2),
                    highlightColor: Colors.transparent,
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                _buildNavItem(2, Icons.favorite_rounded, 'Favorit'),
                _buildNavItem(3, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : Colors.grey.shade600,
              size: 24,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
