import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  double _textSize = 1.0;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _screenReader = false;
  bool _closedCaptions = true;
  bool _soundDescriptions = false;
  String _colorTheme = 'Default';

  final List<String> _colorThemes = [
    'Default',
    'High Contrast',
    'Dark High Contrast',
    'Protanopia',
    'Deuteranopia',
    'Tritanopia',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Vision'),
        _buildTextSizeSection(),
        const SizedBox(height: 16),
        _buildColorAndContrastSection(),
        const SizedBox(height: 32),
        
        _buildSectionHeader('Motion and Interaction'),
        _buildMotionSection(),
        const SizedBox(height: 32),
        
        _buildSectionHeader('Hearing'),
        _buildHearingSection(),
        const SizedBox(height: 32),
        
        _buildSectionHeader('Screen Reader'),
        _buildScreenReaderSection(),
        const SizedBox(height: 32),
        
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextSizeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Text Size',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sample text with current size',
            style: TextStyle(
              fontSize: 16 * _textSize,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Small'),
              Expanded(
                child: Slider(
                  value: _textSize,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: '${(_textSize * 100).round()}%',
                  onChanged: (value) {
                    setState(() {
                      _textSize = value;
                    });
                  },
                  activeColor: AppTheme.twitterBlue,
                ),
              ),
              const Text('Large'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorAndContrastSection() {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'High Contrast',
          subtitle: 'Increase contrast for better visibility',
          value: _highContrast,
          onChanged: (value) {
            setState(() {
              _highContrast = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Color Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a color theme that works best for you.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _colorTheme,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _colorThemes.map((theme) {
                  return DropdownMenuItem(
                    value: theme,
                    child: Text(theme),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _colorTheme = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMotionSection() {
    return _buildSwitchTile(
      title: 'Reduce Motion',
      subtitle: 'Reduce animations and motion effects',
      value: _reduceMotion,
      onChanged: (value) {
        setState(() {
          _reduceMotion = value;
        });
      },
    );
  }

  Widget _buildHearingSection() {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'Closed Captions',
          subtitle: 'Show captions for videos when available',
          value: _closedCaptions,
          onChanged: (value) {
            setState(() {
              _closedCaptions = value;
            });
          },
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: 'Audio Descriptions',
          subtitle: 'Play audio descriptions for videos when available',
          value: _soundDescriptions,
          onChanged: (value) {
            setState(() {
              _soundDescriptions = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildScreenReaderSection() {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'Screen Reader Support',
          subtitle: 'Optimize app for screen readers',
          value: _screenReader,
          onChanged: (value) {
            setState(() {
              _screenReader = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Screen Reader Tips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '• Use headphones for better audio clarity\n'
                '• Enable high contrast for better visibility\n'
                '• Increase text size if needed\n'
                '• Use voice commands for navigation',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.twitterBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveAccessibilitySettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.twitterBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Save Accessibility Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _saveAccessibilitySettings() async {
    try {
      // TODO: Implement API call to save accessibility settings
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accessibility settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}