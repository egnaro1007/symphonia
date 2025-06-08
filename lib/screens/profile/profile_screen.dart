import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/screens/profile/login_screen.dart';
import 'package:symphonia/screens/profile/playlist.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'package:symphonia/constants/screen_index.dart';

class ProfileScreen extends AbstractScreen {
  @override
  final void Function(int, String) onTabSelected;

  const ProfileScreen({super.key, required this.onTabSelected})
    : super(onTabSelected: onTabSelected);

  @override
  String get title => "Cá Nhân";

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            _buildProfileHeader(),

            const SizedBox(height: 20),

            // Quick access buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAccessButton(
                  Icons.favorite_border,
                  AppLocalizations.of(context)!.favorites,
                  Theme.of(context).colorScheme.primary,
                  () {
                    // Navigate to favorites screen using navigation system
                    widget.onTabSelected(ScreenIndex.favorites.value, "");
                  },
                ),
                _buildQuickAccessButton(
                  Icons.arrow_downward,
                  AppLocalizations.of(context)!.downloaded,
                  Theme.of(context).colorScheme.secondary,
                  () {
                    // Navigate to downloaded screen using navigation system
                    widget.onTabSelected(ScreenIndex.downloaded.value, "");
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Playlists Section
            PlayListComponent(onTabSelected: widget.onTabSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        height: 90,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: AppLocalizations.of(context)!.welcome,
                style: const TextStyle(fontSize: 18),
                children: [
                  TextSpan(
                    text: UserInfoManager.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: '!',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Logout functionality
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(AppLocalizations.of(context)!.logout),
                    content: Text(
                      AppLocalizations.of(context)!.logoutConfirmation,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Reset player state before logout
                          final playerController =
                              PlayerController.getInstance();
                          await playerController.reset();

                          await TokenManager.logout();
                          Navigator.pop(context); // Close the dialog first
                          // Navigate to login screen and clear all previous routes
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (Route<dynamic> route) =>
                                  false, // This removes all previous routes
                            );
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.logout),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              AppLocalizations.of(context)!.logout,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        ],
      ),
    );
  }
}
