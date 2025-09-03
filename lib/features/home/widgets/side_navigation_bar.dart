// lib/features/home/widgets/side_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:project_x/core/constants/route_constants.dart';
import 'package:project_x/core/theme/app_theme.dart';
import 'package:project_x/shared/services/navigation_service.dart';

class SideNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const SideNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.search, "Explore", 1),
          _buildNavItem(Icons.notifications, "Notifications", 2),
          _buildNavItem(Icons.mail, "Messages", 3),
          _buildNavItem(Icons.person, "Profile", 4),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              NavigationService.navigateTo(RouteConstants.home);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text(
              "Post",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileTile(),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: currentIndex == index ? Colors.blue : Colors.white,
      ),
      title: Text(
        label,
        style: AppTheme.darkTheme.textTheme.bodyLarge!.copyWith(
          color: currentIndex == index ? Colors.blue : Colors.white,
          fontWeight: currentIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onTap: () => onItemSelected(index),
    );
  }

  Widget _buildProfileTile() {
    return ListTile(
      leading: const CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage('https://via.placeholder.com/32'),
      ),
      title: Text(
        "User Name",
        style: AppTheme.darkTheme.textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        "@username",
        style: AppTheme.darkTheme.textTheme.bodySmall!.copyWith(
          color: Colors.grey,
        ),
      ),
    );
  }
}
