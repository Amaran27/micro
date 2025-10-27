import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/utils/logger.dart';
import '../providers/app_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Welcome to Micro',
      description: 'Your privacy-first, autonomous personal assistant',
      icon: Icons.smart_toy,
    ),
    OnboardingItem(
      title: 'Universal Capabilities',
      description: 'Adapts to any domain through MCP integration',
      icon: Icons.extension,
    ),
    OnboardingItem(
      title: 'Privacy & Security',
      description: 'Local-first storage with end-to-end encryption',
      icon: Icons.security,
    ),
    OnboardingItem(
      title: 'Get Started',
      description: 'Begin your journey with intelligent automation',
      icon: Icons.rocket_launch,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return OnboardingItemWidget(
                    item: _items[index],
                    isLast: index == _items.length - 1,
                    onNext: () => _nextPage(),
                    onGetStarted: () => _completeOnboarding(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    try {
      logger.info('Starting onboarding completion process');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Save onboarding completion state
      logger.info('Saving onboarding completion state');
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(AppConstants.onboardingCompleteKey, true);
      logger.info('Onboarding completion state saved successfully');

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to home page after completing onboarding
      if (mounted) {
        logger.info('Navigating to home page');
        context.go(RouteConstants.home);
      }
    } catch (e) {
      logger.error('Failed to complete onboarding: $e');

      // Close loading indicator if open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Handle error during onboarding completion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingItemWidget extends StatelessWidget {
  final OnboardingItem item;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  const OnboardingItemWidget({
    super.key,
    required this.item,
    required this.isLast,
    required this.onNext,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            size: 120,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 48),
          Text(
            item.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLast ? onGetStarted : onNext,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(
                isLast ? 'Get Started' : 'Next',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
