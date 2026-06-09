import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'services/sms_parser_service.dart';
import 'services/ml_service_client.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/education_screen.dart';
import 'theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed, running in offline mock mode: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, DBService>(
          create: (_) => DBService(),
          update: (_, auth, db) {
            db!.setUserId(auth.currentUser?.uid);
            return db;
          },
        ),
        ChangeNotifierProvider(create: (_) => SMSParserService()),
        ChangeNotifierProvider(create: (_) => MLServiceClient()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const FinMateApp(),
    ),
  );
}

class FinMateApp extends StatelessWidget {
  const FinMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'FinMate – AI Finance & Investments',
      debugShowCheckedModeBanner: false,
      theme: FinMateTheme.lightTheme,
      darkTheme: FinMateTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.currentUser == null) {
            return const LoginScreen();
          }
          return const MainNavigationContainer();
        },
      ),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onNavigate: _onTabTapped),
      const TransactionScreen(),
      const BudgetScreen(),
      const GoalScreen(),
      const ChatbotScreen(),
      const EducationScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (_currentIndex != index) {
            HapticFeedback.selectionClick();
            setState(() {
              _currentIndex = index;
            });
          }
        },
        physics: const BouncingScrollPhysics(),
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
          height: 64,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / 6;
                    return Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double offset = _currentIndex.toDouble();
                            if (_pageController.hasClients && _pageController.position.haveDimensions) {
                              offset = _pageController.page ?? _currentIndex.toDouble();
                            }
                            return Positioned(
                              left: itemWidth * offset,
                              top: 0,
                              bottom: 0,
                              width: itemWidth,
                              child: Center(
                                child: Container(
                                  width: 48,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 0),
                            _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 1),
                            _buildNavItem(Icons.donut_large_outlined, Icons.donut_large, 2),
                            _buildNavItem(Icons.flag_outlined, Icons.flag, 3),
                            _buildNavItem(Icons.psychology_outlined, Icons.psychology, 4),
                            _buildNavItem(Icons.school_outlined, Icons.school, 5),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = Theme.of(context).iconTheme.color?.withOpacity(0.5) ?? Colors.grey;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 64,
        alignment: Alignment.center,
        child: Icon(
          isSelected ? filledIcon : outlineIcon,
          color: isSelected ? primaryColor : unselectedColor,
          size: 26,
        ),
      ),
    );
  }
}
