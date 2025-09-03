// lib/features/home/home_screen.dart (assumed based on error)
import 'package:flutter/material.dart';
import 'package:project_x/shared/widgets/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:project_x/features/home/home_viewmodel.dart';
import 'package:project_x/features/home/widgets/mobile_home_layout.dart';
import 'package:project_x/features/home/widgets/tablet_home_layout.dart';
import 'package:project_x/features/home/widgets/desktop_home_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(
      context,
    ); // Line 14: Error here
    return ResponsiveLayout(
      mobile: MobileHomeLayout(
        currentIndex: viewModel.currentIndex,
        onItemTapped: viewModel.navigateTo,
      ),
      tablet: TabletHomeLayout(
        currentIndex: viewModel.currentIndex,
        onItemSelected: viewModel.navigateTo,
      ),
      desktop: DesktopHomeLayout(
        currentIndex: viewModel.currentIndex,
        onItemSelected: viewModel.navigateTo,
      ),
    );
  }
}
