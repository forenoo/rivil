import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rivil/core/config/app_colors.dart';
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
import 'package:rivil/features/home/presentation/bloc/destination_bloc.dart';
import 'package:rivil/features/home/data/repositories/destination_repository_impl.dart';
import 'package:rivil/features/home/domain/repository/destination_repository.dart';
import 'package:rivil/features/exploration/presentation/screens/exploration_screen.dart';
import 'package:rivil/features/profile/presentation/screens/profile_screen.dart';
import 'package:rivil/features/exploration/data/repositories/exploration_repository_impl.dart';
import 'package:rivil/features/exploration/domain/repositories/exploration_repository.dart';
import 'package:rivil/features/exploration/presentation/bloc/exploration_bloc.dart';
import 'package:rivil/features/add_destination/presentation/screens/add_destination_screen.dart';
import 'package:rivil/features/trip_planning/data/services/trip_planning_service.dart';
import 'package:rivil/features/trip_planning/presentation/bloc/trip_planning_bloc.dart';
import 'package:rivil/widgets/slide_page_route.dart';
import 'package:rivil/features/trip_planning/domain/repositories/trip_repository.dart';
import 'package:rivil/features/trip_planning/data/repositories/trip_repository_impl.dart';
import 'package:rivil/features/trip_planning/presentation/bloc/trip_save_bloc.dart';

final GlobalKey<_MainNavigationWrapperState> mainNavigationKey =
    GlobalKey<_MainNavigationWrapperState>();

class RivilApp extends StatelessWidget {
  final SupabaseService supabaseService;

  const RivilApp({super.key, required this.supabaseService});

  @override
  Widget build(BuildContext context) {
    final onboardingService = OnboardingService();
    final tripPlanningService = TripPlanningService();

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
          create: (context) => FavoriteRepositoryImpl(supabaseService.client),
        ),
        RepositoryProvider<DestinationRepository>(
          create: (context) =>
              DestinationRepositoryImpl(supabaseService.client),
        ),
        RepositoryProvider<ExplorationRepository>(
          create: (context) =>
              ExplorationRepositoryImpl(supabaseService.client),
        ),
        RepositoryProvider<TripPlanningService>(
          create: (context) => tripPlanningService,
        ),
        RepositoryProvider<TripRepository>(
          create: (context) => TripRepositoryImpl(supabaseService.client),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(context.read<AuthRepository>()),
          ),
          BlocProvider<FavoritesBloc>(
            create: (context) =>
                FavoritesBloc(repository: context.read<FavoriteRepository>()),
          ),
          BlocProvider<DestinationBloc>(
            create: (context) => DestinationBloc(
              context.read<DestinationRepository>(),
            )..add(LoadDestinations()),
          ),
          BlocProvider<ExplorationBloc>(
            create: (context) => ExplorationBloc(
              context.read<ExplorationRepository>(),
            ),
          ),
          BlocProvider<TripPlanningBloc>(
            create: (context) => TripPlanningBloc(
              context.read<TripPlanningService>(),
            ),
          ),
          BlocProvider<TripSaveBloc>(
            create: (context) => TripSaveBloc(
              context.read<TripRepository>(),
            ),
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
                authenticatedRoute:
                    MainNavigationWrapper(key: mainNavigationKey),
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

  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(_currentIndex == 0 ? -1 : 1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuint,
              )),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        SlidePageRoute(
                          child: const AddDestinationScreen(),
                        ),
                      );
                    },
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
          navigateToTab(index);
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
